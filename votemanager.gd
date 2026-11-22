extends Node

const PROJECT_URL := "https://supabase.co"
const ANON_KEY := "YOUR_PUBLIC_ANON_KEY"
const AUTH_URL := PROJECT_URL + "/auth/v1"
const VOTES_URL := PROJECT_URL + "/rest/v1/report_votes?on_conflict=report_path,player_id"
const TOTALS_URL := PROJECT_URL + "/rest/v1/vote_totals_view?select=report_path,yes_votes,no_votes"

const DB_PATH := "user://local_votes.db"
const COOLDOWN_SECONDS := 10 * 3600 # 10 hours
signal summary_updated
var summary_data := VoteSummaryData.new()

var db: SQLite
var access_token: String = ""
var refresh_token: String = ""
var user_id: String = ""
var is_syncing: bool = false
var is_refreshing_auth: bool = false

func _ready() -> void:
	_init_local_db()
	_load_auth_from_db()
	
	if refresh_token.is_empty():
		_sign_in_anonymously()
	else:
		_refresh_session()

# --- 1. Local SQLite Setup ---

func _init_local_db() -> void:
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()
	
	# Stores anonymous session tokens locally
	db.query("""
		CREATE TABLE IF NOT EXISTS profile (
			id INTEGER PRIMARY KEY CHECK (id = 1),
			user_id TEXT,
			refresh_token TEXT
		);
	""")
	
	# Stores each report's vote, timestamp, and upload status (synced: 0 = pending, 1 = uploaded)
	db.query("""
		CREATE TABLE IF NOT EXISTS local_votes (
			report_path TEXT PRIMARY KEY,
			vote TEXT NOT NULL,
			updated_at INTEGER NOT NULL,
			synced INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	db.query("""
		CREATE TABLE IF NOT EXISTS cached_totals (
			report_path TEXT PRIMARY KEY,
			yes_votes INTEGER NOT NULL DEFAULT 0,
			no_votes INTEGER NOT NULL DEFAULT 0
		);
	""")
	
	# Immediately populate summary_data from local cache so offline play works right away
	rebuild_summary_from_cache()

func refresh_global_totals() -> void:
	# Skip overwriting cached_totals if local votes are still uploading to prevent race conditions
	db.query("SELECT 1 FROM local_votes WHERE synced = 0 LIMIT 1;")
	if not db.query_result.is_empty():
		return
		
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_totals_fetched.bind(http))
	
	var headers := [
		"apikey: " + ANON_KEY,
		"Authorization: Bearer " + (access_token if not access_token.is_empty() else ANON_KEY)
	]
	http.request(TOTALS_URL, headers, HTTPClient.METHOD_GET)

func _on_totals_fetched(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if response_code >= 200 and response_code < 300:
		# Re-check in case a vote was cast while the HTTP request was in flight
		db.query("SELECT 1 FROM local_votes WHERE synced = 0 LIMIT 1;")
		if not db.query_result.is_empty():
			return
			
		var rows: Variant = JSON.parse_string(body.get_string_from_utf8())
		if rows is Array:
			db.query("BEGIN TRANSACTION;")
			db.query("DELETE FROM cached_totals;")
			for row in rows:
				db.query_with_bindings(
					"INSERT INTO cached_totals (report_path, yes_votes, no_votes) VALUES (?, ?, ?);",
					[row["report_path"], int(row["yes_votes"]), int(row["no_votes"])]
				)
			db.query("COMMIT;")
			rebuild_summary_from_cache()
	else:
		push_warning("Could not refresh global totals (%d). Using offline cache." % response_code)

func rebuild_summary_from_cache() -> void:
	var fresh_summary := VoteSummaryData.new()
	db.query("SELECT report_path, yes_votes, no_votes FROM cached_totals;")
	
	for row in db.query_result:
		var path: String = row["report_path"]
		var y: int = int(row["yes_votes"])
		var n: int = int(row["no_votes"])
		
		# Add to global grand totals
		fresh_summary.total_yes_votes += y
		fresh_summary.total_no_votes += n
		
		# Walk the folder path (e.g., "podcasts/actual diaries/2023/report1")
		var parts := path.split("/", false)
		var current: Dictionary = fresh_summary.reports_by_group
		
		for i in range(parts.size()):
			var part: String = parts[i]
			var is_leaf := (i == parts.size() - 1)
			
			if is_leaf:
				current[part] = { "yes": y, "no": n }
			else:
				if not current.has(part):
					current[part] = { "_subtotal": { "yes": 0, "no": 0 } }
				current[part]["_subtotal"]["yes"] += y
				current[part]["_subtotal"]["no"] += n
				current = current[part]
				
	summary_data = fresh_summary
	summary_updated.emit()

func _load_auth_from_db() -> void:
	db.query("SELECT user_id, refresh_token FROM profile WHERE id = 1;")
	if db.query_result.size() > 0:
		user_id = db.query_result[0].get("user_id", "")
		refresh_token = db.query_result[0].get("refresh_token", "")

func _save_auth_to_db() -> void:
	db.query_with_bindings(
		"INSERT OR REPLACE INTO profile (id, user_id, refresh_token) VALUES (1, ?, ?);",
		[user_id, refresh_token]
	)

# --- 2. Local Cooldown & Voting ---

func get_remaining_cooldown(report_path: String) -> int:
	db.query_with_bindings("SELECT updated_at FROM local_votes WHERE report_path = ?;", [report_path])
	if db.query_result.is_empty():
		return 0
		
	var last_voted: int = db.query_result[0]["updated_at"]
	var elapsed := int(Time.get_unix_time_from_system()) - last_voted
	return maxi(0, COOLDOWN_SECONDS - elapsed)

func can_vote(report_path: String) -> bool:
	return get_remaining_cooldown(report_path) == 0

func get_previous_vote(report_path: String) -> String:
	db.query_with_bindings("SELECT vote FROM local_votes WHERE report_path = ?;", [report_path])
	if db.query_result.is_empty():
		return "none"
	return db.query_result[0]["vote"]

# Saves immediately to the local database, then triggers a background server upload
func cast_vote(report_path: String, vote_choice: String) -> bool:
	if vote_choice != "yes" and vote_choice != "no":
		push_warning("Invalid vote choice: " + vote_choice)
		return false
		
	if not can_vote(report_path):
		push_warning("Cooldown active for: " + report_path)
		return false
	
	# Fetch previous vote BEFORE overwriting local_votes
	var prev_vote := get_previous_vote(report_path)
	var now := int(Time.get_unix_time_from_system())
	
	db.query_with_bindings(
		"""
		INSERT INTO local_votes (report_path, vote, updated_at, synced)
		VALUES (?, ?, ?, 0)
		ON CONFLICT(report_path) DO UPDATE SET
			vote = excluded.vote,
			updated_at = excluded.updated_at,
			synced = 0;
		""",
		[report_path, vote_choice, now]
	)
	
	var y_delta := (1 if vote_choice == "yes" else 0) - (1 if prev_vote == "yes" else 0)
	var n_delta := (1 if vote_choice == "no" else 0) - (1 if prev_vote == "no" else 0)

	db.query_with_bindings(
		"""
		INSERT INTO cached_totals (report_path, yes_votes, no_votes)
		VALUES (?, MAX(0, ?), MAX(0, ?))
		ON CONFLICT(report_path) DO UPDATE SET
			yes_votes = MAX(0, yes_votes + ?),
			no_votes = MAX(0, no_votes + ?);
		""",
		[report_path, y_delta, n_delta, y_delta, n_delta]
	)
	rebuild_summary_from_cache()

	sync_pending_votes()
	return true

# --- 3. Anonymous Auth & Server Upload Queue ---

func sync_pending_votes() -> void:
	if access_token.is_empty() or is_syncing or is_refreshing_auth:
		return
		
	db.query("SELECT report_path, vote FROM local_votes WHERE synced = 0 LIMIT 1;")
	if db.query_result.is_empty():
		return
		
	is_syncing = true
	var row: Dictionary = db.query_result[0]
	var report_path: String = row["report_path"]
	var vote_choice: String = row["vote"]
	
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_sync_completed.bind(http, report_path))

	var headers := [
		"apikey: " + ANON_KEY,
		"Authorization: Bearer " + access_token,
		"Content-Type: application/json",
		"Prefer: resolution=merge-duplicates"
	]

	var payload := JSON.stringify({
		"report_path": report_path,
		"player_id": user_id,
		"vote": vote_choice
	})

	http.request(VOTES_URL, headers, HTTPClient.METHOD_POST, payload)

func _on_sync_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, report_path: String) -> void:
	http.queue_free()
	is_syncing = false
	
	if response_code >= 200 and response_code < 300:
		db.query_with_bindings("UPDATE local_votes SET synced = 1 WHERE report_path = ?;", [report_path])
		
		db.query("SELECT 1 FROM local_votes WHERE synced = 0 LIMIT 1;")
		if not db.query_result.is_empty():
			# Wait 6.5 seconds between queued uploads to stay safely under 10 votes/min
			get_tree().create_timer(6.5).timeout.connect(sync_pending_votes)
		else:
			refresh_global_totals()

	elif response_code == 401 and not refresh_token.is_empty():
		# Access token expired after 1 hour; refresh session and retry automatically
		_refresh_session()
	else:
		push_warning("Server sync failed (%d): %s" % [response_code, body.get_string_from_utf8()])

func _sign_in_anonymously() -> void:
	if is_refreshing_auth:
		return
	is_refreshing_auth = true
	
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_auth_completed.bind(http))
	http.request(AUTH_URL + "/signup", ["apikey: " + ANON_KEY, "Content-Type: application/json"], HTTPClient.METHOD_POST, "{}")

func _refresh_session() -> void:
	if is_refreshing_auth:
		return
	is_refreshing_auth = true
	
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_auth_completed.bind(http))
	var payload := JSON.stringify({ "refresh_token": refresh_token })
	http.request(AUTH_URL + "/token?grant_type=refresh_token", ["apikey: " + ANON_KEY, "Content-Type: application/json"], HTTPClient.METHOD_POST, payload)

func _on_auth_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	is_refreshing_auth = false
	
	if response_code >= 200 and response_code < 300:
		var data: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		access_token = data.get("access_token", "")
		refresh_token = data.get("refresh_token", "")
		user_id = data.get("user", {}).get("id", "")
		_save_auth_to_db()
		
		# Upload any offline votes first; otherwise fetch latest global totals
		db.query("SELECT 1 FROM local_votes WHERE synced = 0 LIMIT 1;")
		if not db.query_result.is_empty():
			sync_pending_votes()
		else:
			refresh_global_totals()
	else:
		refresh_token = ""
		
func get_all_player_votes() -> Dictionary:
	var votes := {}
	db.query("SELECT report_path, vote FROM local_votes;")
	for row in db.query_result:
		votes[row["report_path"]] = row["vote"]
	return votes

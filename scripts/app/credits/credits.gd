extends Control

@export var scroll_speed: float = 40.0 # Normal pixels per second
@export var fast_forward_multiplier: float = 5.0 # 5x speed when holding button/key

@onready var scrolls: ScrollContainer = $scrolls
@onready var lab: RichTextLabel = $scrolls/margins/lab
@onready var margins: MarginContainer = $scrolls/margins
@onready var bgm_p: AudioStreamPlayer = $bgmp

var scrolling: bool = true
var scroll_pos: float = 0.0
var base_credits_text: String = ""

func _ready() -> void:
	scrolls.scroll_vertical = 0
	
	# Cache the original text from the scene so we can rebuild cleanly if live totals arrive
	base_credits_text = lab.text
	_refresh_credits_display()
	
	# Connect to live updates and trigger a background fetch
	if Votemanager.has_signal("summary_updated"):
		Votemanager.summary_updated.connect(_refresh_credits_display)
	Votemanager.refresh_global_totals()
	
	# Godot 4.7 requires a frame delay to build the RichTextLabel size from text
	set_process(false)
	await get_tree().process_frame
	set_process(true)
	bgm_p.play()

func _refresh_credits_display() -> void:
	lab.text = base_credits_text + "\n\n\n" + _build_vote_credits_bbcode()

func _process(delta: float) -> void:
	if not scrolling:
		return
		
	# Hold left mouse button, Space, Enter, or Down Arrow to fast-forward
	var is_fast_forwarding := (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		or Input.is_action_pressed("ui_accept")
		or Input.is_action_pressed("ui_down")
	)
	var current_speed := scroll_speed * (fast_forward_multiplier if is_fast_forwarding else 1.0)
	
	scroll_pos += current_speed * delta
	scrolls.scroll_vertical = int(scroll_pos)
	
	# Dynamically recalculate height each frame (handles live vote refreshes seamlessly)
	var label_height := lab.get_content_height()
	var top_pad := margins.get_theme_constant("margin_top")
	var bottom_pad := margins.get_theme_constant("margin_bottom")
	var total_height := label_height + top_pad + bottom_pad
	var max_scroll := total_height - scrolls.size.y
	
	if label_height > 0 and scrolls.scroll_vertical >= max_scroll:
		scrolling = false
		_on_credits_finished()

func _input(event: InputEvent) -> void:
	# Press Escape (ui_cancel) or Right-Click to immediately exit credits
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		_on_credits_finished()

func _on_credits_finished() -> void:
	if Votemanager.has_signal("summary_updated") and Votemanager.summary_updated.is_connected(_refresh_credits_display):
		Votemanager.summary_updated.disconnect(_refresh_credits_display)
	print("Credits finished!")
	bgm_p.stop()
	# get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# --- Vote Breakdown Formatting ---

func _build_vote_credits_bbcode() -> String:
	var data: VoteSummaryData = Votemanager.summary_data
	var player_votes: Dictionary = Votemanager.get_all_player_votes()
	
	var lines: PackedStringArray = []
	lines.append("community report votes")
	lines.append("-------------------------")
	
	if data.total_yes_votes == 0 and data.total_no_votes == 0 and data.reports_by_group.is_empty():
		lines.append("[color=#999999]connect online to view global report votes[/color]")
		return "\n".join(lines)
		
	lines.append("total global votes: [color=#06D6A0]%d yes[/color]  /  [color=#EF476F]%d no[/color]\n" % [
		data.total_yes_votes,
		data.total_no_votes
	])
	
	_append_group_lines(lines, data.reports_by_group, 0, "", player_votes)
	return "\n".join(lines)

func _append_group_lines(
	lines: PackedStringArray,
	branch: Dictionary,
	depth: int,
	current_path: String,
	player_votes: Dictionary
) -> void:
	var keys := branch.keys()
	keys.sort()
	
	for key in keys:
		if key == "_subtotal":
			continue
			
		var entry: Dictionary = branch[key]
		var label_name := str(key).to_lower()
		var full_path := str(key) if current_path.is_empty() else (current_path + "/" + str(key))
		
		if entry.has("_subtotal"):
			var sub: Dictionary = entry["_subtotal"]
			if depth == 0:
				lines.append("\n[color=#8ECAE6]%s[/color]  ([color=#06D6A0]%d yes[/color] / [color=#EF476F]%d no[/color])" % [
					label_name, sub["yes"], sub["no"]
				])
				lines.append("-".repeat(maxi(6, label_name.length() + 4)))
			else:
				lines.append("[b]%s[/b]  ([color=#06D6A0]%d yes[/color] / [color=#EF476F]%d no[/color])" % [
					label_name, sub["yes"], sub["no"]
				])
			_append_group_lines(lines, entry, depth + 1, full_path, player_votes)
		else:
			var y: int = entry.get("yes", 0)
			var n: int = entry.get("no", 0)
			var total := y + n
			var yes_pct := int(round((float(y) / total) * 100.0)) if total > 0 else 0
			var my_vote: String = player_votes.get(full_path, "")
			
			if my_vote == "yes":
				lines.append("[b][color=#FFFFFF]%s[/color][/b] — [color=#06D6A0]%d%% yes[/color] (%d / %d)  [b][color=#FFD166][you: yes][/color][/b]" % [
					label_name, yes_pct, y, n
				])
			elif my_vote == "no":
				lines.append("[b][color=#FFFFFF]%s[/color][/b] — [color=#06D6A0]%d%% yes[/color] (%d / %d)  [b][color=#FFD166][you: no][/color][/b]" % [
					label_name, yes_pct, y, n
				])
			else:
				lines.append("[color=#999999]%s — %d%% yes (%d / %d)[/color]" % [
					label_name, yes_pct, y, n
				])

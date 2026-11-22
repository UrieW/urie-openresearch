class_name VoteSummaryData
extends Resource

@export var total_yes_votes: int = 0
@export var total_no_votes: int = 0
@export var reports_by_group: Dictionary = {}

# Safely retrieves { "yes": int, "no": int } for any folder subtotal or report path
# Example paths:
#   "podcasts" -> returns podcasts _subtotal
#   "podcasts/actual diaries/2023" -> returns 2023 _subtotal
#   "podcasts/actual diaries/2023/report1" -> returns report1 votes
func get_votes(path: String) -> Dictionary:
	var clean_path := path.strip_edges().trim_prefix("/").trim_suffix("/")
	if clean_path.is_empty():
		return { "yes": total_yes_votes, "no": total_no_votes }
	
	var parts := clean_path.split("/", false)
	var current: Variant = reports_by_group
	
	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return { "yes": 0, "no": 0 }
	
	if current is Dictionary:
		# If the path points to a folder, return its _subtotal
		if current.has("_subtotal"):
			return current["_subtotal"]
		# If the path points directly to a report entry, return its votes
		if current.has("yes") and current.has("no"):
			return current
	
	push_warning("Invalid vote node at path: " + path)
	return { "yes": 0, "no": 0 }

# Convenience helpers for single numbers
func get_yes(path: String = "") -> int:
	return get_votes(path).get("yes", 0)

func get_no(path: String = "") -> int:
	return get_votes(path).get("no", 0)

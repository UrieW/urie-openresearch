extends Resource
class_name ReportData

@export var title: String
@export var author: String
@export var date: String
@export var desc: String


func get_report_id() -> String:
	# Converts "res://reports/podcasts/dreams/log1.tres" -> "podcasts/dreams/log1"
	return resource_path.replace("res://reports/", "").trim_suffix(".tres")
	

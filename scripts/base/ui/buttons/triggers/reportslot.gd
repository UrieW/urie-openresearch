extends Node

var report: String = ""
var report_name: String = ""
var folder: String = ""
	
func _is_report_data() -> bool:
	if report.ends_with(".tres"):
		return true
	else:
		return false
		
func equip_report(target:String):
	report = target
	equip_folder()
	
	if !_is_report_data():
		report_name = folder
	else:
		var target_report: ReportData = load(report)
		report_name = target_report.title
	

func equip_folder():
	if !_is_report_data():
		folder = report.substr(report.rfind("/")+1)
	else:
		var rbd: String = report.get_base_dir()
		folder = rbd.substr(rbd.rfind("/")+1, rbd.length())

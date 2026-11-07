extends Button

@onready var report_slot: Node = $reportslot
@onready var itemnum:Label = $itemnum
var s3text: String = ""

var folder_icon = load("res://assets/gfx/gui/icons/akar-icons--folder/akar-icons--folder.png")
var doc_icon = load("res://assets/gfx/gui/icons/akar-icons-file/akar-icons--file.png")
var audio_icon = load("res://assets/gfx/gui/icons/fluent--speaker-0-20-filled/fluent--speaker-0-20-filled.png")
	
func equip_icon():
	if !report_slot._is_report_data():
		icon = folder_icon
	else:
		var report = load(report_slot.report)
		
		if report is TxtReportData:
			icon = doc_icon
		else:
			icon = audio_icon
			
func equip_report_info() -> void:
	equip_folder()
	if !report_slot._is_report_data():
		s3text = report_slot.folder
		return
	else:
		var report = load(report_slot.report)
		s3text = report.desc
		
func equip_folder()->void:
	report_slot.equip_folder()

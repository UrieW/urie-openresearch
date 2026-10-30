extends Button

@onready var report_slot: Node = $reportslot
@onready var itemnum:Label = $itemnum
var s1text: String = ""
var s2text: String = ""
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
		if  report is TxtReportData:
			#text vars fill with dummy text, with templates
			#the name and creators
			s1text ="Title:\
			titles\
			Author:\
			authors\
			\
			"
			#now, for the specs...
			s2text = "Words:\
			wordnum\
			Lines:\
			linenum\
			Paragraphs:\
			paranum\
			Sentences:\
			snum"
			
			#splice first var to give credit
			s1text = s1text.replace("titles", report.title)
			s1text = s1text.replace("authors", report.author)
			
			#then for the specs...
			s2text = s2text.replace("wordnum", str(report.words))
			s2text = s2text.replace("linenum", str(report.lines))
			s2text = s2text.replace("paranum", str(report.paragraphs))
			s2text = s2text.replace("snum", str(report.sentences))
		else:
			#if not a text report, i will do this to the same box
			#targets..
			s1text = "Title:\
			titles\
			Author:\
			authors\
			\
			"
			s2text = "Length:\
			  " + report.equip_time()
			
			#splice first var to give credit
			s1text = s1text.replace("titles", report.title)
			s1text = s1text.replace("authors", report.author)
		
		#fuse text together
		s1text += s2text
		s3text = report.desc
		
func equip_folder()->void:
	report_slot.equip_folder()

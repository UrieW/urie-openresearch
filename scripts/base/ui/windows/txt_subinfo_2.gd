extends VBoxContainer

@onready var t_name: RichTextLabel = $titles
@onready var au_name: Label = $authors
@onready var da_name: Label = $datetext
@onready var len_name: Label = $lentext
@onready var yes_name: Label = $yesvtext
@onready var no_name: Label = $novtext

func show_report_info(target:ReportData)->void:
	var report_id = target.get_report_id()
	var vote_data: VoteSummaryData = Votemanager.summary_data
	
	t_name.text = target.title
	au_name.text = target.author
	da_name.text = target.date
	
	if target is TxtReportData:
		len_name.text = str(target.pages) + "page"
		if target.pages > 1:
			len_name.text = str(target.pages) + "pages"
	elif target is PodcastReportData:
		len_name.text = target.equip_time()
		
	yes_name.text = "Y: " + str(vote_data.get_yes(report_id))
	no_name.text = "N: " + str(vote_data.get_no(report_id))

func hide_report_info()->void:
	t_name.text = ""
	au_name.text = ""
	da_name.text = ""
	len_name.text = ""
	yes_name.text = ""
	no_name.text = ""

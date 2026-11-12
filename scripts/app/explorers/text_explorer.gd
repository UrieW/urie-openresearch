extends Control

@onready var body: RichTextLabel = $explorer/text

@onready var p_label: Label = $controls/pgctrls/page
@onready var pg_ctrls: HBoxContainer = $controls/pgctrls
@onready var dbtn:Button = $controls/pgctrls/dbtn
@onready var tbtn:Button = $controls/pgctrls/tbtn
@onready var back_btn:Button = $controls/pgctrls/back
@onready var next_btn:Button = $controls/pgctrls/next
@onready var vote_btn:Button = $controls/pgctrls/votebtn
@onready var exit_btn:Button = $controls/pgctrls/close

@onready var c_report: ReportData = Globals.current_report

var b_text: Array[String]
var page_count: int = 0
var page_scroll_offsets: Array[float] = []

signal file_closed

func _ready() -> void:
	load_report(c_report)
	$subinfo/textrows.show_report_info(c_report)
	
#	d_btn.pressed.connect(show_disclaimer)
#	t_btn.pressed.connect(show_tutorial)
	back_btn.pressed.connect(prev_page)
	next_btn.pressed.connect(next_page)
#	vote_btn.pressed.connect(show_voting_page)
	exit_btn.pressed.connect(close_doc)
	
	next_btn.grab_focus.call_deferred()

func load_report(report: TxtReportData) -> void:
	body.scroll_active = false
	body.clip_contents = true
	body.text = report.body
	
	# Wait one frame for RichTextLabel to wrap and lay out all lines
	await get_tree().process_frame
	
	page_scroll_offsets = [0.0]
	var current_page_start_y: float = 0.0
	var box_height: float = body.size.y
	
	for line in range(body.get_line_count()):
		var line_top: float = body.get_line_offset(line)
		var line_bottom: float = line_top + body.get_line_height(line)
		
		# If this line crosses the bottom edge of the box, start a new page at this line
		if line_bottom - current_page_start_y > box_height:
			current_page_start_y = line_top
			page_scroll_offsets.append(current_page_start_y)
			
	report.pages = page_scroll_offsets.size()
	report.lines = body.get_line_count()
	report.current_page = 0
	
	# Start at page 1 immediately
	page_count = 1
	show_page(report, page_count)
	p_label.text = str(page_count)
	
func show_page(report: TxtReportData, page_index: int) -> void:
	report.current_page = clampi(page_index - 1, 0, page_scroll_offsets.size() - 1)
	body.get_v_scroll_bar().value = page_scroll_offsets[report.current_page]
	
func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		for i in pg_ctrls.get_children():
			if i.has_focus():
				if i.get_index() > 0:
					pg_ctrls.get_child(i.get_index() - 1).grab_focus.call_deferred()
				else:
					pg_ctrls.get_child(pg_ctrls.get_child_count() - 1).grab_focus.call_deferred()
		accept_event()
				
	if event.is_action_pressed("ui_right"):
		for i in pg_ctrls.get_children():
			if i.has_focus():
				if i.get_index() < pg_ctrls.get_child_count() - 1:
					pg_ctrls.get_child(i.get_index() + 1).grab_focus.call_deferred()
				else:
					pg_ctrls.get_child(0).grab_focus.call_deferred()
		accept_event()
	
	if event.is_action_pressed("ui_cancel"):
		close_doc()
		accept_event()
	
func _on_timer_timeout() -> void:
	print("Timer finished!")
	next_page()
	
func next_page() -> void:
	if page_count >= c_report.pages:
		return
		
	page_count += 1
	show_page(c_report, page_count)
	p_label.text = str(page_count)
	
func prev_page() -> void:
	if page_count <= 1:
		return
		
	page_count -= 1
	show_page(c_report, page_count)
	p_label.text = str(page_count)
	
func show_disclaimer():
	var DISCLAIMERPRELOAD: PackedScene = preload("res://scenes/app/disclaimer/disclaimer.tscn")
	var disclaimer: Control = DISCLAIMERPRELOAD.instantiate()
	get_tree().current_scene.add_child(disclaimer)
#	show_disclaimer()

#func show_tutorial():
#	var TUTORIALPRELOAD: PackedScene = preload()
#	var tutorial: Control = TUTORIALPRELOAD.instantiate()
#	get_tree().current_scene.add_child(tutorial)
	
#func show_voting_page():
#	var VOTINGPANELPRELOAD: PackedScene = preload()
#	var voting_panel: Control = VOTINGPANELPRELOAD.instantiate()
#	get_tree().current_scene.add_child(voting_panel)
#	votingpanel.unhide()
	
func close_doc():
	#shifts to the folder it was in...
	Globals.current_dir = Globals.current_report.resource_path.get_base_dir() 
	Globals.current_report = null

	file_closed.emit()

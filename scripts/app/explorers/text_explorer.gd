extends Control

@onready var body: RichTextLabel = $explorer/text
@onready var s_text1: RichTextLabel = $subinfo/subtext
@onready var s_text2: RichTextLabel = $subinfo2/subtext2

@onready var p_label: Label = $controls/pgctrls/page
@onready var pg_ctrls: HBoxContainer = $controls/pgctrls
@onready var dbtn:Button = $controls/pgctrls/dbtn
@onready var tbtn:Button = $controls/pgctrls/tbtn
@onready var back_btn:Button = $controls/pgctrls/back
@onready var next_btn:Button = $controls/pgctrls/next
@onready var vote_btn:Button = $controls/pgctrls/votebtn
@onready var exit_btn:Button = $controls/pgctrls/close

@onready var c_report: ReportData = Globals.current_report
#var sbkg: TextureRect = get_parent().get_root().get_child("sbkg")

var b_text: Array[String]
var page_count: int = 0

var focused: bool = false

func _ready() -> void:
	focused = true
#	sbkg.transition_to_background(sbkg.bkgt2)
	#max char for body of this node is 51 and lines, 5.
	b_text.assign(c_report.make_pages(c_report.body)) 
	body.text = b_text[0]
	page_count = 1
	p_label.text = str(page_count)
	
	var s1text: String = s_text1.text
	var s2text: String = s_text2.text
	
	s1text = s1text.replace("titles", c_report.title)
	s1text = s1text.replace("authors", c_report.author)
	
	s2text = s2text.replace("ynum", str(c_report.yvotes))
	s2text = s2text.replace("nnum", str(c_report.nvotes))
	
	s_text1.text = s1text
	s_text2.text = s2text
	
#	d_btn.pressed.connect(show_disclaimer)
#	t_btn.pressed.connect(show_tutorial)
	back_btn.pressed.connect(prev_page)
	next_btn.pressed.connect(next_page)
#	vote_btn.pressed.connect(show_voting_page)
	exit_btn.pressed.connect(close_doc)
	
	next_btn.grab_focus.call_deferred()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		for i in pg_ctrls.get_children():
			if i.has_focus():
				if i.get_index() > 0:
					pg_ctrls.get_child(i.get_index() - 1).grab_focus.call_deferred()
				else:
					pg_ctrls.get_child(pg_ctrls.get_child_count() - 1).grab_focus.call_deferred()
								
	if event.is_action_pressed("ui_right"):
		for i in pg_ctrls.get_children():
			if i.has_focus():
				if i.get_index() > pg_ctrls.get_child_count() - 1:
					pg_ctrls.get_child(i.get_index() + 1).grab_focus.call_deferred()
				else:
					pg_ctrls.get_child(0).grab_focus.call_deferred()
				
	if event.is_action_pressed("ui_cancel"):
		close_doc()
		
func _on_timer_timeout() -> void:
	if !focused:
		return
		
	print("Timer finished!")
	next_page()
	
func next_page():
	if !focused:
		return
		
	if page_count == b_text.size():
		return
		
	page_count += 1
	body.text = b_text[page_count-1]
	p_label.text = str(page_count)
	
func prev_page():
	if !focused:
		return
		
	if page_count == 1:
		return
		
	page_count -= 1
	body.text = b_text[page_count-1]
	p_label.text = str(page_count)
	
func show_disclaimer():
	if !focused:
		return
		
	var DISCLAIMERPRELOAD: PackedScene = preload("res://scenes/app/disclaimer/disclaimer.tscn")
	var disclaimer: Control = DISCLAIMERPRELOAD.instantiate()
	get_tree().current_scene.add_child(disclaimer)
#	show_disclaimer()
	focused = false
	
	

#func show_tutorial():
#	if !focused:
#		return
		
#	var TUTORIALPRELOAD: PackedScene = preload()
#	var tutorial: Control = TUTORIALPRELOAD.instantiate()
#	get_tree().current_scene.add_child(tutorial)
#	focused = false
	
#func show_voting_page():
#	if !focused:
#		return
		
#	var VOTINGPANELPRELOAD: PackedScene = preload()
#	var voting_panel: Control = VOTINGPANELPRELOAD.instantiate()
#	get_tree().current_scene.add_child(voting_panel)
#	votingpanel.unhide()
#	focused = false
	
func close_doc():
	#shifts to the folder it was in...
	Globals.current_dir = Globals.current_report.resource_path.get_base_dir() 
	Globals.current_report = null
	
	#changes focus back to the file explorer and changes backgrounds...
	get_parent().get_node("fileexplorer").grab_focus()
	get_parent().get_node("fileexplorer").focused = true
#	sbkg.transition_to_background(sbkg.bkgt1)
	focused = false
	queue_free()

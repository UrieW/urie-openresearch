extends Control

@onready var ex_y_btn: Button = $pmargs2/pwin/pwinmargs/vbox/btnmargs/votes/Panel/Yes
@onready var ex_n_btn: Button = $pmargs2/pwin/pwinmargs/vbox/btnmargs/votes/Panel2/No

@onready var y_btn: Button = $pmargs/pwin/pwinmargs/vbox/btnmargs/votes/Panel/Yes
@onready var n_btn: Button = $pmargs/pwin/pwinmargs/vbox/btnmargs/votes/Panel2/No
@onready var cancel_btn: Button = $pmargs/pwin/pwinmargs/vbox/btnmargs2/Panel/Cancel

var audio_exp = load("res://scenes/app/explorers/audio_explorer.tscn")
var text_exp = load("res://scenes/app/explorers/text_explorer.tscn")
 
var prev_focus: Control = null

var target_vote: String = "none"
var already_voted:bool = false

func _ready() -> void:
	prev_focus = get_viewport().gui_get_focus_owner()
	
	y_btn.pressed.connect(get_yes_vote)
	n_btn.pressed.connect(get_no_vote)
	cancel_btn.pressed.connect(revert_event)
	
	y_btn.focus_neighbor_top = y_btn.get_path()
	y_btn.focus_neighbor_bottom = cancel_btn.get_path()
	y_btn.focus_neighbor_left = n_btn.get_path()
	y_btn.focus_neighbor_right = n_btn.get_path()
	
	n_btn.focus_neighbor_top =  n_btn.get_path()
	n_btn.focus_neighbor_bottom = cancel_btn.get_path()
	n_btn.focus_neighbor_left = y_btn.get_path()
	n_btn.focus_neighbor_right = y_btn.get_path()
	
	cancel_btn.focus_neighbor_top =  cancel_btn.get_path()
	cancel_btn.focus_neighbor_bottom = cancel_btn.get_path()
	cancel_btn.focus_neighbor_left = y_btn.get_path()
	cancel_btn.focus_neighbor_right = n_btn.get_path()
	
	ex_y_btn.pressed.connect(vote)
	ex_n_btn.pressed.connect(revert_event)
	
	ex_y_btn.focus_neighbor_top = ex_y_btn.get_path()
	ex_y_btn.focus_neighbor_bottom = ex_y_btn.get_path()
	ex_y_btn.focus_neighbor_left = ex_n_btn.get_path()
	ex_y_btn.focus_neighbor_right = ex_n_btn.get_path()
	
	ex_n_btn.focus_neighbor_top = ex_n_btn.get_path()
	ex_n_btn.focus_neighbor_bottom = ex_n_btn.get_path()
	ex_n_btn.focus_neighbor_left = ex_y_btn.get_path()
	ex_n_btn.focus_neighbor_right = ex_y_btn.get_path()
	
	y_btn.grab_focus()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_parent().scene_file_path == text_exp.resource_path or audio_exp.resource_path:
			revert_event()
			get_viewport().set_input_as_handled()
				
	queue_free()
	
func revert_event()->void:
	if ex_y_btn.has_focus():
		$pmargs2.hide()
		$pmargs.unhide()
		y_btn.grab_focus()
		target_vote = "none"
	elif ex_n_btn.has_focus():
		$pmargs2.hide()
		$pmargs.unhide()
		n_btn.grab_focus()
		target_vote = "none"
	else:
		prev_focus.grab_focus()
		queue_free()
	
func get_yes_vote()->void:
	target_vote = "y"
	$pmargs.hide()
	$pmargs2.unhide()
	ex_y_btn.grab_focus()
	
func get_no_vote()->void:
	target_vote = "n"
	$pmargs.hide()
	$pmargs2.unhide()
	ex_y_btn.grab_focus()

func vote()->void:
	if target_vote == "y":
		if already_voted:
			Globals.current_report.nvotes -= 1
		Globals.current_report.yvotes += 1
	elif target_vote == "n":
		if already_voted:
			Globals.current_report.yvotes -= 1
		Globals.current_report.nvotes += 1

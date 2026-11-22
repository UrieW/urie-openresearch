extends Control

@onready var y_btn: Button = $pmargs2/pwin/pwinmargs/vbox/btnmargs/votes/Panel/Yes
@onready var n_btn: Button = $pmargs2/pwin/pwinmargs/vbox/btnmargs/votes/Panel2/No

var file_exp = load("res://scenes/app/explorers/file_explorer.tscn")
#var audio_exp = load("res://scenes/app/explorers/audio_explorer.tscn")
#var text_exp = load("res://scenes/app/explorers/text_explorer.tscn")
 
var prev_focus: Control = null

func _ready() -> void:
	prev_focus = get_viewport().gui_get_focus_owner()
	
	y_btn.pressed.connect(close_app)
	n_btn.pressed.connect(revert_event)
	
	y_btn.focus_neighbor_top = y_btn.get_path()
	y_btn.focus_neighbor_bottom = y_btn.get_path()
	y_btn.focus_neighbor_left = n_btn.get_path()
	y_btn.focus_neighbor_right = n_btn.get_path()
	
	n_btn.focus_neighbor_top =  n_btn.get_path()
	n_btn.focus_neighbor_bottom = n_btn.get_path()
	n_btn.focus_neighbor_left = y_btn.get_path()
	n_btn.focus_neighbor_right = y_btn.get_path()
	
	y_btn.grab_focus()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		revert_event()

func close_app()->void:
	var app_root := get_parent().get_parent().get_parent()
	if app_root and app_root.has_signal("app_closed"):
		app_root.app_closed.emit()
	elif get_parent().get_parent().has_signal("app_closed"):
		get_parent().get_parent().app_closed.emit()
	queue_free()
	
func revert_event()->void:
	if is_instance_valid(prev_focus):
		prev_focus.grab_focus()
	queue_free()
	

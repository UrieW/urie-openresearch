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
		if get_parent().scene_file_path == file_exp.resource_path:
			if file_exp.has_signal("app_closed"):
				prev_focus.grab_focus()
				get_viewport().set_input_as_handled()
				
	queue_free()

func close_app()->void:
	if  get_parent().scene_file_path == file_exp.resource_path:
		file_exp.app_closed.emit()
	queue_free()
	
func revert_event()->void:
	prev_focus.grab_focus()
	queue_free()
	

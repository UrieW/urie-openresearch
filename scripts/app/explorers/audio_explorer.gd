extends Control

@onready var cd_name_label: Label = $title/reportname

@onready var f_ctrls: HBoxContainer = $title/filctrls
@onready var dbtn:Button = $title/filctrls/dbtn
@onready var tbtn:Button = $title/filctrls/tbtn
@onready var close_btn:Button = $title/filctrls/closebtn
@onready var vbtn:Button = $title/filctrls/vbtn

@onready var audio_player: AudioStreamPlayer = $currentfile
@onready var play_pause_btn: Button = $explorer/playpause
@onready var time_slider: HSlider = $streambarbox/tracktimeslider/tracker
@onready var current_time_lbl: Label = $iteminfo/starttime
@onready var total_time_lbl: Label = $iteminfo/maxlength

var play_icon = load("res://assets/gfx/gui/icons/Play Button.png")
var pause_icon = load("res://assets/gfx/gui/icons/Pause Button.png")
var keyboard_seek_step: float = 2.0 # Adjust this to change seek speed (in seconds)

var is_user_dragging: bool = false
signal file_closed

func _ready() -> void:
	# Configure slider step for native arrow-key seeking
	time_slider.step = 0.01
	time_slider.value_changed.connect(_on_slider_value_changed)
	
	audio_player.stream = load(Globals.current_report.file)
	setup_labels()
	dbtn.pressed.connect(show_disclaimer)
	tbtn.pressed.connect(show_tutorial)
	close_btn.pressed.connect(close_doc)
#	vbtn.pressed.connect(show_voting_panel)
	
	# 1. Wire UI events up cleanly
	play_pause_btn.pressed.connect(_on_play_pause_pressed)
	time_slider.drag_started.connect(_on_slider_drag_started)
	time_slider.drag_ended.connect(_on_slider_drag_ended)
	
	# 2. Pre-calculate total track duration if media exists
	if audio_player.stream:
		var duration = audio_player.stream.get_length()
		time_slider.max_value = duration
		total_time_lbl.text = _format_time(duration)
	else:
		total_time_lbl.text = "00:00:000"
		
	audio_player.play()
	
	time_slider.grab_focus.call_deferred()
	
	for i in f_ctrls.get_children():
		if i is Button:
			i.focus_neighbor_bottom = play_pause_btn.get_path()
			i.focus_neighbor_top = i.get_path()
			
	play_pause_btn.focus_neighbor_bottom = time_slider.get_path()
	play_pause_btn.focus_neighbor_top = dbtn.get_path()
	
	time_slider.focus_neighbor_bottom = time_slider.get_path()
	time_slider.focus_neighbor_top = play_pause_btn.get_path()
	
	dbtn.focus_neighbor_left = vbtn.get_path()
	dbtn.focus_neighbor_right = tbtn.get_path()
	tbtn.focus_neighbor_left = dbtn.get_path()
	tbtn.focus_neighbor_right = close_btn.get_path()
	close_btn.focus_neighbor_left = tbtn.get_path()
	close_btn.focus_neighbor_right = vbtn.get_path()
	vbtn.focus_neighbor_left = close_btn.get_path()
	vbtn.focus_neighbor_right = dbtn.get_path()
					
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_doc()
		get_viewport().set_input_as_handled()
	elif time_slider.has_focus():
		if event.is_action_pressed("ui_right"):
			_seek_relative(keyboard_seek_step)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			_seek_relative(-keyboard_seek_step)
			get_viewport().set_input_as_handled()
			
func _seek_relative(offset: float) -> void:
	var target = clamp(audio_player.get_playback_position() + offset, 0.0, time_slider.max_value)
	audio_player.seek(target)
	time_slider.set_value_no_signal(target)
	current_time_lbl.text = _format_time(target)

func setup_labels() -> void:
	cd_name_label.text  = Globals.current_report.title
	
func _process(_delta: float) -> void:
	# FIX: Update slider value and time label when playing and NOT dragging
	if audio_player.playing and not is_user_dragging:
		var current_time = audio_player.get_playback_position()
		time_slider.set_value_no_signal(current_time)
		current_time_lbl.text = _format_time(current_time)
	
	# FIX: If the user IS dragging, update text label to show real-time target timestamp 
	elif is_user_dragging:
		current_time_lbl.text = _format_time(time_slider.value)

func _on_play_pause_pressed() -> void:
	if not audio_player.playing and not audio_player.stream_paused:
		# Direct play from the start if it has stopped entirely
		audio_player.play()
		play_pause_btn.icon = pause_icon
	elif audio_player.stream_paused:
		# Unpause right where it was held
		audio_player.stream_paused = false
		play_pause_btn.icon = pause_icon
	else:
		# Pause the track in its tracks
		audio_player.stream_paused = true
		play_pause_btn.icon = play_icon

# Stop updating slider via _process while the mouse drags it
func _on_slider_drag_started() -> void:
	is_user_dragging = true

# Snap audio timeline to exactly where the user drops the handle
func _on_slider_drag_ended(value_changed: bool) -> void:
	is_user_dragging = false
	if value_changed:
		audio_player.seek(time_slider.value)
		current_time_lbl.text = _format_time(time_slider.value)

func _on_slider_value_changed(new_value: float) -> void:
	# Only seek immediately if changed via keyboard/controller (not while mouse-dragging)
	if not is_user_dragging and time_slider.has_focus():
		audio_player.seek(new_value)
		current_time_lbl.text = _format_time(new_value)

# Utility helper to turn raw floats like 124.5 into formatted "02:04"
func _format_time(time_in_seconds: float) -> String:
	var hours:int = int(time_in_seconds / 3600)
	var minutes: int = int(time_in_seconds / 60)
	var seconds: int = int(time_in_seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
	
func close_doc():
	#stops playing file
	if audio_player.playing:
		audio_player.stop()
	
	#returns to the folder it was in...
	Globals.current_dir = Globals.current_report.resource_path.get_base_dir() 
	Globals.current_report = null

	file_closed.emit()

func show_disclaimer():	
	var DISCLAIMERPRELOAD: PackedScene = preload("res://scenes/app/disclaimer/disclaimer.tscn")
	var disclaimer: Control = DISCLAIMERPRELOAD.instantiate()	
	add_child(disclaimer)
	
func show_tutorial():
	var TUTORIALPRELOAD: PackedScene = preload("res://scenes/app/tutorials/2/scene/tutorial2.tscn")
	var tutorial: Control = TUTORIALPRELOAD.instantiate()
	add_child(tutorial)
	

#func show_voting_panel():
#	var VOTINGPANELPRELOAD: PackedScene = preload()
#	var voting_panel: Control = VOTINGPANELPRELOAD.instantiate()
#	add_child(voting_panel)

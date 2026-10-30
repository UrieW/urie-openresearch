extends Control

@onready var cd_name_label: Label = $title/reportname
@onready var year_name_label: Label = $title/yearname

@onready var dbtn:Button = $title/filctrls/dbtn
@onready var tbtn:Button = $title/filctrls/tbtn
@onready var close_btn:Button = $title/filctrls/closebtn
@onready var vbtn:Button = $title/filctrls/vbtn

@onready var audio_player: AudioStreamPlayer = $currentfile
@onready var play_pause_btn: Button = $explorer/playpause
@onready var time_slider: HSlider = $streambarbox/tracktimeslider/tracker
@onready var current_time_lbl: Label = $iteminfo/starttime
@onready var total_time_lbl: Label = $iteminfo/maxlength

#var sbkg: TextureRect = get_parent().get_root().get_child("sbkg")

var is_user_dragging: bool = false
var focused: bool = false

func _ready() -> void:
	focused = true
	audio_player.stream = load(Globals.current_report.file)
#	sbkg.transition_to_background(sbkg.bkgt3)
	setup_labels()
#	dbtn.pressed.connect(show_disclaimer)
#	tbtn.pressed.connect(show_tutorial)
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

func setup_labels() -> void:
	if !focused:
		return
		
	var rd_array: PackedStringArray = Globals.current_dir.split("/")
	var real_ldir: String = rd_array[rd_array.size()-2]
	
	cd_name_label.text  = Globals.current_report.title
	year_name_label.text = real_ldir
	
func _process(_delta: float) -> void:
	if !focused:
		return
		
	# Continuously update the slider position and text as long as the user isn't clicking it
	if audio_player.playing and not is_user_dragging:
		var current_time = audio_player.get_playback_position()
		time_slider.value = current_time
		current_time_lbl.text = _format_time(current_time)

func _on_play_pause_pressed() -> void:
	if !focused:
		return
		
	if not audio_player.playing and not audio_player.stream_paused:
		# Direct play from the start if it has stopped entirely
		audio_player.play()
		play_pause_btn.text = "Pause"
	elif audio_player.stream_paused:
		# Unpause right where it was held
		audio_player.stream_paused = false
		play_pause_btn.text = "Pause"
	else:
		# Pause the track in its tracks
		audio_player.stream_paused = true
		play_pause_btn.text = "Play"

# Stop updating slider via _process while the mouse drags it
func _on_slider_drag_started() -> void:
	if !focused:
		return
		
	is_user_dragging = true

# Snap audio timeline to exactly where the user drops the handle
func _on_slider_drag_ended(value_changed: bool) -> void:
	if !focused:
		return
		
	is_user_dragging = false
	if value_changed:
		audio_player.seek(time_slider.value)
		current_time_lbl.text = _format_time(time_slider.value)

# Utility helper to turn raw floats like 124.5 into formatted "02:04"
func _format_time(time_in_seconds: float) -> String:
	var minutes: int = int(time_in_seconds / 60)
	var seconds: int = int(time_in_seconds) % 60
	var mseconds: int = int((time_in_seconds - int(time_in_seconds)) * 1000)
	return "%02d:%02d:%03d" % [minutes, seconds, mseconds]
	
func close_doc():
	#stops playing file
	if audio_player.playing:
		audio_player.stop()
	
	#returns to the folder it was in...
	Globals.current_dir = Globals.current_report.resource_path.get_base_dir() 
	Globals.current_report = null
	
	#shifts focus to the file explorer and changes default background...
	get_parent().get_node("fileexplorer").grab_focus()
	get_parent().get_node("fileexplorer").focused = true
#	sbkg.transition_to_background(sbkg.bkgt1)
	focused = false
	queue_free()

#func show_disclaimer():
#	if !focused:
#		return
		
#	var DISCLAIMERPRELOAD: PackedScene = preload("res://scenes/app/disclaimer/disclaimer.tscn")
#	var disclaimer: Control = DISCLAIMERPRELOAD.instantiate()	
#	get_tree().current_scene.add_child(disclaimer)
#	show_disclaimer()
#	focused = false
	
#func show_tutorial():
#	if !focused:
#		return
		
#	var TUTORIALPRELOAD: PackedScene = preload()
#	var tutorial: Control = TUTORIALPRELOAD.instantiate()
#	get_tree().current_scene.add_child(tutorial3)
#	focused = false
	

#func show_voting_panel():
#	if !focused:
#		return
		
#	var VOTINGPANELPRELOAD: PackedScene = preload()
#	var voting_panel: Control = VOTINGPANELPRELOAD.instantiate()
#	get_tree().current_scene.add_child(voting_panel)
#	voting_panel.unhide()
#	focused = false

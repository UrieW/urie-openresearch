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

var keyboard_seek_step: float = 2.0 # Adjust this to change seek speed (in seconds)

var is_user_dragging: bool = false
signal file_closed

func _ready() -> void:
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
	
	time_slider.grab_focus.call_deferred()
	
func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		if play_pause_btn.has_focus():
			time_slider.grab_focus.call_deferred()
		for i in f_ctrls.get_children():
			if i.has_focus():
				play_pause_btn.grab_focus.call_deferred()
		accept_event()
	
	if event.is_action_pressed("ui_up"):
		if play_pause_btn.has_focus():
			f_ctrls.get_child(0).grab_focus.call_deferred()
		if time_slider.has_focus():
				play_pause_btn.grab_focus.call_deferred()
		accept_event()
		
	if event.is_action_pressed("ui_left"):
		if time_slider.has_focus():
			# Lower value, clamp it so it doesn't go below 0
			time_slider.value = max(0.0, time_slider.value - keyboard_seek_step)
			audio_player.seek(time_slider.value)
			current_time_lbl.text = _format_time(time_slider.value)
			get_viewport().set_input_as_handled() # Prevent focus from breaking out
		for i in f_ctrls.get_children():
			if i.has_focus():
				if i.get_index() > 0:
					f_ctrls.get_child(i.get_index() -1).grab_focus.call_deferred()
				else:
					time_slider.grab_focus.call_deferred()
		accept_event()
								
	if event.is_action_pressed("ui_right"):
		if time_slider.has_focus():
			# Raise value, clamp it to maximum track duration
			time_slider.value = min(time_slider.max_value, time_slider.value + keyboard_seek_step)
			audio_player.seek(time_slider.value)
			current_time_lbl.text = _format_time(time_slider.value)
			get_viewport().set_input_as_handled() # Prevent focus from breaking out
		for i in f_ctrls.get_children():
			if i.has_focus():
				if i.get_index() < f_ctrls.get_child_count()-1:
					f_ctrls.get_child(i.get_index() +1).grab_focus.call_deferred()
				else:
					play_pause_btn.grab_focus.call_deferred()
		accept_event()
				
	if event.is_action_pressed("ui_cancel"):
		close_doc()
		accept_event()

func hbox_focus_first_item():
	if f_ctrls.get_child_count() > 0:
		var first_child = f_ctrls.get_child(0)
		
		# If your child is a custom Scene container holding a button:
		if first_child.has_node("dbtn"):
			first_child.get_node("dbtn").grab_focus()
			
		# If the child itself is the Button node:
		elif first_child is Button:
			first_child.grab_focus()
	
func setup_labels() -> void:
	cd_name_label.text  = Globals.current_report.title
	
func _process(_delta: float) -> void:
	# FIX: Update slider value and time label when playing and NOT dragging
	if audio_player.playing and not is_user_dragging:
		var current_time = audio_player.get_playback_position()
		time_slider.value = current_time
		current_time_lbl.text = _format_time(current_time)
	
	# FIX: If the user IS dragging, update text label to show real-time target timestamp 
	elif is_user_dragging:
		current_time_lbl.text = _format_time(time_slider.value)

func _on_play_pause_pressed() -> void:
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
	is_user_dragging = true

# Snap audio timeline to exactly where the user drops the handle
func _on_slider_drag_ended(value_changed: bool) -> void:
	is_user_dragging = false
	if value_changed:
		audio_player.seek(time_slider.value)
		current_time_lbl.text = _format_time(time_slider.value)

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

#func show_disclaimer():
#	if !focused:
#		return
		
#	var DISCLAIMERPRELOAD: PackedScene = preload("res://scenes/app/disclaimer/disclaimer.tscn")
#	var disclaimer: Control = DISCLAIMERPRELOAD.instantiate()	
#	get_tree().current_scene.add_child(disclaimer)
#	show_disclaimer()
	
#func show_tutorial():
#	var TUTORIALPRELOAD: PackedScene = preload()
#	var tutorial: Control = TUTORIALPRELOAD.instantiate()
#	get_tree().current_scene.add_child(tutorial3)
	

#func show_voting_panel():
#	var VOTINGPANELPRELOAD: PackedScene = preload()
#	var voting_panel: Control = VOTINGPANELPRELOAD.instantiate()
#	get_tree().current_scene.add_child(voting_panel)
#	voting_panel.unhide()

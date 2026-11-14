extends Control

@onready var scrolls: ScrollContainer = $scrolls
var def_scrolls = preload("res://scenes/app/tutorials/3/app menu/app_menu.tscn")
var alt_scrolls1 = preload("res://scenes/app/tutorials/3/events/event1.tscn")
var alt_scrolls2 = preload("res://scenes/app/tutorials/3/events/event2.tscn")

var current_page: int = 0
const TOTAL_PAGES: int = 9
const PAGE_WIDTH: int = 640 # 600px panel width + 40px HBox separation
var _previous_focus: Control = null

func _ready() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	# Jump to a specific pixel position
	scrolls.scroll_horizontal = 0
	set_default_focus()

func smooth_scroll_to(target_x: int, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(scrolls, "scroll_horizontal", target_x, duration)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if scrolls.scene_file_path == alt_scrolls2.resource_path:
			current_page += 1
			if current_page < TOTAL_PAGES:
				smooth_scroll_to(current_page * PAGE_WIDTH)
			else:
				switch_to_scrolls(def_scrolls)
			get_viewport().set_input_as_handled()
		elif scrolls.scene_file_path == alt_scrolls1.resource_path:
			switch_to_scrolls(def_scrolls)
			get_viewport().set_input_as_handled()

func smooth_fade_to_and_kill(target:Control, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 0, duration)
	tween.finished.connect(target.queue_free)

func switch_to_scrolls(target:PackedScene):
	smooth_fade_to_and_kill(scrolls)
	current_page = 0
	scrolls = target.instantiate()
	fade_and_add_child(scrolls)
	set_default_focus()
	
func get_to_alt1()-> void:
	switch_to_scrolls(alt_scrolls1)

func get_to_alt2()-> void:
	switch_to_scrolls(alt_scrolls2)
	
func set_default_focus()-> void:
	if scrolls.scene_file_path == def_scrolls.resource_path:
		var btn1 = scrolls.get_node("vbox/margs1/Panel/Button") as Button
		var btn2 = scrolls.get_node("vbox/margs2/Panel/Button") as Button
		var btn3 = scrolls.get_node("vbox/margs3/Panel/Button") as Button

		btn1.focus_neighbor_bottom = btn2.get_path()
		btn1.focus_neighbor_top = btn3.get_path()
		btn2.focus_neighbor_bottom = btn3.get_path()
		btn2.focus_neighbor_top = btn1.get_path()
		btn3.focus_neighbor_bottom = btn1.get_path()
		btn3.focus_neighbor_top = btn2.get_path()
		
		btn1.focus_neighbor_left = btn1.get_path()
		btn1.focus_neighbor_right = btn1.get_path()
		btn2.focus_neighbor_left = btn2.get_path()
		btn2.focus_neighbor_right = btn2.get_path()
		btn3.focus_neighbor_left = btn3.get_path()
		btn3.focus_neighbor_right = btn3.get_path()
		
		btn1.pressed.connect(get_to_alt1)
		btn2.pressed.connect(get_to_alt2)
		btn3.pressed.connect(close_doc)
		
		btn1.grab_focus()
		
func close_doc()->void:
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()
	smooth_fade_to_and_kill(self)
	
func fade_and_add_child(child_node: CanvasItem, duration: float = 0.3)->void:
	if not is_instance_valid(child_node):
		return
		
	child_node.modulate.a = 0.0
	add_child(child_node)
	
	# 2. Bind a new tween to the parent's lifecycle
	var tween = create_tween()
	
	# 3. Target the specific child's alpha property
	tween.tween_property(child_node, "modulate:a", 1.0, duration)

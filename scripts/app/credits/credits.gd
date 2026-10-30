extends Control

@export var scroll_speed: float = 40.0 # Pixels per second

@onready var scrolls: ScrollContainer = $scrolls
@onready var lab: RichTextLabel = $scrolls/margins/lab
@onready var margins: MarginContainer = $scrolls/margins
@onready var bgm_p: AudioStreamPlayer = $bgmp

var scrolling: bool = true
var scroll_pos: float = 0.0

func _ready() -> void:
	scrolls.scroll_vertical = 0
	# Godot 4.7 requires a frame delay to build the RichTextLabel size from text
	set_process(false)
	await get_tree().process_frame
	set_process(true)
	bgm_p.play()

func _process(delta: float) -> void:
	if scrolling:
		scroll_pos += scroll_speed * delta
		scrolls.scroll_vertical = int(scroll_pos)
		
		# Get the actual height calculation from the label itself
		var label_height = lab.get_content_height()
		
		# Pull padding values explicitly from the MarginContainer
		var top_pad = margins.get_theme_constant("margin_top")
		var bottom_pad = margins.get_theme_constant("margin_bottom")
		
		# Calculate exact scroll bounds
		var total_height = label_height + top_pad + bottom_pad
		var max_scroll = total_height - scrolls.size.y
		
		# Safety check to ensure size calculation has finished
		if label_height > 0 and scrolls.scroll_vertical >= max_scroll:
			scrolling = false
			_on_credits_finished()


func _input(event: InputEvent) -> void:
	# Optional: Allow players to skip the credits with a keypress or click
	if event.is_pressed() and not event.is_echo():
		_on_credits_finished()

func _on_credits_finished() -> void:
	# Change back to the main menu or exit the scene
	print("Credits finished!")
	bgm_p.stop()
	# get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

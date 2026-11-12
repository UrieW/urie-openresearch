extends Node

#file open signals controls
signal text_opened
signal audio_opened

#scrolling bkg, somehow, n ot refffed yet, grrrrrr...
@onready var s_bkg = $sbkg

# Reference to the container node where the scene will be injected
@onready var container = $subscnbox

# Preload the sub-scenes you want to swap between
var scene_a = preload("res://scenes/app/explorers/file_explorer.tscn")
var scene_b = preload("res://scenes/app/explorers/audio_explorer.tscn")
var scene_c = preload("res://scenes/app/explorers/text_explorer.tscn")
#var scene_b = preload("res://scenes/sub_scene_b.tscn")

# This variable tracks the currently active sub-scene instance
var current_sub_scene = null

func _ready() -> void:
	# Load the default scene when starting
	switch_sub_scene(scene_a)
	text_opened.connect(on_text_opened)
	audio_opened.connect(on_audio_opened)

func switch_sub_scene(new_scene: PackedScene, delay: float = 0.5) -> void:
	# 1. Safely remove the existing sub-scene if there is one
	if is_instance_valid(current_sub_scene):
		if current_sub_scene == scene_b:
			audio_opened.emit()
		elif current_sub_scene == scene_c:
			text_opened.emit()
			
		fade_and_remove_child(current_sub_scene, 0.5)
	
	# Wait for the fade-out (1.5s) PLUS your custom delay before continuing
	await get_tree().create_timer(1.5 + delay).timeout
	
	# 2. Create an instance of the new scene
	current_sub_scene = new_scene.instantiate()
	if current_sub_scene.has_signal("file_closed"):
		current_sub_scene.file_closed.connect(on_file_closed)
	
	# 3. Add it as a child of your container node
	fade_and_add_child(current_sub_scene, 0.5)

## Smoothly fades out a specified child node and destroys it
func fade_and_remove_child(child_node: CanvasItem, duration: float = 0.5) -> void:
	# 1. Validation check to prevent crashes if the child was already freed elsewhere
	if not is_instance_valid(child_node):
		return
		
	# 2. Bind a new tween to the parent's lifecycle
	var tween = create_tween()
	
	# 3. Target the specific child's alpha property
	tween.tween_property(child_node, "modulate:a", 0.0, duration)
	
	# 4. Tell the tween to free the child node the instant the animation ends
	tween.tween_callback(child_node.queue_free)

func fade_and_add_child(child_node: CanvasItem, duration: float = 0.5)->void:
	if not is_instance_valid(child_node):
		return
		
	child_node.modulate.a = 0.0
	container.add_child(child_node)
	
	# 2. Bind a new tween to the parent's lifecycle
	var tween = create_tween()
	
	# 3. Target the specific child's alpha property
	tween.tween_property(child_node, "modulate:a", 1.0, duration)
	
func on_file_closed()->void:
		s_bkg.transition_to_background(s_bkg.bkgt1)
		switch_sub_scene(scene_a)

func on_audio_opened()->void:
	s_bkg.transition_to_background(s_bkg.bkgt2)
	switch_sub_scene(scene_b)

func on_text_opened()->void:
	s_bkg.transition_to_background(s_bkg.bkgt3)
	switch_sub_scene(scene_c)

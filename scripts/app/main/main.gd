extends Node

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

func switch_sub_scene(new_scene: PackedScene) -> void:
	# 1. Safely remove the existing sub-scene if there is one
	if is_instance_valid(current_sub_scene):
		fade_and_remove_child(current_sub_scene, 1.5)
	
	# 2. Create an instance of the new scene
	current_sub_scene = new_scene.instantiate()
	
	# 3. Add it as a child of your container node
	fade_and_add_child(current_sub_scene, 1.5)

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
	

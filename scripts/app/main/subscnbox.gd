extends Node

# Reference to the container node where the scene will be injected
@onready var container = $sub

# Preload the sub-scenes you want to swap between
var scene_a = preload("res://scenes/sub_scene_a.tscn")
var scene_b = preload("res://scenes/sub_scene_b.tscn")

# This variable tracks the currently active sub-scene instance
var current_sub_scene = null

func _ready() -> void:
	# Load the default scene when starting
	switch_sub_scene(scene_a)

func switch_sub_scene(new_scene: PackedScene) -> void:
	# 1. Safely remove the existing sub-scene if there is one
	if is_instance_valid(current_sub_scene):
		current_sub_scene.queue_free()
	
	# 2. Create an instance of the new scene
	current_sub_scene = new_scene.instantiate()
	
	# 3. Add it as a child of your container node
	container.add_child(current_sub_scene)

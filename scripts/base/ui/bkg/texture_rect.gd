extends TextureRect

# 1. Preload your background texture files
@export var bkgt1: Texture2D = preload("res://assets/gfx/gui/backgrounds/theme1.png")
@export var bkgt2: Texture2D = preload("res://assets/gfx/gui/backgrounds/theme2.png")
@export var bkgt3: Texture2D = preload("res://assets/gfx/gui/backgrounds/theme3.png")

@export var fade_duration: float = 1.5 # Duration of crossfade in seconds
var shader_mat: ShaderMaterial

func _ready() -> void:
	shader_mat = material as ShaderMaterial
	# Ensure the TextureRect asset uses repeating textures natively
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture = bkgt1

func transition_to_background(new_texture: Texture2D) -> void:
	if not shader_mat:
		push_error("Missing ShaderMaterial on TextureRect.")
		return
		
	# 1. Set the secondary texture slot in the shader
	shader_mat.set_shader_parameter("texture_next", new_texture)
	
	# 2. Reset fade factor to 0 (all current texture)
	shader_mat.set_shader_parameter("fade_factor", 0.0)
	
	# 3. Create a Tween to animate the shader property smoothly to 1.0
	var tween = create_tween()
	tween.tween_property(shader_mat, "shader_parameter/fade_factor", 1.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# 4. Clean up setup once transition finishes
	tween.finished.connect(func():
		# Commit the secondary texture as our primary texture
		texture = new_texture
		# Instantly reset fade factor back to 0.0
		shader_mat.set_shader_parameter("fade_factor", 0.0))

shader_type canvas_item;

// Uniforms for scrolling
uniform vec2 direction = vec2(1.0, 1.0);
uniform float speed_scale = 0.25;

// Uniforms for crossfading textures
uniform sampler2D texture_next : hint_screen_texture, filter_nearest, repeat_enable; 
uniform float fade_factor : hint_range(0.0, 1.0) = 0.0; // 0.0 = old texture, 1.0 = new texture

void fragment() {
    // Standard scrolling texture coordinate calculation
    vec2 move = direction * TIME * speed_scale;
    vec2 uv_moved = UV + move;
    
    // Sample both the default TEXTURE and our runtime texture_next
    vec4 tex_current = texture(TEXTURE, uv_moved);
    vec4 tex_next = texture(texture_next, uv_moved);
    
    // Smoothly mix/blend between the two textures based on fade_factor
    COLOR = mix(tex_current, tex_next, fade_factor);
}

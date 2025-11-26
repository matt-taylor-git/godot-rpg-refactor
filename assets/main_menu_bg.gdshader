// Main Menu Background Shader
// Creates a subtle animated atmosphere with color gradients and gentle wave effects

shader_type canvas_item;
render_mode blend_mix;

// Uniforms for control
uniform sampler2D texture_base : hint_default_white;
uniform float time_scale : hint_range(0.0, 2.0) = 0.5;
uniform float wave_intensity : hint_range(0.0, 1.0) = 0.3;
uniform vec3 color_primary : source_color = vec3(0.1, 0.1, 0.15);
uniform vec3 color_accent : source_color = vec3(0.4, 0.2, 0.8);
uniform bool reduce_motion = false;

void fragment() {
	// Base color with gradient
	vec3 base_color = mix(color_primary, color_accent, UV.y * 0.5);
	
	// Apply time-based animation only if reduce_motion is false
	float time_factor = 0.0;
	if (!reduce_motion) {
		time_factor = sin(TIME * time_scale + UV.x * 3.0) * wave_intensity * 0.1;
	}
	
	// Subtle wave effect
	vec2 wave_uv = UV;
	wave_uv.x += time_factor;
	
	// Sample texture if provided
	vec4 tex_color = texture(texture_base, wave_uv);
	
	// Blend texture with gradient
	vec3 final_color = mix(base_color, tex_color.rgb, tex_color.a * 0.3);
	
	// Very subtle luminance oscillation
	float luminance_mod = 1.0 + (sin(TIME * time_scale * 0.5) * wave_intensity * 0.05);
	
	// Output color with alpha
	COLOR = vec4(final_color * luminance_mod, 1.0);
}

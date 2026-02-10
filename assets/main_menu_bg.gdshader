// Main Menu Background Shader
// Creates a dark fantasy atmosphere with warm tones, grain texture, and subtle ember glow

shader_type canvas_item;
render_mode blend_mix;

// Uniforms for control
uniform sampler2D texture_base : hint_default_white;
uniform float time_scale : hint_range(0.0, 2.0) = 0.5;
uniform float wave_intensity : hint_range(0.0, 1.0) = 0.3;
uniform vec3 color_primary : source_color = vec3(0.06, 0.05, 0.04);
uniform vec3 color_accent : source_color = vec3(0.15, 0.10, 0.06);
uniform bool reduce_motion = false;

// Grain and ember effects
uniform float grain_intensity : hint_range(0.0, 0.1) = 0.03;
uniform float ember_intensity : hint_range(0.0, 0.3) = 0.08;
uniform vec3 ember_color : source_color = vec3(0.9, 0.4, 0.1);
uniform float overlay_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Base color with gradient (dark at top, slightly warmer at bottom)
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

	// Very subtle luminance oscillation (only when motion enabled)
	float luminance_mod = 1.0;
	if (!reduce_motion) {
		luminance_mod = 1.0 + (sin(TIME * time_scale * 0.5) * wave_intensity * 0.05);
	}

	// Apply luminance
	final_color *= luminance_mod;

	// Add grain texture for aged/weathered look
	float noise = fract(sin(dot(UV * 1000.0, vec2(12.9898, 78.233))) * 43758.5453);
	final_color += vec3(noise * grain_intensity);

	// Add ember glow at bottom edge (only when motion enabled)
	if (!reduce_motion) {
		float ember = sin(TIME * 0.7) * 0.5 + 0.5;
		float mask = smoothstep(0.85, 1.0, UV.y);
		final_color += ember_color * ember * mask * ember_intensity;
	}

	// Output color with alpha
	COLOR = vec4(final_color, overlay_alpha);
}

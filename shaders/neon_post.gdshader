shader_type canvas_item;
// Full-screen post-process for the neon look:
// bloom (thresholded multi-tap blur), chromatic aberration, vignette,
// faint scanlines and a red damage flash. Runs on the Compatibility renderer.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_strength : hint_range(0.0, 4.0) = 2.2;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.22;
uniform float bloom_radius = 6.0;
uniform float aberration : hint_range(0.0, 0.02) = 0.0035;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float scanline_strength : hint_range(0.0, 0.3) = 0.05;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.1, 0.3, 1.0);

vec3 bright(vec3 c) {
	return max(c - vec3(bloom_threshold), vec3(0.0)) / (1.0 - bloom_threshold);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 centered = uv - 0.5;

	vec3 col;
	col.r = texture(screen_tex, uv + centered * aberration).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - centered * aberration).b;

	vec3 bloom = vec3(0.0);
	float total = 0.0;
	for (int ring = 1; ring <= 3; ring++) {
		float r = float(ring) * bloom_radius;
		float w = 1.0 / float(ring);
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.785398 + float(ring) * 0.39;
			vec2 off = vec2(cos(a), sin(a)) * r * px;
			bloom += bright(textureLod(screen_tex, uv + off, float(ring)).rgb) * w;
			total += w;
		}
	}
	col += bloom / total * bloom_strength;

	float vig = 1.0 - vignette_strength * dot(centered, centered) * 1.8;
	col *= vig;
	col *= 1.0 - scanline_strength * (0.5 + 0.5 * sin(FRAGCOORD.y * 3.14159));
	col = mix(col, flash_color.rgb, flash * clamp(length(centered) * 1.6, 0.0, 1.0) * 0.55);

	COLOR = vec4(col, 1.0);
}

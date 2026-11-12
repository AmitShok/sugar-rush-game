shader_type canvas_item;
// Balatro-style swirling paint background in candy colours (v0.25).
// Pixelated into chunky cells and posterised into bands so it reads as pixel art.
uniform vec4 color_light : source_color = vec4(0.91, 0.36, 0.55, 1.0); // berry pink
uniform vec4 color_mid : source_color = vec4(0.40, 0.22, 0.56, 1.0); // plum
uniform vec4 color_dark : source_color = vec4(0.13, 0.07, 0.18, 1.0); // dark chocolate
uniform vec4 color_accent : source_color = vec4(0.98, 0.78, 0.40, 1.0); // caramel
uniform float speed = 0.05; // set to 0 by the Reduced motion option
uniform float pixel_size = 4.0;
uniform float bands = 9.0;
uniform vec2 resolution = vec2(1152.0, 720.0);
uniform float clock = 0.0; // advanced from script so motion can pause cleanly

void fragment() {
	vec2 cell = floor(UV * resolution / pixel_size) * pixel_size / resolution;
	vec2 p = (cell - 0.5) * vec2(resolution.x / resolution.y, 1.0) * 2.4;
	float t = clock * speed;
	float radius = length(p);
	float angle = atan(p.y, p.x) + radius * 1.4 - t * 1.8;
	vec2 q = vec2(cos(angle), sin(angle)) * radius;
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		q += 0.55 * vec2(sin(q.y * 1.6 + t * 2.6 + fi), cos(q.x * 1.8 - t * 2.2 + fi * 1.3));
	}
	float paint = 0.5 + 0.5 * sin(q.x * 1.25 + q.y * 1.05);
	float ribbon = 0.5 + 0.5 * sin(length(q) * 2.1 - t * 3.5);
	vec3 col = mix(color_dark.rgb, color_mid.rgb, smoothstep(0.15, 0.85, paint));
	col = mix(col, color_light.rgb, smoothstep(0.72, 0.96, ribbon) * 0.55);
	col = mix(col, color_accent.rgb, smoothstep(0.93, 1.0, paint * ribbon) * 0.35);
	// Darken the edges like a lit table.
	col *= 1.0 - 0.45 * smoothstep(0.6, 1.4, length(UV - 0.5) * 2.0);
	col = floor(col * bands + 0.5) / bands;
	COLOR = vec4(col, 1.0);
}

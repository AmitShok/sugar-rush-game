shader_type canvas_item;
// Balatro-style fake 3D tilt for cards (v0.25). The side tilted away shrinks, and a soft
// diagonal sheen slides across the card while it is hovered. Driven by scripts/ui/card_tilt.gd.
// v0.30: Joker editions are drawn here too, so they move with the card and react to the tilt:
//   1 Foil: metallic card with silver-blue bands that sweep across as it tilts.
//   2 Holographic: rainbow interference shimmer that shifts with the angle.
//   3 Polychrome: the card's colours rotate through the rainbow.
uniform vec2 tilt = vec2(0.0); // -1..1 on each axis, toward the pointer
uniform float strength = 0.24;
uniform float inset = 0.05; // headroom so the near side never clips
uniform float sheen = 0.0; // 0..1 hover amount
uniform int edition = 0; // 0 none, 1 foil, 2 holographic, 3 polychrome
uniform float clock = 0.0; // seconds, advanced from script (pauses with Reduced motion)
uniform vec2 card_pixels = vec2(140.0, 188.0); // art resolution, so effects stay pixel-chunky
varying vec4 tint; // vertex colour and modulate only (COLOR in fragment already includes the texture)

void vertex() {
	tint = COLOR;
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.x) / (6.0 * d + 1e-5)), d / (q.x + 1e-5), q.x);
}

vec3 apply_edition(vec3 rgb, vec2 p) {
	// p is the card-space position snapped to 2x2 art pixels. Effects are strong on purpose so an
	// edition card is obvious at a glance, and grow while the card is hovered.
	float angle = tilt.x * 1.1 + tilt.y * 0.8;
	float boost = 1.0 + sheen * 0.6;
	if (edition == 1) {
		// Foil: cool BLUE CHROME. The art becomes blue-tinted greyscale with high-contrast dark and
		// bright reflection bands, like polished metal catching the light as it tilts.
		float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
		vec3 chrome = vec3(lum) * vec3(0.55, 0.75, 1.15) + vec3(0.02, 0.06, 0.16);
		float wave = sin((p.x * 1.1 + p.y * 1.7) * 8.0 + angle * 8.0 + clock * 1.3);
		float bright = smoothstep(0.55, 1.0, wave);
		float dark = smoothstep(0.55, 1.0, -wave);
		float fine = smoothstep(0.75, 1.0, sin((p.x * 2.4 - p.y * 1.2) * 19.0 - angle * 6.0 + clock * 1.8));
		vec3 metal = mix(rgb, chrome, 0.8);
		metal = metal * (1.0 - 0.45 * dark) + bright * vec3(0.6, 0.85, 1.0) * 0.75 * boost;
		return metal + fine * vec3(0.85, 0.95, 1.0) * 0.3 * boost;
	}
	if (edition == 2) {
		// Holographic: hot MAGENTA-PINK. Keeps the art's full colour (never greyed like Foil), tints
		// it pink, and adds a sparkling dot grid and hologram lines that flicker with the tilt.
		vec3 magenta = vec3(1.0, 0.25, 0.7);
		float lines = step(0.5, fract(p.y * card_pixels.y / 4.0));
		vec3 holo = mix(rgb, rgb * vec3(1.25, 0.6, 1.0) + magenta * 0.25, 0.75);
		vec2 cell = floor(p * card_pixels / 8.0);
		float sparkle_phase = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		float twinkle = smoothstep(0.75, 1.0, sin(sparkle_phase * 6.2832 + clock * 3.0 + angle * 6.0));
		vec2 in_cell = fract(p * card_pixels / 8.0);
		float dot_mask = step(length(in_cell - 0.5), 0.2);
		float sweep = 0.5 + 0.5 * sin((p.x - p.y) * 10.0 + angle * 7.0 + clock * 1.6);
		return holo * (0.88 + 0.12 * lines) + magenta * sweep * 0.35 * boost + vec3(1.0, 0.85, 1.0) * twinkle * dot_mask * 0.9;
	}
	if (edition == 3) {
		// Polychrome: the whole card recoloured through a rainbow that flows as it tilts.
		vec3 hsv = rgb2hsv(rgb);
		float shift = fract(p.y * 0.7 + p.x * 0.4 + angle * 0.5 + clock * 0.15);
		hsv.x = fract(hsv.x + shift);
		hsv.y = clamp(hsv.y * 1.6 + 0.3, 0.0, 1.0);
		hsv.z = clamp(hsv.z * 1.08 + 0.05, 0.0, 1.0);
		return mix(rgb, hsv2rgb(hsv), 0.95);
	}
	return rgb;
}

// Glowing animated rim in the edition's colours, so editions stand out even when small.
vec3 edition_rim(vec2 src, vec2 p) {
	float edge = min(min(src.x, 1.0 - src.x) * card_pixels.x, min(src.y, 1.0 - src.y) * card_pixels.y);
	float glow = 1.0 - smoothstep(2.0, 9.0, edge);
	if (glow <= 0.0) return vec3(0.0);
	float pulse = 0.75 + 0.25 * sin(clock * 3.0 + (p.x + p.y) * 12.0);
	vec3 col = vec3(0.7, 0.88, 1.0);
	if (edition == 2) col = mix(vec3(1.0, 0.2, 0.65), vec3(1.0, 0.6, 0.9), 0.5 + 0.5 * sin(clock * 2.0 + (p.x - p.y) * 9.0));
	if (edition == 3) col = hsv2rgb(vec3(fract((p.x - p.y) * 1.5 + clock * 0.25), 0.9, 1.0));
	return col * glow * pulse * (0.8 + sheen * 0.5);
}

void fragment() {
	vec2 uv = (UV - 0.5) / (1.0 - inset);
	float depth = 1.0 + strength * (tilt.x * uv.x + tilt.y * uv.y);
	vec2 src = uv / depth + 0.5;
	if (src.x < 0.0 || src.x > 1.0 || src.y < 0.0 || src.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 c = texture(TEXTURE, src);
		if (edition > 0 && c.a > 0.0) {
			vec2 p = floor(src * card_pixels / 2.0) * 2.0 / card_pixels;
			c.rgb = apply_edition(c.rgb, p) + edition_rim(src, p);
		}
		float lane = (src.x - src.y) - (tilt.x - tilt.y) * 0.7;
		float band = 1.0 - smoothstep(0.0, 0.16, abs(lane));
		c.rgb += band * 0.16 * sheen * c.a;
		// Faces turned away from the light read slightly darker.
		c.rgb *= 1.0 - 0.06 * strength * (tilt.x * uv.x + tilt.y * uv.y);
		COLOR = c * tint;
	}
}

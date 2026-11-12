shader_type canvas_item;
// Balatro-style fake 3D tilt for cards (v0.25). The side tilted away shrinks, and a soft
// diagonal sheen slides across the card while it is hovered. Driven by scripts/ui/card_tilt.gd.
uniform vec2 tilt = vec2(0.0); // -1..1 on each axis, toward the pointer
uniform float strength = 0.24;
uniform float inset = 0.05; // headroom so the near side never clips
uniform float sheen = 0.0; // 0..1 hover amount
varying vec4 tint; // vertex colour and modulate only (COLOR in fragment already includes the texture)

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 uv = (UV - 0.5) / (1.0 - inset);
	float depth = 1.0 + strength * (tilt.x * uv.x + tilt.y * uv.y);
	vec2 src = uv / depth + 0.5;
	if (src.x < 0.0 || src.x > 1.0 || src.y < 0.0 || src.y > 1.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 c = texture(TEXTURE, src);
		float lane = (src.x - src.y) - (tilt.x - tilt.y) * 0.7;
		float band = 1.0 - smoothstep(0.0, 0.16, abs(lane));
		c.rgb += band * 0.16 * sheen * c.a;
		// Faces turned away from the light read slightly darker.
		c.rgb *= 1.0 - 0.06 * strength * (tilt.x * uv.x + tilt.y * uv.y);
		COLOR = c * tint;
	}
}

shader_type canvas_item;
render_mode unshaded, blend_mul;

// No screen texture or framebuffer copy: reduce mobile WebGL rendering work.
// Coordinates stay in the 1152x720 logical canvas, independent of phone DPR.
void fragment() {
 vec2 pixel = UV * vec2(1152.0, 720.0);
 float scan = 0.84 + 0.16 * pow(0.5 + 0.5 * cos(pixel.y * 3.14159265), 2.0);
 float column = mod(floor(pixel.x), 3.0);
 vec3 mask = column < 1.0 ? vec3(1.0, 0.94, 0.94) : (column < 2.0 ? vec3(0.94, 1.0, 0.94) : vec3(0.94, 0.94, 1.0));
 vec2 centered = UV * 2.0 - 1.0;
 float vignette = 1.0 - 0.24 * pow(clamp(dot(centered, centered) * 0.5, 0.0, 1.0), 1.4);
 COLOR = vec4(scan * mask * vignette, 1.0);
}

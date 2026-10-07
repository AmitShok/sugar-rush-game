shader_type canvas_item;
uniform float motion = 1.0;
void fragment() {
 vec2 uv = floor(UV * vec2(576.0,360.0)) / vec2(576.0,360.0);
 vec2 p = (uv-0.5)*vec2(1.6,1.0);
 float t = TIME * 0.045 * motion;
 float a = atan(p.y,p.x);
 float r = length(p);
 float flow = sin(a*2.0 + r*13.0 - t + sin(p.y*6.0+t)*1.6);
 float second = sin(p.x*9.0 + p.y*6.0 + flow*1.8 - t);
 float band = floor((flow+second)*1.8)/6.0;
 vec3 base = mix(vec3(0.055,0.18,0.16),vec3(0.13,0.32,0.27),clamp(band+0.5,0.0,1.0));
 float grain = fract(sin(dot(floor(UV*vec2(1152.0,720.0)),vec2(12.9898,78.233)))*43758.5453);
 base += (grain-0.5)*0.025;
 base *= 1.0 - 0.32*dot(p,p);
 COLOR = vec4(base,1.0);
}

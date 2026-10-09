shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
// Keep sampling geometry aligned with input; the CRT treatment does not warp hitboxes.
void fragment() {
 vec2 uv=SCREEN_UV;
 vec2 px=SCREEN_PIXEL_SIZE;
 vec3 original=texture(screen_texture,uv).rgb;
 vec3 color=vec3(texture(screen_texture,uv+vec2(px.x*0.65,0.0)).r,original.g,texture(screen_texture,uv-vec2(px.x*0.65,0.0)).b);
 vec3 glow=(texture(screen_texture,uv+vec2(px.x*2.0,0.0)).rgb+texture(screen_texture,uv-vec2(px.x*2.0,0.0)).rgb+texture(screen_texture,uv+vec2(0.0,px.y*2.0)).rgb+texture(screen_texture,uv-vec2(0.0,px.y*2.0)).rgb)*0.25;
 color+=max(glow-vec3(0.38),vec3(0.0))*0.25;
 float scan=0.76+0.24*pow(0.5+0.5*cos(uv.y/px.y*3.14159265),2.0);
 float column=mod(floor(uv.x/px.x),3.0);
 vec3 mask=column<1.0 ? vec3(1.0,0.88,0.88) : (column<2.0 ? vec3(0.88,1.0,0.88) : vec3(0.88,0.88,1.0));
 vec2 centered=uv*2.0-1.0;
 float vignette=1.0-0.32*pow(clamp(dot(centered,centered)*0.5,0.0,1.0),1.4);
 float grain=fract(sin(dot(floor(uv/px),vec2(12.9898,78.233)))*43758.5453)-0.5;
 color=pow(max(color,vec3(0.0)),vec3(0.94))*1.16*scan*mask*vignette+grain*0.018;
 COLOR=vec4(color,1.0);
}

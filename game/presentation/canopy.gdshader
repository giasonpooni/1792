// Copyright (c) 2026 Cartesian Graphics. All rights reserved.
// Presentation phase comes from the owning chapter's tick; no engine TIME or RNG.
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 cloth_color : source_color = vec4(0.72,0.59,0.39,1.0);
uniform vec4 stripe_color : source_color = vec4(0.36,0.36,0.29,1.0);
uniform float sampled_seconds=0.0;
uniform float breeze=0.035;
void vertex() {
 float pinned=sin(UV.x*PI)*sin(UV.y*PI);
 VERTEX.y+=breeze*pinned*sin(UV.x*12.0+sampled_seconds*1.5+UV.y*3.0);
}
void fragment() {
 float s=fract(UV.x*8.0);
 float edge=max(fwidth(UV.x*8.0),0.002);
 float stripe=smoothstep(0.12-edge,0.12+edge,s)*(1.0-smoothstep(0.26-edge,0.26+edge,s));
 vec3 c=mix(cloth_color.rgb,stripe_color.rgb,stripe*0.65);
 float fade=1.0-smoothstep(0.2,1.0,max(fwidth(UV.x*180.0),fwidth(UV.y*180.0)));
 c*=1.0+0.055*sin(UV.x*1131.0)*sin(UV.y*1131.0)*fade;
 ALBEDO=c; ROUGHNESS=0.96; SPECULAR=0.18;
}

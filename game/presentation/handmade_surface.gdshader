// Copyright (c) 2026 Cartesian Graphics. All rights reserved.
// Original analytic surface study, not a scanned or historically certified material.
shader_type spatial;
render_mode diffuse_burley;
uniform vec4 pigment : source_color = vec4(0.64, 0.51, 0.37, 1.0);
uniform int finish = 0; // 0 plaster, 1 brick, 2 timber, 3 earth, 4 woven cloth
uniform float surface_roughness : hint_range(0.1, 1.0) = 0.9;
varying vec3 world_at;
varying vec3 world_normal;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise21(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
 world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
 vec3 n=abs(world_normal);
 vec2 p=n.y>max(n.x,n.z)?world_at.xz:(n.x>n.z?world_at.zy:world_at.xy);
 if(finish==4) { p=UV*0.8; }
 float coarse=noise21(p*2.0), fine=noise21(p*63.0);
 vec3 color=pigment.rgb*(0.89+coarse*0.16+fine*0.015);
 float cavity=0.0;
 if(finish==0 || finish==1) {
  vec2 tile=p/vec2(0.29,0.085);
  tile.x+=mod(floor(tile.y),2.0)*0.5;
  vec2 f=fract(tile), aa=max(fwidth(tile)*0.7,vec2(0.003));
  float inside=smoothstep(0.03-aa.x,0.03+aa.x,f.x)*(1.0-smoothstep(0.97-aa.x,0.97+aa.x,f.x));
  inside*=smoothstep(0.075-aa.y,0.075+aa.y,f.y)*(1.0-smoothstep(0.925-aa.y,0.925+aa.y,f.y));
  vec3 brick=pigment.rgb*(0.68+0.30*hash21(floor(tile)));
  float exposed=finish==1?1.0:(1.0-smoothstep(0.24,0.53,coarse+min(max(world_at.y,0.0),2.0)*0.16));
  color=mix(color,mix(vec3(0.39,0.34,0.26),brick,inside),exposed);
  cavity=(1.0-inside)*exposed*0.19;
 } else if(finish==2) {
  float grain=noise21(p*vec2(45.0,1.8));
  color=pigment.rgb*(0.87+grain*0.14+coarse*0.025);
 } else if(finish==3) {
  color=pigment.rgb*(0.48+noise21(p*0.45)*0.17+fine*0.015);
 } else if(finish==4) {
  float width=max(fwidth(p.x*170.0),fwidth(p.y*170.0));
  float weave=sin(p.x*1068.0)*sin(p.y*1068.0)*(1.0-smoothstep(0.2,1.0,width));
  color*=1.0+weave*0.075;
 }
 ALBEDO=color;
 ROUGHNESS=surface_roughness;
 SPECULAR=0.24;
 AO=1.0-cavity;
}

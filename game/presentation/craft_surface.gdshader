// Copyright (c) 2026 Cartesian Graphics. All rights reserved.
// Appearance study: object-local metre scale; bump normals never displace geometry.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 pigment : source_color = vec4(0.6, 0.5, 0.4, 1.0);
uniform int finish = 0; // plaster, timber, earthenware, cloth
uniform bool horizontal_grain = false;
uniform sampler2D plaster_height : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D plaster_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 local_at;
varying vec3 local_normal;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() { local_at=VERTEX; local_normal=NORMAL; }
void fragment() {
 vec3 n=abs(local_normal);
 vec2 p=n.y>max(n.x,n.z)?local_at.xz:(n.x>n.z?local_at.zy:local_at.xy);
 float macro=noise2(p*2.3), height=0.0, roughness=0.94;
 vec3 color=pigment.rgb;
 if(finish==0) {
  // Generic CC0 plaster microrelief, tinted with the authored palette.
  float relief=texture(plaster_height,p*0.5).r;
  color*=0.95+0.07*macro+0.025*(relief-0.5);
  height=0.0012*(relief-0.5);
  roughness=clamp(texture(plaster_roughness,p*0.5).r,0.83,1.0);
 } else if(finish==1) {
  vec2 grain_at=horizontal_grain?p.yx:p;
  float grain=noise2(grain_at*vec2(75.0,1.8)+vec2(sin(grain_at.y*4.1)*0.7,0.0));
  color*=0.91+0.13*grain+0.025*macro;
  height=0.00065*(grain-0.5);
  roughness=0.84+0.1*grain;
 } else if(finish==2) {
  float pore=noise2(UV*vec2(170.0,100.0));
  float band=sin(local_at.y*360.0+noise2(UV*8.0)*0.6);
  float filter_width=fwidth(local_at.y*360.0);
  band*=1.0-smoothstep(0.6,2.0,filter_width);
  color*=0.94+0.055*macro+0.016*band+0.022*(pore-0.5);
  height=0.00018*band+0.00016*(pore-0.5);
  roughness=0.88+0.1*pore;
 } else {
  // Derivative filtering suppresses distant weave shimmer. Coordinates move with cloth.
  vec2 thread=p*950.0;
  float filter_width=max(fwidth(thread.x),fwidth(thread.y));
  float weave=sin(thread.x)*sin(thread.y)*(1.0-smoothstep(0.6,2.0,filter_width));
  color*=0.96+0.055*macro+0.025*weave;
  height=0.00006*weave;
  roughness=0.98;
 }
 vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);
 vec3 r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
 float det=dot(dx,r1);
 if(abs(det)>0.000001) NORMAL=normalize(NORMAL-(dFdx(height)*r1+dFdy(height)*r2)/det);
 ALBEDO=clamp(color,vec3(0.015),vec3(0.85));
 ROUGHNESS=roughness;
 SPECULAR=finish==2?0.18:0.16;
}

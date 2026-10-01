// Copyright (c) 2026 Cartesian Graphics. All rights reserved.
// Metre-scaled appearance only. Height affects normals, never the physical terrain.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(.68,.62,.50,1.0);
uniform int material_kind = 0;
uniform bool use_scanned = false;
uniform sampler2D surface_diffuse : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_height : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D surface_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 wp;
varying vec3 wn;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec2 p=abs(wn.y)>.65?wp.xz:(abs(wn.z)>abs(wn.x)?wp.xy:wp.zy);
 float macro=noise2(p*1.7);float h=0.0;vec3 c=base_color.rgb;float rough=.94;
 if(use_scanned){
  // Two-metre source sample; not geospatial placement or historical material admission.
  vec2 tiled=p*.5;vec3 scanned=texture(surface_diffuse,tiled).rgb;
  float relief=texture(surface_height,tiled).r;
  if(material_kind==3){c=scanned*(.92+.10*macro);h=.003*(relief-.5);}
  else{c*=mix(vec3(.75),scanned*2.1,.68);h=.0015*(relief-.5);}
  rough=clamp(texture(surface_roughness,tiled).r,.78,1.0);
 }else if(material_kind==2){
  float grain=noise2(vec2(p.x*32.0,p.y*.7)+vec2(sin(p.y*1.3)*.8,0));
  c*=.76+.28*grain+.06*macro;h=.0007*grain;rough=.86;
 }else if(material_kind==1){
  vec2 b=p/vec2(.34,.115);b.x+=mod(floor(b.y),2.0)*.5;vec2 f=fract(b);
  float mortar=max(1.0-smoothstep(.035,.09,min(f.x,1.0-f.x)),1.0-smoothstep(.055,.13,min(f.y,1.0-f.y)));
  c*=.82+.22*hash21(floor(b));c=mix(c,vec3(.28,.245,.20),mortar);h=-.001*mortar;
 }else if(material_kind==4){
  // Imported garment UVs keep weave attached to cloth rather than crawling in world space.
  float filter_width=max(fwidth(UV.x),fwidth(UV.y));
  float weave=sin(UV.x*4000.0)*sin(UV.y*4000.0)*(1.0-smoothstep(.0005,.002,filter_width));
  c*=.98+.018*weave;h=.00004*weave;rough=.98;
 }else{c*=.90+.13*macro;}
 vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);vec3 r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);float det=dot(dx,r1);
 if(abs(det)>.000001){NORMAL=normalize(NORMAL-(dFdx(h)*r1+dFdy(h)*r2)/det);}
 ALBEDO=clamp(c,vec3(.015),vec3(.85));ROUGHNESS=rough;SPECULAR=material_kind==3?.04:.16;
}

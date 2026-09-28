shader_type spatial;
// Copyright (c) 2026 Cartesian Graphics. All rights reserved.
// Original analytic material. All dimensions/colors are authored, not measured fabric.
uniform vec4 brick_color : source_color = vec4(0.52,0.25,0.15,1.0);
uniform vec4 plaster_color : source_color = vec4(0.78,0.65,0.47,1.0);
uniform float plaster_cover : hint_range(0.0,1.0) = 0.7;
varying vec3 world_position;
varying vec3 world_normal;
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    vec2 p = abs(world_normal.z)>abs(world_normal.x) ? world_position.xy : world_position.zy;
    float row = floor(p.y / 0.12);
    vec2 brick_uv = vec2(p.x / 0.32 + mod(row,2.0)*0.5,p.y/0.12);
    vec2 edge = min(fract(brick_uv),1.0-fract(brick_uv));
    vec2 aa = max(fwidth(brick_uv),vec2(0.005));
    float face = smoothstep(0.02-aa.x,0.02+aa.x,edge.x)*smoothstep(0.03-aa.y,0.03+aa.y,edge.y);
    float variation = 0.86+0.20*grain(floor(brick_uv));
    vec3 brick = mix(plaster_color.rgb*0.72,brick_color.rgb*variation,face);
    // A maintained plaster field with an uneven exposed brick footing.
    // No periodic circular 'damage spots' and no use of contemporary ruin photographs.
    float footing = 0.24+0.045*sin(p.x*2.0)+0.025*sin(p.x*5.7);
    float plaster = smoothstep(footing-0.035,footing+0.035,world_position.y);
    plaster *= smoothstep(0.18,0.70,plaster_cover);
    ALBEDO = mix(brick,plaster_color.rgb*(0.96+0.04*sin(p.x*3.0)*sin(p.y*5.0)),plaster);
    ROUGHNESS = 0.95;
}

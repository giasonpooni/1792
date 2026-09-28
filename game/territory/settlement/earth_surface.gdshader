shader_type spatial;
render_mode cull_back;
uniform vec4 earth_color : source_color = vec4(0.64, 0.45, 0.29, 1.0);
uniform float grain_strength : hint_range(0.0, 0.3) = 0.09;
uniform float course_strength : hint_range(0.0, 0.2) = 0.035;
varying vec3 local_point;
float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float smooth_grain(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash31(i), hash31(i + vec3(1.0, 0.0, 0.0)), f.x);
	float b = mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x);
	float c = mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x);
	float d = mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}
void vertex() {
	local_point = VERTEX;
}
void fragment() {
	float grain = smooth_grain(local_point * 7.0) - 0.5;
	float courses = 1.0 - smoothstep(0.01, 0.06, abs(fract(local_point.y * 4.0) - 0.5));
	ALBEDO = earth_color.rgb * (1.0 + grain_strength * grain - course_strength * courses);
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}

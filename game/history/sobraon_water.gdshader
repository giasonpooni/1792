shader_type spatial;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float a = sin(world_position.x * 1.9 + world_position.z * 5.1 + TIME * 1.6);
	float b = sin(world_position.x * 5.3 - world_position.z * 1.1 - TIME * 1.1);
	ALBEDO = mix(vec3(0.14, 0.23, 0.25), vec3(0.31, 0.42, 0.42), 0.48 + a * 0.10 + b * 0.06);
	NORMAL = normalize((VIEW_MATRIX * vec4(a * 0.04, 1.0, b * 0.05, 0.0)).xyz);
	ROUGHNESS = 0.36;
	SPECULAR = 0.48;
}

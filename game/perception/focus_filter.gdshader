shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
void fragment() {
	vec3 source = texture(screen_texture, SCREEN_UV).rgb;
	float grey = dot(source, vec3(0.2126, 0.7152, 0.0722));
	COLOR = vec4(mix(source, vec3(grey), 0.78), 1.0);
}

shader_type canvas_item;
render_mode unshaded;
// Stylized subjective framing. The healthy eye and the centre are not blacked out.
// This layer precedes the HUD, so dialogue and controls remain readable.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float loss : hint_range(0.0,1.0) = 0.2;
uniform bool affected_left = true;
void fragment() {
    vec2 uv = SCREEN_UV;
    float side = affected_left ? 1.0-UV.x : UV.x;
    float edge = smoothstep(0.58,1.0,side);
    float weight = clamp(loss,0.0,1.0)*edge;
    vec2 dx = vec2(4.0*weight,0.0)*SCREEN_PIXEL_SIZE;
    vec2 dy = vec2(0.0,3.0*weight)*SCREEN_PIXEL_SIZE;
    vec3 original = texture(screen_texture,uv).rgb;
    vec3 blurred = (original*2.0 + texture(screen_texture,uv+dx).rgb + texture(screen_texture,uv-dx).rgb + texture(screen_texture,uv+dy).rgb + texture(screen_texture,uv-dy).rgb)/6.0;
    COLOR = vec4(mix(original,blurred,weight)*(1.0-0.45*weight),1.0);
}

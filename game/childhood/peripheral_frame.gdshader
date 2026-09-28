shader_type canvas_item;
// Authored third-person peripheral framing, NOT an ophthalmological simulation.
// HUD/captions are on a higher CanvasLayer and never obscured. Setting zero disables it.
uniform float strength : hint_range(0.0, 0.4) = 0.24;
void fragment() {
	float left_edge = 1.0 - smoothstep(0.0, 0.20, UV.x);
	COLOR = vec4(0.10, 0.13, 0.12, strength * left_edge);
}

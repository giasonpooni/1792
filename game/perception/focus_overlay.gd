# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Control
## Screen presentation of recorded evidence, with explicit stale/estimated labels.
var marks: Array=[]

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for m in marks:
		var at: Vector2=m.at
		var color: Color=m.color
		var alpha: float=m.alpha
		color.a=alpha
		var label: String=m.text
		var width := minf(310.0,font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+20)
		var origin:=at+Vector2(10,-22)
		origin.x=clampf(origin.x,12,maxf(12,size.x-width-12))
		origin.y=clampf(origin.y,12,maxf(12,size.y-41))
		var rect := Rect2(origin,Vector2(width,29))
		draw_style_box(_style(alpha),rect)
		draw_circle(at,7,color,false,2.0)
		draw_string(font,rect.position+Vector2(9,19),label,HORIZONTAL_ALIGNMENT_LEFT,width-18,14,color)
		if m.has("prediction"):
			var end: Vector2=m.prediction
			var start: Vector2=m.prediction_origin
			var length := start.distance_to(end)
			var direction := start.direction_to(end)
			for distance in range(0,int(minf(length,500)),12):
				draw_line(start+direction*distance,start+direction*minf(distance+6,length),color,2.0)
			draw_string(font,end+Vector2(8,0),"estimated",HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

func _style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.06,0.075,0.06,0.86*alpha)
	style.set_corner_radius_all(3)
	return style

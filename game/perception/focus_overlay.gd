# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Control
## Screen presentation of recorded evidence, with explicit stale/estimated labels.
var marks: Array=[]
var exclusion_rects: Array[Rect2]=[]

func _label_rect(at: Vector2, dimensions: Vector2, occupied: Array[Rect2]) -> Rect2:
	for offset in [Vector2(10,-22),Vector2(-dimensions.x-10,-22),Vector2(10,12),Vector2(-dimensions.x-10,12)]:
		var origin: Vector2=at+offset
		origin.x=clampf(origin.x,12,maxf(12,size.x-dimensions.x-12))
		origin.y=clampf(origin.y,12,maxf(12,size.y-dimensions.y-12))
		var candidate:=Rect2(origin,dimensions)
		var clear:=true
		for rect in occupied:
			if candidate.intersects(rect): clear=false;break
		if clear: return candidate
	return Rect2()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2]=exclusion_rects.duplicate()
	for m in marks:
		var at: Vector2=m.at
		var color: Color=m.color
		var alpha: float=m.alpha
		color.a=alpha
		var label: String=m.text
		var width := minf(310.0,font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+20)
		var rect:=_label_rect(at,Vector2(width,29),occupied)
		if rect.has_area():
			draw_style_box(_style(alpha),rect)
			draw_string(font,rect.position+Vector2(9,19),label,HORIZONTAL_ALIGNMENT_LEFT,width-18,14,color)
			occupied.append(rect.grow(3))
		if m.has("progress"):
			var background:=color;background.a*=0.35
			draw_circle(at,10,background,false,1.5)
			draw_arc(at,10,-PI*0.5,-PI*0.5+TAU*clampf(float(m.progress),0,1),32,color,2.5,true)
		else: draw_circle(at,7,color,false,2.0)
		if m.has("prediction"):
			var end: Vector2=m.prediction
			var start: Vector2=m.prediction_origin
			var length := start.distance_to(end)
			var direction := start.direction_to(end)
			for distance in range(0,int(minf(length,500)),12):
				var from:=start+direction*distance
				var to:=start+direction*minf(distance+6,length)
				var bounds:=Rect2(from,Vector2.ZERO).expand(to).grow(2)
				var clear:=true
				for reserved in occupied:
					if bounds.intersects(reserved): clear=false;break
				if clear: draw_line(from,to,color,2.0)
			var estimate_rect:=_label_rect(end,Vector2(84,22),occupied)
			if estimate_rect.has_area():
				draw_string(font,estimate_rect.position+Vector2(6,16),"estimated",HORIZONTAL_ALIGNMENT_LEFT,72,12,color)
				occupied.append(estimate_rect.grow(3))

func _style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.06,0.075,0.06,0.86*alpha)
	style.set_corner_radius_all(3)
	return style

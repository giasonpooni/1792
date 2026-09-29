# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Control
## Diagram of acquisition coverage. This is NOT rendered or compressed game terrain.
signal selected(id: String)
var catalogue: Dictionary = {}
var selected_id := "gujranwala"

func plot_rect() -> Rect2:
	return Rect2(Vector2(34,24),Vector2(maxf(1,size.x-48),maxf(1,size.y-46)))
func project(point: Array) -> Vector2:
	var b: Array = catalogue.bounds
	var r := plot_rect()
	return r.position+Vector2((point[0]-b[0])/(b[2]-b[0]),1.0-(point[1]-b[1])/(b[3]-b[1]))*r.size
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("111c27"))
	if catalogue.is_empty(): return
	var b: Array = catalogue.bounds
	var font := ThemeDB.fallback_font
	for lon in range(int(b[0]),int(b[2])):
		for lat in range(int(b[1]),int(b[3])):
			var top:=project([lon,lat+1]);var bottom:=project([lon+1,lat])
			var color:=Color("1b2c39") if (lon+lat)%2==0 else Color("203440")
			draw_rect(Rect2(top,bottom-top),color)
	for lon in range(int(b[0]),int(b[2])+1,2):
		var top:=project([lon,b[3]]);var bottom:=project([lon,b[1]])
		draw_line(top,bottom,Color("48606c"),1)
		draw_string(font,bottom+Vector2(-10,17),str(lon)+"E",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b6c4c4"))
	for lat in range(int(b[1]),int(b[3])+1,2):
		var left:=project([b[0],lat]);var right:=project([b[2],lat])
		draw_line(left,right,Color("48606c"),1)
		draw_string(font,left+Vector2(-29,4),str(lat)+"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b6c4c4"))
	for item in catalogue.theatres:
		var box: Array = item.bounds
		draw_rect(Rect2(project([box[0],box[3]]),project([box[2],box[1]])-project([box[0],box[3]])),Color(0.45,0.64,0.72,0.4),false,1)
	for place in catalogue.places:
		if place.anchor==null: continue
		var at:=project(place.anchor)
		var color:=Color("82d6ae") if place.placement_class=="A" else Color("dec586")
		draw_circle(at,4 if place.id==selected_id else 2.5,color)
		if place.id==selected_id:
			draw_arc(at,7,0,TAU,24,Color.WHITE,1)
			draw_string(font,Vector2(clampf(at.x+11,38,maxf(38,size.x-170)),clampf(at.y-8,18,size.y-24)),place.label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
	draw_string(font,Vector2(38,17),"ACQUISITION GRID | no terrain loaded",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e5c480"))
func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
	var closest: String="";var distance:=14.0
	for place in catalogue.get("places",[]):
		if place.anchor==null: continue
		var gap: float=project(place.anchor).distance_to(event.position)
		if gap<distance: distance=gap;closest=place.id
	if not closest.is_empty(): selected.emit(closest);accept_event()
func _notification(what: int) -> void:
	if what==NOTIFICATION_RESIZED: queue_redraw()

# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Presentation/save envelope. The existing WorkshopState remains the world authority.
const Authority := preload("res://workshops/workshop_state.gd")
const SCHEMA := "1792.gujranwala-continuation.v0.1"
const PATH := "user://1792-gujranwala-slice-v01.continue.json"
const LIMIT := 262144

static func new_run_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

static func valid_run_id(value: Variant) -> bool:
	if not value is String or value.length()!=32: return false
	for character in value:
		if character not in "0123456789abcdef": return false
	return true

static func manual_path(run_id: String) -> String:
	return "user://1792-gujranwala-slice-"+run_id+".manual.json" if valid_run_id(run_id) else ""

static func validate(value: Variant) -> String:
	if not value is Dictionary or value.size()!=4 or value.get("schema")!=SCHEMA:
		return "Malformed Gujranwala continuation."
	if not valid_run_id(value.get("run_id")): return "Invalid continuation run identity."
	var camera: Variant=value.get("camera")
	if not camera is Array or camera.size()!=2: return "Invalid continuation camera."
	for number in camera:
		if not Authority.Riding.finite_number(number): return "Nonfinite continuation camera."
	if camera[0]<-0.9 or camera[0]>0.5 or absf(camera[1])>PI+1e-6:
		return "Continuation camera outside limits."
	var staged:=Authority.new()
	return staged.restore(value.get("snapshot"))

static func write(path: String,run_id: String,snapshot: Dictionary,view: Vector3) -> String:
	var value:={"schema":SCHEMA,"run_id":run_id,"snapshot":snapshot.duplicate(true),
		"camera":[clampf(view.x,-0.9,0.5),wrapf(view.y,-PI,PI)]}
	var error:=validate(value)
	if not error.is_empty(): return error
	var text:=JSON.stringify(value,"",true,true)
	if text.to_utf8_buffer().size()>LIMIT: return "Continuation exceeds size budget."
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return "Cannot create continuation temporary file."
	file.store_string(text);file.flush()
	var status:=file.get_error();file.close()
	if status!=OK: return "Continuation write failed."
	status=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
	return "" if status==OK else "Continuation replacement failed."

static func read(path: String=PATH) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"error":"No Gujranwala continuation found."}
	if file.get_length()>LIMIT:
		file.close();return {"error":"Continuation exceeds size budget."}
	var text:=file.get_as_text();file.close()
	var parser:=JSON.new()
	if parser.parse(text)!=OK: return {"error":"Malformed continuation JSON."}
	var error:=validate(parser.data)
	return {"error":error} if not error.is_empty() else {"error":"","envelope":parser.data}

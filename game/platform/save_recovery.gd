# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Local manual-save policy. No world owner, new clock, index file, or automatic rollback.
## Byte I/O is injected; the caller's existing validator owns the snapshot schema.
const POLICY_ID := "cg.manual-save-recovery.v1"
const PREVIOUS_SUFFIX := ".previous"

static func digest(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

static func world_digest(model: RefCounted) -> String:
	return digest(JSON.stringify(model.snapshot(),"",true,true).to_utf8_buffer())

static func _valid_path(path: String) -> bool:
	# One OS-local save, no arbitrary path or remote account selected by content.
	if not path.begins_with("user://") or path.length()>160: return false
	var leaf:=path.trim_prefix("user://")
	if leaf.is_empty() or leaf.begins_with("."): return false
	for character in leaf:
		if character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.": return false
	return leaf.ends_with(".json") or leaf.ends_with(".json"+PREVIOUS_SUFFIX)

static func _read(model: RefCounted, path: String) -> Dictionary:
	var result: Dictionary={"path":path,"status":"unavailable","error":"Invalid local save path.","digest":""}
	if not _valid_path(path): return result
	var storage: RefCounted=model.platform_services.storage
	if not storage.has_method("path_status"):
		result.error="This transport does not implement local save inspection. No fallback was selected."
		return result
	var presence: String=storage.path_status(path)
	if presence=="missing":
		result.status="missing";result.error="No save in this slot."
		return result
	if presence!="file":
		result.error="Save path is not an accessible regular file."
		return result
	var read: Dictionary=storage.read_bytes(path,model.LIMIT)
	if not read.error.is_empty():
		result.error=read.error
		return result
	var bytes: PackedByteArray=read.bytes
	result.digest=digest(bytes)
	result.bytes=bytes
	result.status="invalid"
	var text:=bytes.get_string_from_utf8()
	if text.to_utf8_buffer()!=bytes:
		result.error="Save is not valid UTF-8."
		return result
	var parser:=JSON.new()
	if parser.parse(text)!=OK:
		result.error="Saved chapter JSON is malformed."
		return result
	var error: String=model.validate(parser.data)
	if not error.is_empty():
		result.error=error
		return result
	result.status="valid";result.error="";result.snapshot=parser.data
	return result

static func inspect(model: RefCounted, path: String) -> Dictionary:
	var raw:=_read(model,path)
	var view: Dictionary={"path":path,"status":raw.status,"error":raw.error,"digest":raw.digest}
	if raw.status=="valid":
		# Summary is save metadata, never injected into the protagonist's knowledge.
		var summary: RefCounted=model.get_script().new()
		summary.restore(raw.snapshot)
		view.stage=summary.stage()
		view.tick=int(raw.snapshot.childhood.tick)
	return view

static func read_selected(model: RefCounted, path: String, expected_digest: String) -> Dictionary:
	var raw:=_read(model,path)
	if raw.status!="valid": return {"error":raw.error}
	if expected_digest.is_empty() or raw.digest!=expected_digest:
		return {"error":"The selected save changed. Review it again; nothing was loaded."}
	return {"error":"","snapshot":raw.snapshot.duplicate(true)}

static func save(model: RefCounted, path: String, replacement: Dictionary={}) -> String:
	if not _valid_path(path) or not path.ends_with(".json"): return "Invalid primary save path."
	var state: Dictionary=model.snapshot()
	var error: String=model.validate(state)
	if not error.is_empty(): return error
	var bytes:=JSON.stringify(state,"",true,true).to_utf8_buffer()
	if bytes.size()>model.LIMIT: return "Saved chapter exceeds its existing size limit."
	var prior:=_read(model,path)
	if prior.status=="unavailable": return prior.error
	if not replacement.is_empty():
		if replacement.size()!=2 or replacement.get("primary_digest")!=prior.digest or replacement.get("world_digest")!=digest(bytes) or prior.status!="invalid":
			return "The save or current chapter changed. Review replacement again; no file was written."
	elif prior.status=="invalid":
		return "Primary save is invalid. Open Saved chapter / recovery to recover or explicitly replace it."
	var storage: RefCounted=model.platform_services.storage
	if prior.status=="valid" and prior.bytes!=bytes:
		# Complete a backup copy BEFORE replacing primary. Failure never deletes primary.
		error=storage.write_bytes(path+PREVIOUS_SUFFIX,prior.bytes,model.LIMIT)
		if not error.is_empty(): return "Previous-save preservation failed; primary unchanged. "+error
	# Missing/invalid primary never overwrites the previous slot. Duplicate saves retain it too.
	return storage.write_bytes(path,bytes,model.LIMIT)

static func description(view: Dictionary, label: String) -> String:
	if view.status=="valid":
		return "%s · %s · %.1f seconds of active chapter time\nData checks passed; standing-room checks run before entry."%[label,str(view.stage).capitalize(),view.tick/60.0]
	return "%s · %s\n%s"%[label,str(view.status).capitalize(),str(view.error)]

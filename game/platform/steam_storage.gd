# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## App/user-scoped LOCAL files. No Steam Cloud API and no automatic old-save import.
const Storage := preload("res://platform/local_storage.gd")
var _owner: WeakRef
var _root := ""
var _io: RefCounted=Storage.new()

func configure(owner: RefCounted, app_id: int, user_id: int) -> void:
	_owner=weakref(owner)
	_root="user://store-users/steam/%d/%d/"%[app_id,user_id]

func _resolve(path: String) -> Dictionary:
	var session: Variant=_owner.get_ref() if _owner!=null else null
	if session==null or not session.check_session(): return {"error":"Steam session no longer matches this local save scope; restart deliberately."}
	if not path.begins_with("user://"): return {"error":"Store saves require a user-local filename."}
	var leaf:=path.trim_prefix("user://")
	if leaf.is_empty() or leaf.length()>120 or leaf.contains("..") or leaf.begins_with(".") or leaf.ends_with("."):
		return {"error":"Invalid store-local save name."}
	for character in leaf:
		if not (character in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"):
			return {"error":"Nested or noncanonical store-local save name refused."}
	return {"error":"","path":_root+leaf}

func write_bytes(path: String, bytes: PackedByteArray, limit: int) -> String:
	var result:=_resolve(path)
	if not result.error.is_empty(): return result.error
	if bytes.is_empty() or limit<=0 or bytes.size()>limit: return "Store-local byte budget exceeded."
	if DirAccess.make_dir_recursive_absolute(_root)!=OK: return "Cannot prepare this store user's local save directory."
	return _io.write_bytes(result.path,bytes,limit)

func read_bytes(path: String, limit: int) -> Dictionary:
	var result:=_resolve(path)
	if not result.error.is_empty(): return result
	return _io.read_bytes(result.path,limit)

func path_status(path: String) -> String:
	var result:=_resolve(path)
	if not result.error.is_empty(): return "unavailable"
	if not DirAccess.dir_exists_absolute(_root): return "missing"
	return _io.path_status(result.path)

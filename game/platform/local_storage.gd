# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Byte transport only. The caller owns schema validation and world-state promotion.
const CONTRACT_ID := "cg.save-transport.v1"
const IMPLEMENTATION_ID := "cg.local-files.v1"

func write_bytes(path: String, bytes: PackedByteArray, limit: int) -> String:
	if path.is_empty() or limit<=0 or bytes.size()>limit: return "Save exceeds its transport budget or has no path."
	var temporary:=path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return "Cannot open temporary save."
	file.store_buffer(bytes)
	file.flush()
	var status:=file.get_error()
	file.close()
	if status!=OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return "Save write failed."
	status=DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))
	if status!=OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return "Save replacement failed; previous destination was not removed."
	return ""

func read_bytes(path: String, limit: int) -> Dictionary:
	if path.is_empty() or limit<=0: return {"error":"Invalid save transport request."}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"error":"No save found."}
	var length:=file.get_length()
	if length>limit:
		file.close()
		return {"error":"Save too large."}
	var bytes:=file.get_buffer(length)
	var status:=file.get_error()
	file.close()
	if bytes.size()!=length or status not in [OK,ERR_FILE_EOF]: return {"error":"Save read failed."}
	return {"error":"","bytes":bytes}

func path_status(path: String) -> String:
	# Optional local inspection seam; does not expand the cg.save-transport.v1 contract.
	var dir:=DirAccess.open(path.get_base_dir())
	if dir==null: return "unavailable"
	var leaf:=path.get_file()
	if dir.is_link(leaf) or dir.dir_exists(leaf): return "unavailable"
	return "file" if dir.file_exists(leaf) else "missing"

# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Explicit build-time new-process probe. Does not claim physical hardware or native Steam use.
static func run(menu: Control) -> void:
	var errors: Array=[]
	var host=menu.platform_runtime
	if host==null or host.recorder==null:
		print("INTEGRATION_BOOT_RECORD: "+JSON.stringify({"errors":["Missing explicit hardware-session probe host"]}))
		menu.get_tree().quit(1);return
	var h: Node=host.recorder
	menu._open_hardware()
	for _i in range(3): await menu.get_tree().process_frame
	var report: Dictionary=h.report()
	if report.evidence_kind!="automated_observation" or report.certified or report.operator_results.controller!="not_tested":
		errors.append("Headless run misclassified as human hardware evidence")
	if not h.write_report().begins_with("Saved locally"): errors.append("Diagnostic export failed")
	var path: String=h._folder+"report.json"
	var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not saved is Dictionary or saved.get("certified")!=false: errors.append("Diagnostic persistence mismatch")
	if Engine.has_singleton("Steam"): errors.append("Local-PC export unexpectedly contains an unqualified Steam native singleton")
	var record: Dictionary={"schema":"cg.integration-boot.v1","os":OS.get_name(),"exported":not OS.has_feature("editor"),
		"source_commit":report.source.get("source_commit",""),"source_tree":report.source.get("source_tree",""),
		"build_execution_id":report.source.get("execution_id",""),"verification_id":"platform.integration-export-boot.v1",
		"diagnostic_report_written":errors.is_empty(),"native_steam_tested":false,"physical_hardware_qualified":false,"errors":errors}
	DirAccess.remove_absolute(path)
	print("INTEGRATION_BOOT_RECORD: "+JSON.stringify(record))
	print("INTEGRATION_BOOT_SMOKE: "+("pass" if errors.is_empty() else "fail"))
	menu.get_tree().quit(0 if errors.is_empty() else 1)

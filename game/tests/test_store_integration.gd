# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_platform.gd"
## Fake client and synthetic input: native-client/hardware qualification explicitly NOT claimed.
const Steam := preload("res://platform/steam_services.gd")
const Runtime := preload("res://platform/platform_runtime.gd")
const Hardware := preload("res://platform/hardware_session.gd")
const Shell := preload("res://platform/controller_shell.gd")

class FakeClient extends RefCounted:
	signal overlay_toggled(active: bool, user_initiated: bool, app_id: int)
	var app: Variant=1234567
	var user: Variant=76561198000000001
	var running: Variant=true
	var subscribed: Variant=true
	var online: Variant=false
	var result: Variant={"status":0,"verbal":"synthetic result"}
	var init_args: Array=[]
	var callbacks:=0
	var shutdowns:=0
	func steamInitEx(app_id: int, embedded: bool) -> Variant:
		init_args=[app_id,embedded];return result
	func steamShutdown() -> void: shutdowns+=1
	func run_callbacks() -> void: callbacks+=1
	func isSteamRunning() -> Variant: return running
	func getAppID() -> Variant: return app
	func getSteamID() -> Variant: return user
	func isSubscribed() -> Variant: return subscribed
	func loggedOn() -> Variant: return online

func _steam_domain() -> void:
	for value in [null,true,0,-1,480,4294967296,1.5,"1234567"]:
		var service:=Steam.new()
		check(not service.initialize(value,FakeClient.new()).is_empty(),"invalid app identity refused "+str(value))
		check(not service.ready and service.identity().platform_user_id==null,"no identity manufactured on refusal")
	var absent:=Steam.new()
	check(not absent.initialize(1234567).is_empty(),"standard Godot actually refuses missing native singleton")
	check(not Steam.api_error(RefCounted.new()).is_empty(),"method-shape mismatch refused")
	for result in [null,{"status":true},{"status":0.0},{"status":1},{}]:
		var bad:=FakeClient.new();bad.result=result
		var service:=Steam.new()
		check(not service.initialize(1234567,bad).is_empty(),"malformed/failed init does not create session")
		service.shutdown();check(bad.shutdowns==0,"no SDK shutdown without acquired session")
	var client:=FakeClient.new()
	var service:=Steam.new()
	ok(service.initialize(1234567,client),"synthetic contract accepted")
	check(client.init_args==[1234567,false],"verified app-id-first signature; only host owns callbacks")
	check(service.ready and not client.online,"offline client not wrongly refused as online-only DRM")
	check(not service.diagnostic_status().native_client_observed and service.diagnostic_status().dependency_evidence=="injected_test_double","fake bridge cannot label itself native-client evidence")
	check(service.entitlement().status=="client_reported_subscribed" and not service.entitlement().server_authenticated,"client report is not signed ownership proof")
	check(not service.capabilities().cloud_save and not service.capabilities().achievements,"no invented services")
	var actor:=State.new();var before:=actor.snapshot();actor.platform_services=service
	check(actor.snapshot()==before and not JSON.stringify(before).contains(str(client.user)),"account does not enter character state")
	var slot: String="user://store-integration-test-only.json"
	ok(actor.save_to(slot),"actual app/user local write through inherited validator")
	var path: String=service.storage._resolve(slot).path
	check(path.begins_with("user://store-users/steam/1234567/76561198000000001/"),"account directory selected by client not save bytes")
	check(not FileAccess.file_exists(slot),"no write to legacy global slot")
	var second:=State.new();second.platform_services=service
	ok(second.load_from(slot),"scoped bytes load through original state authority")
	check(Equality._equal(second.snapshot(),before),"scoped transport preserves serialized world")
	for wrong in ["", "res://project.godot", "user://../other.json", "user://nested/x.json", "user://.hidden", "user://bad:stream"]:
		check(not service.storage.write_bytes(wrong,"x".to_utf8_buffer(),100).is_empty(),"scoped name refuses "+wrong)
	var shell:=Shell.new();root.add_child(shell)
	service.gate_changed.connect(shell.set_platform_gate)
	client.overlay_toggled.emit(true,true,1234567)
	check(not shell.focused and service.overlay_open,"overlay blocks input")
	shell.set_focus(false);client.overlay_toggled.emit(false,false,1234567)
	check(not shell.focused,"closing overlay cannot override OS focus loss")
	shell.set_focus(true);check(shell.focused,"separate gates both clear")
	client.overlay_toggled.emit(true,false,777)
	check(service.ready and not shell.focused,"overlay navigation metadata never substitutes app identity")
	client.overlay_toggled.emit(false,false,777)
	service.pump();check(client.callbacks==1,"one explicit callback pump")
	var stored:=FileAccess.get_file_as_bytes(path)
	client.user+=1
	check(not service.check_session() and not shell.focused,"account change invalidates old session and pauses")
	check(not actor.save_to(slot).is_empty() and FileAccess.get_file_as_bytes(path)==stored,"account change refuses old-scope write")
	check(service.identity().platform_user_id==null,"invalid session no longer reports a current user")
	client.user-=1
	check(not service.check_session(),"returning account never silently revives invalid session")
	service.shutdown();service.shutdown();check(client.shutdowns==1,"idempotent one-owner shutdown")
	shell.queue_free();DirAccess.remove_absolute(path)
	for alteration in ["app","running","subscribed","user"]:
		var fake:=FakeClient.new();var s:=Steam.new()
		ok(s.initialize(1234567,fake),"new labelled session fixture")
		match alteration:
			"app": fake.app=1
			"running": fake.running=false
			"subscribed": fake.subscribed=false
			"user": fake.user=0
		check(not s.check_session(),"session guard refuses changed "+alteration)
		s.shutdown()

func _hardware_domain() -> void:
	var h:=Hardware.new();h.automated=true;root.add_child(h)
	check(not h.record_operator("controller","pass").is_empty(),"automation cannot author a human pass")
	var r:=h.report()
	check(r.evidence_kind=="automated_observation" and not r.certified and not r.human_accessibility_study,"headless observation never claims hardware certification")
	check(r.operator_results.controller=="not_tested","all human checks start unknown")
	check(not JSON.stringify(r).contains("76561198000000001"),"no platform-user ID in exported diagnostic record")
	r.operator_results.controller="pass"
	check(h.report().operator_results.controller=="not_tested","report snapshots detached")
	h.transport=RefusingTransport.new()
	check(h.write_report().begins_with("Report not saved"),"diagnostic write failure reported")
	h.transport=Storage.new()
	check(h.write_report().begins_with("Saved locally"),"bounded local report actually written")
	var path: String=h._folder+"report.json"
	var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(saved.schema=="cg.hardware-session.v1" and saved.certified==false,"retained report refuses false certification")
	DirAccess.remove_absolute(path)
	h.queue_free()

func _integration() -> void:
	var host:=Runtime.new();host.name="PlatformRuntime";root.add_child(host)
	host.configure(PackedStringArray(["--hardware-session"]),null,true)
	var title=load("res://ui/main_menu.tscn").instantiate()
	title.home_save_path="user://store-journey-test-only.json"
	root.add_child(title);current_scene=title;await frames(4)
	await choose("Local hardware test session")
	check(title._hardware_box.visible,"opt-in recorder reachable by actual title controller focus")
	await choose("Export local report")
	check(title._hardware_box.get_child(0).text.contains("Saved locally"),"title actually exports report")
	await tap(JOY_BUTTON_B)
	await choose("1792 ·")
	var scene=current_scene.get_node("ChildhoodChapter")
	scene.save_path="user://store-journey-test-only.json"
	await tap(JOY_BUTTON_START);await choose("Local hardware test session")
	var paused: Dictionary=scene.model.snapshot()
	await frames(10)
	check(scene.model.snapshot()==paused,"diagnostics menu freezes existing world rather than extra authority")
	await choose("Review: controller");await choose("Observed pass")
	check(scene._panel_text.text.contains("cannot record a human"),"automated GUI click cannot counterfeit operator evidence")
	check(host.recorder.report().operator_results.controller=="not_tested","fake human click retains not tested")
	await choose("Return")
	var path: String=host.recorder._folder+"report.json";DirAccess.remove_absolute(path)
	current_scene.queue_free();current_scene=null;host.queue_free();await frames()
	# Actual mounted scene fixture with fake native client; no live Steam qualification claimed.
	var fake:=FakeClient.new();var steam_host:=Runtime.new();steam_host.name="PlatformRuntime";root.add_child(steam_host)
	steam_host.configure(PackedStringArray(["--steam-app-id=1234567"]),fake,true)
	var menu=load("res://ui/main_menu.tscn").instantiate();menu.home_save_path="user://store-overlay-test-only.json"
	root.add_child(menu);current_scene=menu;await frames()
	check(menu.save_reader.platform_services==steam_host.provider,"title uses explicit Steam account scope")
	await choose("1792 ·");scene=current_scene.get_node("ChildhoodChapter")
	check(scene.model.platform_services==steam_host.provider,"new game inherits the same explicit provider")
	scene.save_path="user://store-overlay-test-only.json"
	await frames(3)
	fake.overlay_toggled.emit(true,true,1234567);await frames()
	paused=scene.model.snapshot()
	await frames(5);await tap(JOY_BUTTON_A)
	check(scene._paused and scene.model.snapshot()==paused,"real home pauses on synthetic overlay, blocking background A")
	var count:=fake.callbacks;await frames(4)
	check(fake.callbacks>count,"callbacks continue during modal pause")
	fake.overlay_toggled.emit(false,false,1234567);await frames()
	check(scene._paused,"overlay close does not auto-resume")
	await tap(JOY_BUTTON_A);check(not scene._paused,"explicit resume after close")
	var cp: String=scene.checkpoint_path();var existed:=FileAccess.file_exists(cp)
	scene._capture_checkpoint("return_trail")
	check(FileAccess.file_exists(cp)==existed and scene._checkpoint_note.contains("not read or written"),"Steam does not use another account's legacy checkpoints")
	fake.user+=1;await frames()
	check(scene._paused and not scene.controls.focused,"runtime pump catches changed client identity in actual scene")
	current_scene.queue_free();current_scene=null;steam_host.queue_free();await frames()
	check(fake.shutdowns==1,"host shuts SDK down once")
	# Duplicate flags cannot accidentally select either supplied app or a local provider.
	var bad_host:=Runtime.new();root.add_child(bad_host)
	bad_host.configure(PackedStringArray(["--steam-app-id=1234567","--steam-app-id=1234568"]),FakeClient.new(),true)
	check(not bad_host.can_enter() and bad_host.blocked,"ambiguous launch flags fail closed")
	bad_host.queue_free();await frames()

func _run() -> void:
	_steam_domain();_hardware_domain();await _integration()
	print("STORE_INTEGRATION_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

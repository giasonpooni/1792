# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## The only implemented provider. Never substitutes a local profile for a store account.
const CONTRACT_ID := "cg.platform-services.v1"
const IMPLEMENTATION_ID := "cg.local-pc.v1"
const Storage := preload("res://platform/local_storage.gd")
var storage: RefCounted=Storage.new() # Explicit code-side injection; never chosen by a save.

func identity() -> Dictionary:
	return {"provider_id":IMPLEMENTATION_ID,"scope":"os-user-local","platform_user_id":null}

func capabilities() -> Dictionary:
	return {"local_save":true,"cloud_save":false,"platform_sign_in":false,
		"achievements":false,"entitlement_verification":false,"console_lifecycle":false}

func entitlement() -> Dictionary:
	return {"status":"not_checked","provider_id":IMPLEMENTATION_ID}

func unlock_achievement(_achievement_id: String) -> Dictionary:
	return {"ok":false,"code":"unavailable","provider_id":IMPLEMENTATION_ID}

static func create(profile_id: String) -> Dictionary:
	if profile_id!="local_pc":
		return {"error":"No implemented provider for "+profile_id+". Store/console services cannot silently fall back to local identity."}
	return {"error":"","provider":load("res://platform/local_services.gd").new()}

class_name CharacterCatalog
extends RefCounted

const FOX: StringName = &"fox"
const GOLEM: StringName = &"golem"
const ILLUSIONIST: StringName = &"illusionist"
const ALCHEMIST: StringName = &"alchemist"

const ALL: Array[StringName] = [FOX, GOLEM, ILLUSIONIST, ALCHEMIST]

const NAMES: Dictionary = {
	FOX: "VIX",
	GOLEM: "BULWARK",
	ILLUSIONIST: "MIRAGE",
	ALCHEMIST: "BUBBLES"
}

const MODELS: Dictionary = {
	FOX: "res://assets/characters/models/vix.glb",
	GOLEM: "res://assets/characters/models/bulwark.glb",
	ILLUSIONIST: "res://assets/characters/models/mirage.glb",
	ALCHEMIST: "res://assets/characters/models/bubbles.glb"
}

static func random_order() -> Array[StringName]:
	var order := ALL.duplicate()
	order.shuffle()
	return order

static func display_name(id: StringName) -> String:
	return NAMES.get(id, "UNKNOWN")

static func model_path(id: StringName) -> String:
	return MODELS.get(id, "")

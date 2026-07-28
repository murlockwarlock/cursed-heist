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

static func random_order() -> Array[StringName]:
	var order := ALL.duplicate()
	order.shuffle()
	return order

static func display_name(id: StringName) -> String:
	return NAMES.get(id, "UNKNOWN")

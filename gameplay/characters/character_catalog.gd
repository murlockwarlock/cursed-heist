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

const PORTRAIT_ATLAS: Texture2D = preload("res://assets/ui/character_portraits.png")
const PORTRAIT_INDICES: Dictionary = {
	FOX: 0,
	GOLEM: 1,
	ILLUSIONIST: 2,
	ALCHEMIST: 3
}

static func random_order() -> Array[StringName]:
	var order := ALL.duplicate()
	order.shuffle()
	return order

static func display_name(id: StringName) -> String:
	return NAMES.get(id, "UNKNOWN")

static func model_path(id: StringName) -> String:
	return MODELS.get(id, "")

static func portrait(id: StringName) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = PORTRAIT_ATLAS
	var index: int = PORTRAIT_INDICES.get(id, 0)
	var cell := PORTRAIT_ATLAS.get_size() * 0.5
	texture.region = Rect2(Vector2(index % 2, index / 2) * cell, cell)
	return texture

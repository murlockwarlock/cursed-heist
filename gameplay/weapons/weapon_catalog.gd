class_name WeaponCatalog
extends RefCounted

const BATON := &"baton"
const BLUNDERBUSS := &"blunderbuss"
const FOAM_SPRAYER := &"foam_sprayer"

const ALL: Array[StringName] = [BATON, BLUNDERBUSS, FOAM_SPRAYER]

const DEFINITIONS := {
	BATON: {"range": 2.25, "damage": 19.0, "force": 11.5, "cooldown": 0.62, "cone": -0.1, "color": Color("ffcf58")},
	BLUNDERBUSS: {"range": 6.2, "damage": 13.0, "force": 14.0, "cooldown": 1.35, "cone": 0.52, "color": Color("ff704f")},
	FOAM_SPRAYER: {"range": 5.2, "damage": 5.0, "force": 4.0, "cooldown": 0.82, "cone": 0.7, "color": Color("65e8ff")},
}

static func definition(id: StringName) -> Dictionary:
	return DEFINITIONS.get(id, DEFINITIONS[BATON])

static func title(id: StringName) -> String:
	return TranslationServer.translate(StringName("WEAPON_%s" % String(id).to_upper()))

static func next(id: StringName) -> StringName:
	var index := ALL.find(id)
	return ALL[(index + 1) % ALL.size()] if index >= 0 else BATON

static func random_order() -> Array[StringName]:
	var order: Array[StringName] = ALL.duplicate()
	order.shuffle()
	order.append(order[0])
	return order

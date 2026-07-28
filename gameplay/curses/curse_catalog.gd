class_name CurseCatalog
extends RefCounted

const HEAVY := &"heavy"
const GREED := &"greed"
const DANCE_FEVER := &"dance_fever"
const ECHO := &"echo"

const ALL: Array[StringName] = [HEAVY, GREED, DANCE_FEVER, ECHO]

static func title(id: StringName) -> String:
	match id:
		HEAVY:
			return TranslationServer.translate(&"CURSE_HEAVY")
		GREED:
			return TranslationServer.translate(&"CURSE_GREED")
		DANCE_FEVER:
			return TranslationServer.translate(&"CURSE_DANCE_FEVER")
		ECHO:
			return TranslationServer.translate(&"CURSE_ECHO")
	return TranslationServer.translate(&"CURSE_UNKNOWN")

static func color(id: StringName) -> Color:
	match id:
		HEAVY:
			return Color("8f79ff")
		GREED:
			return Color("ffd447")
		DANCE_FEVER:
			return Color("ff4fbd")
		ECHO:
			return Color("4de7ff")
	return Color.WHITE

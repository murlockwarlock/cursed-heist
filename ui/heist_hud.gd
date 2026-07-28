class_name HeistHud
extends CanvasLayer

var title_label: Label
var status_label: Label
var controls_label: Label
var player_labels: Array[Label] = []
var overlay: ColorRect
var result_label: Label

func _ready() -> void:
	title_label = _label(Vector2(64.0, 18.0), Vector2(500.0, 44.0), 24, Color("fff4c7"))
	title_label.text = tr(&"GAME_TITLE")
	status_label = _label(Vector2(504.0, 18.0), Vector2(712.0, 44.0), 20, Color.WHITE)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls_label = _label(Vector2(66.0, 665.0), Vector2(1148.0, 35.0), 14, Color("b8acd1"))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.text = tr(&"CONTROLS_HINT")
	for index: int in range(4):
		var label := _label(Vector2(82.0 + index * 286.0, 92.0), Vector2(240.0, 52.0), 16, Color.WHITE)
		player_labels.append(label)
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.015, 0.06, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	result_label = Label.new()
	result_label.position = Vector2(210.0, 270.0)
	result_label.size = Vector2(860.0, 180.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 32)
	result_label.add_theme_color_override("font_color", Color("fff4c7"))
	overlay.add_child(result_label)

func update_state(players: Array[HeistPlayer], time_left: float, charge: float, unlocked: bool, heat: float) -> void:
	var state := tr(&"EXIT_OPEN") if unlocked else tr(&"CHARGE_LABEL") % [charge, GameConstants.EXTRACTION_CHARGE]
	status_label.text = "%s    %s    %02d:%02d" % [state, tr(&"HEAT_LABEL") % int(heat * 100.0), int(time_left) / 60, int(time_left) % 60]
	for index: int in range(players.size()):
		var player := players[index]
		var curse_names: Array[String] = []
		for id: StringName in player.active_curses:
			curse_names.append(CurseCatalog.title(id))
		player_labels[index].text = "%s · %s  %03d\n%s" % [player.player_name, CharacterCatalog.display_name(player.character_id), int(player.score), " · ".join(curse_names)]
		player_labels[index].add_theme_color_override("font_color", player.body_color.lightened(0.24))

func show_result(winner: HeistPlayer, reason: String, titles: Array[String]) -> void:
	overlay.visible = true
	result_label.text = "%s\n%s\n\n%s\n\n%s" % [tr(&"WINNER_LABEL") % winner.player_name, reason, "    ".join(titles), tr(&"NEW_MATCH")]

func hide_result() -> void:
	overlay.visible = false

func _label(position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

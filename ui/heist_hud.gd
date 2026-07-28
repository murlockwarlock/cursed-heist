class_name HeistHud
extends CanvasLayer

const PLAYER_COLORS: Array[Color] = [Color("ff4d61"), Color("36d3ff"), Color("ffd43b"), Color("87f558")]

var title_label: Label
var timer_label: Label
var objective_label: Label
var controls_label: Label
var prompt_label: Label
var crosshair_label: Label
var local_card: PlayerStatusCard
var opponent_chips: Array[OpponentStatusChip] = []
var heat_panel: PanelContainer
var heat_bar: ProgressBar
var heat_label: Label
var overlay: ColorRect
var result_label: Label
var minimap: MuseumMinimap
var artifact: CursedArtifact
var void_shrines: Array[VoidShrine] = []
var started_msec := 0

func configure(assigned_artifact: CursedArtifact, assigned_void_shrines: Array[VoidShrine]) -> void:
	artifact = assigned_artifact
	void_shrines = assigned_void_shrines

func _ready() -> void:
	started_msec = Time.get_ticks_msec()
	title_label = _label(Vector2(26.0, 18.0), Vector2(260.0, 36.0), 20, Color("fff4c7"))
	title_label.text = tr(&"GAME_TITLE")
	_build_objective_panel()
	_build_opponent_chips()
	_build_local_status()
	_build_heat_panel()
	_build_center_prompts()
	_build_minimap()
	_build_result_overlay()

func update_state(players: Array[HeistPlayer], time_left: float, charge: float, unlocked: bool, heat: float) -> void:
	var local_player := players[0]
	local_card.update_player(local_player)
	for index: int in range(opponent_chips.size()):
		opponent_chips[index].update_player(players[index + 1])
	timer_label.text = "%02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	objective_label.text = _objective_text(players, charge, unlocked)
	heat_panel.visible = local_player.carried_artifact != null
	heat_bar.value = heat * 100.0
	heat_label.text = tr(&"ARTIFACT_OVERHEAT") % int(heat * 100.0)
	controls_label.visible = Time.get_ticks_msec() - started_msec < 9000
	minimap.update_players(players)

func update_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

func show_result(winner: HeistPlayer, reason: String, titles: Array[String]) -> void:
	overlay.visible = true
	result_label.text = "%s\n%s\n\n%s\n\n%s" % [tr(&"WINNER_LABEL") % winner.player_name, reason, "    ".join(titles), tr(&"NEW_MATCH")]

func hide_result() -> void:
	overlay.visible = false

func _objective_text(players: Array[HeistPlayer], charge: float, unlocked: bool) -> String:
	if unlocked:
		return tr(&"OBJECTIVE_ESCAPE")
	var seals := mini(int(charge / (GameConstants.EXTRACTION_CHARGE / GameConstants.EXIT_SEAL_COUNT)), GameConstants.EXIT_SEAL_COUNT)
	for player: HeistPlayer in players:
		if player.carried_artifact == null:
			continue
		if player == players[0]:
			return tr(&"OBJECTIVE_BREAK_SEALS") % [seals, GameConstants.EXIT_SEAL_COUNT]
		return tr(&"OBJECTIVE_STEAL_FROM") % player.player_name
	return tr(&"OBJECTIVE_FIND_ARTIFACT")

func _build_objective_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(390.0, 15.0)
	panel.custom_minimum_size = Vector2(500.0, 62.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("d7b5ff"), 3))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	objective_label = Label.new()
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color("fff4c7"))
	row.add_child(objective_label)
	timer_label = Label.new()
	timer_label.custom_minimum_size.x = 78.0
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color("ffd05a"))
	row.add_child(timer_label)

func _build_opponent_chips() -> void:
	for index: int in range(3):
		var chip := OpponentStatusChip.new()
		chip.position = Vector2(660.0 + index * 198.0, 88.0)
		add_child(chip)
		chip.configure(PLAYER_COLORS[index + 1])
		opponent_chips.append(chip)

func _build_local_status() -> void:
	local_card = PlayerStatusCard.new()
	local_card.position = Vector2(24.0, 575.0)
	add_child(local_card)
	local_card.configure(PLAYER_COLORS[0])

func _build_heat_panel() -> void:
	heat_panel = PanelContainer.new()
	heat_panel.position = Vector2(466.0, 616.0)
	heat_panel.custom_minimum_size = Vector2(350.0, 66.0)
	heat_panel.add_theme_stylebox_override("panel", _panel_style(Color("ff6b55"), 3))
	add_child(heat_panel)
	var content := VBoxContainer.new()
	heat_panel.add_child(content)
	heat_label = Label.new()
	heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heat_label.add_theme_font_size_override("font_size", 15)
	content.add_child(heat_label)
	heat_bar = ProgressBar.new()
	heat_bar.max_value = 100.0
	heat_bar.show_percentage = false
	heat_bar.custom_minimum_size.y = 16.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ff5848")
	fill.set_corner_radius_all(4)
	heat_bar.add_theme_stylebox_override("fill", fill)
	content.add_child(heat_bar)

func _build_center_prompts() -> void:
	crosshair_label = _label(Vector2(622.0, 342.0), Vector2(36.0, 36.0), 24, Color("fff4c7"))
	crosshair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair_label.text = "+"
	prompt_label = _label(Vector2(390.0, 402.0), Vector2(500.0, 48.0), 19, Color("fff4c7"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label = _label(Vector2(320.0, 676.0), Vector2(920.0, 28.0), 12, Color("b8acd1"))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls_label.text = tr(&"CONTROLS_HINT")

func _build_minimap() -> void:
	minimap = MuseumMinimap.new()
	minimap.position = Vector2(1034.0, 520.0)
	minimap.size = Vector2(220.0, 165.0)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.configure(artifact, void_shrines)
	add_child(minimap)

func _build_result_overlay() -> void:
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

func _panel_style(border_color: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("100c18e8")
	style.border_color = border_color
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func _label(position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

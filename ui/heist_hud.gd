class_name HeistHud
extends CanvasLayer

const LOCAL_COLOR := Color("ff4d61")

var timer_label: Label
var objective_label: Label
var prompt_label: Label
var local_card: PlayerStatusCard
var artifact_panel: PanelContainer
var artifact_label: Label
var heat_bar: ProgressBar
var grip_bar: ProgressBar
var overlay: ColorRect
var result_label: Label
var minimap: MuseumMinimap
var artifact: CursedArtifact
var void_shrines: Array[VoidShrine] = []
var exit_seals: Array[ExitSeal] = []
var last_refresh_msec := -1000
var last_prompt := ""

func configure(assigned_artifact: CursedArtifact, assigned_void_shrines: Array[VoidShrine], assigned_exit_seals: Array[ExitSeal]) -> void:
	artifact = assigned_artifact
	void_shrines = assigned_void_shrines
	exit_seals = assigned_exit_seals

func _ready() -> void:
	_build_objective_panel()
	_build_local_status()
	_build_artifact_panel()
	_build_center_prompt()
	_build_minimap()
	_build_result_overlay()

func update_state(players: Array[HeistPlayer], time_left: float, charge: float, unlocked: bool, heat: float) -> void:
	var now := Time.get_ticks_msec()
	if now - last_refresh_msec < 80:
		return
	last_refresh_msec = now
	var local_player := players[0]
	local_card.update_player(local_player)
	timer_label.text = "%02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	objective_label.text = _objective_text(players, local_player, charge, unlocked)
	artifact_panel.visible = local_player.carried_artifact != null
	heat_bar.value = heat * 100.0
	grip_bar.value = artifact.grip
	artifact_label.text = tr(&"ARTIFACT_STATUS") % [int(artifact.grip), int(heat * 100.0)]
	minimap.update_players(players)

func update_prompt(text: String) -> void:
	if text == last_prompt:
		return
	last_prompt = text
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

func show_result(winner: HeistPlayer, reason: String, titles: Array[String]) -> void:
	overlay.visible = true
	result_label.text = "%s\n%s\n\n%s\n\n%s" % [tr(&"WINNER_LABEL") % winner.player_name, reason, "    ".join(titles), tr(&"NEW_MATCH")]

func hide_result() -> void:
	overlay.visible = false

func _objective_text(players: Array[HeistPlayer], local_player: HeistPlayer, charge: float, unlocked: bool) -> String:
	if local_player.is_ghost:
		return tr(&"OBJECTIVE_RESPAWN") % ceili(local_player.respawn_seconds)
	if unlocked:
		return tr(&"OBJECTIVE_ESCAPE")
	var seals := mini(int(charge), GameConstants.EXIT_SEAL_COUNT)
	for player: HeistPlayer in players:
		if player.carried_artifact == null:
			continue
		if player == local_player:
			return tr(&"OBJECTIVE_BREAK_SEALS") % [seals, GameConstants.EXIT_SEAL_COUNT]
		return tr(&"OBJECTIVE_STEAL_ARTIFACT")
	return tr(&"OBJECTIVE_FIND_ARTIFACT")

func _build_objective_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(415.0, 16.0)
	panel.custom_minimum_size = Vector2(450.0, 52.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("d7bd7c"), 2))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	objective_label = Label.new()
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 15)
	objective_label.add_theme_color_override("font_color", Color("fff0c2"))
	row.add_child(objective_label)
	timer_label = Label.new()
	timer_label.custom_minimum_size.x = 70.0
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color("ffd05a"))
	row.add_child(timer_label)

func _build_local_status() -> void:
	local_card = PlayerStatusCard.new()
	local_card.position = Vector2(18.0, 616.0)
	add_child(local_card)
	local_card.configure(LOCAL_COLOR)

func _build_artifact_panel() -> void:
	artifact_panel = PanelContainer.new()
	artifact_panel.position = Vector2(475.0, 642.0)
	artifact_panel.custom_minimum_size = Vector2(330.0, 55.0)
	artifact_panel.add_theme_stylebox_override("panel", _panel_style(Color("ffb54c"), 2))
	add_child(artifact_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	artifact_panel.add_child(content)
	artifact_label = Label.new()
	artifact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	artifact_label.add_theme_font_size_override("font_size", 12)
	content.add_child(artifact_label)
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 5)
	content.add_child(bars)
	grip_bar = _progress_bar(Color("ffd55c"))
	heat_bar = _progress_bar(Color("ff5848"))
	bars.add_child(grip_bar)
	bars.add_child(heat_bar)

func _build_center_prompt() -> void:
	var crosshair := _label(Vector2(622.0, 342.0), Vector2(36.0, 36.0), 21, Color("fff0c2"))
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.text = "•"
	prompt_label = _label(Vector2(415.0, 392.0), Vector2(450.0, 40.0), 16, Color("fff0c2"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_minimap() -> void:
	minimap = MuseumMinimap.new()
	minimap.position = Vector2(1094.0, 534.0)
	minimap.size = Vector2(168.0, 168.0)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.configure(artifact, void_shrines, exit_seals)
	add_child(minimap)

func _build_result_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.015, 0.06, 0.9)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	result_label = Label.new()
	result_label.position = Vector2(210.0, 270.0)
	result_label.size = Vector2(860.0, 180.0)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.add_theme_color_override("font_color", Color("fff0c2"))
	overlay.add_child(result_label)

func _progress_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(140.0, 11.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background := StyleBoxFlat.new()
	background.bg_color = Color("21172f")
	background.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _panel_style(border_color: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("090711e8")
	style.border_color = border_color
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _label(position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

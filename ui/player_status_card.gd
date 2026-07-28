class_name PlayerStatusCard
extends PanelContainer

var portrait: TextureRect
var title_label: Label
var health_bar: ProgressBar
var detail_label: Label
var weapon_label: Label
var accent := Color.WHITE
var shown_character: StringName = &""

func _ready() -> void:
	custom_minimum_size = Vector2(300.0, 86.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(68.0, 68.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
	row.add_child(content)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 14)
	content.add_child(title_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size.y = 12.0
	health_bar.max_value = GameConstants.MAX_HEALTH
	health_bar.show_percentage = false
	content.add_child(health_bar)
	detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 11)
	detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(detail_label)
	weapon_label = Label.new()
	weapon_label.add_theme_font_size_override("font_size", 12)
	content.add_child(weapon_label)

func configure(color: Color) -> void:
	accent = color
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("0b0812e8")
	panel_style.border_color = Color("d5bb79")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(9)
	panel_style.content_margin_left = 7.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 7.0
	panel_style.content_margin_bottom = 7.0
	add_theme_stylebox_override("panel", panel_style)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("21172f")
	background.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", fill)
	title_label.add_theme_color_override("font_color", Color("fff0c2"))

func update_player(player: HeistPlayer) -> void:
	if shown_character != player.character_id:
		shown_character = player.character_id
		portrait.texture = CharacterCatalog.portrait(player.character_id)
	title_label.text = "%s    %03d" % [CharacterCatalog.display_name(player.character_id), int(player.score)]
	health_bar.value = player.health
	health_bar.modulate = Color(0.45, 0.9, 1.0, 0.68) if player.is_ghost else Color.WHITE
	var statuses: Array[String] = []
	for id: StringName in player.active_curses:
		statuses.append(CurseCatalog.title(id))
	if player.slowed_seconds > 0.0:
		statuses.append(tr(&"STATUS_FOAMED") % ceili(player.slowed_seconds))
	if player.spawn_protection_seconds > 0.0:
		statuses.append(tr(&"STATUS_PROTECTED") % ceili(player.spawn_protection_seconds))
	var life_state := tr(&"STATUS_RESPAWNING") % ceili(player.respawn_seconds) if player.is_ghost else tr(&"HEALTH_LABEL") % int(player.health)
	detail_label.text = life_state if statuses.is_empty() else "%s · %s" % [life_state, " · ".join(statuses)]
	weapon_label.text = WeaponCatalog.title(player.weapon_id)
	weapon_label.add_theme_color_override("font_color", WeaponCatalog.definition(player.weapon_id)["color"])

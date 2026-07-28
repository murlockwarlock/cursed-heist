class_name PlayerStatusCard
extends PanelContainer

var title_label: Label
var health_bar: ProgressBar
var detail_label: Label
var accent := Color.WHITE

func _ready() -> void:
	custom_minimum_size = Vector2(270.0, 76.0)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	add_child(content)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 16)
	content.add_child(title_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size.y = 15.0
	health_bar.max_value = GameConstants.MAX_HEALTH
	health_bar.show_percentage = false
	content.add_child(health_bar)
	detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 12)
	detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(detail_label)

func configure(color: Color) -> void:
	accent = color
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("110d19dd")
	panel_style.border_color = Color("fff0c2")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(5)
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", panel_style)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("21172f")
	background.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", fill)
	title_label.add_theme_color_override("font_color", accent.lightened(0.22))

func update_player(player: HeistPlayer) -> void:
	title_label.text = "%s · %s    %03d" % [player.player_name, CharacterCatalog.display_name(player.character_id), int(player.score)]
	health_bar.value = player.health
	health_bar.modulate = Color(0.5, 0.9, 1.0, 0.72) if player.is_ghost else Color.WHITE
	var curse_names: Array[String] = []
	for id: StringName in player.active_curses:
		curse_names.append(CurseCatalog.title(id))
	var life_state := tr(&"GHOST_LABEL") if player.is_ghost else tr(&"HEALTH_LABEL") % int(player.health)
	detail_label.text = "%s    %s" % [life_state, " · ".join(curse_names)]

class_name OpponentStatusChip
extends PanelContainer

var name_label: Label
var accent := Color.WHITE

func _ready() -> void:
	custom_minimum_size = Vector2(188.0, 38.0)
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	add_child(name_label)

func configure(color: Color) -> void:
	accent = color
	var style := StyleBoxFlat.new()
	style.bg_color = Color("100c18df")
	style.border_color = accent.darkened(0.12)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	add_theme_stylebox_override("panel", style)
	name_label.add_theme_color_override("font_color", accent.lightened(0.2))

func update_player(player: HeistPlayer) -> void:
	var state := tr(&"GHOST_LABEL") if player.is_ghost else "%d" % int(player.score)
	name_label.text = "%s · %s   %s" % [player.player_name, CharacterCatalog.display_name(player.character_id), state]

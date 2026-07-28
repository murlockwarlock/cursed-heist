class_name PlayerWorldMarker
extends Node3D

var player: HeistPlayer
var name_label: Label3D
var state_label: Label3D
var health_fill: MeshInstance3D
var update_seconds := 0.0

func configure(assigned_player: HeistPlayer) -> void:
	player = assigned_player
	_build()

func _process(delta: float) -> void:
	update_seconds -= delta
	if update_seconds > 0.0 or not is_instance_valid(player):
		return
	update_seconds = 0.1
	_update_state()

func _build() -> void:
	name_label = Label3D.new()
	name_label.position.y = 2.92
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.font_size = 34
	name_label.pixel_size = 0.005
	name_label.outline_size = 8
	name_label.modulate = player.body_color.lightened(0.22)
	add_child(name_label)
	state_label = Label3D.new()
	state_label.position.y = 3.22
	state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	state_label.font_size = 30
	state_label.pixel_size = 0.005
	state_label.outline_size = 8
	state_label.modulate = Color("ffd85a")
	add_child(state_label)
	_add_bar(Color("130d1cdd"), Vector3(0.0, 2.69, 0.0), 1.04)
	health_fill = _add_bar(player.body_color, Vector3(0.0, 2.69, -0.006), 1.0)
	_update_state()

func _update_state() -> void:
	visible = player.player_index > 0
	name_label.text = "%s · %s" % [player.player_name, CharacterCatalog.display_name(player.character_id)]
	var ratio := clampf(player.health / GameConstants.MAX_HEALTH, 0.0, 1.0)
	health_fill.scale.x = maxf(ratio, 0.001)
	health_fill.position.x = -(1.0 - ratio) * 0.5
	name_label.visible = player.player_index > 0
	health_fill.visible = player.player_index > 0 and not player.is_ghost
	state_label.text = _state_text()
	state_label.visible = not state_label.text.is_empty()

func _state_text() -> String:
	if player.is_ghost:
		return tr(&"WORLD_RESPAWN") % ceili(player.respawn_seconds)
	if player.carried_artifact != null:
		return "◆"
	if player.spawn_protection_seconds > 0.0:
		return "◇"
	return ""

func _add_bar(color: Color, position: Vector3, width: float) -> MeshInstance3D:
	var bar := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width, 0.09)
	bar.mesh = mesh
	bar.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bar.material_override = material
	add_child(bar)
	return bar

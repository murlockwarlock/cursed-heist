class_name VoidShrine
extends Node3D

signal activated(shrine: VoidShrine, player: HeistPlayer, reward: StringName)

const CHANNEL_SECONDS := 2.4

var reward_id: StringName
var activator: HeistPlayer
var progress := 0.0
var consumed := false
var ring_material: StandardMaterial3D
var label: Label3D

func configure(reward: StringName) -> void:
	reward_id = reward

func _ready() -> void:
	_build_visual()

func _process(delta: float) -> void:
	rotation.y += delta * 0.32
	if consumed or not is_instance_valid(activator):
		return
	if activator.is_ghost or activator.global_position.distance_to(global_position) > GameConstants.VOID_RANGE:
		cancel_activation()
		return
	progress = minf(progress + delta, CHANNEL_SECONDS)
	ring_material.emission_energy_multiplier = 1.8 + progress * 1.6
	label.text = "%s\n%d%%" % [_reward_title(), int(progress / CHANNEL_SECONDS * 100.0)]
	if progress >= CHANNEL_SECONDS:
		consumed = true
		var player := activator
		activator = null
		label.text = tr(&"VOID_SPENT")
		activated.emit(self, player, reward_id)

func can_interact(player: HeistPlayer) -> bool:
	return not consumed and not is_instance_valid(activator) and not player.is_ghost and player.global_position.distance_to(global_position) <= GameConstants.VOID_RANGE

func begin_activation(player: HeistPlayer) -> void:
	if not can_interact(player):
		return
	activator = player
	progress = 0.0
	label.text = "%s\n0%%" % _reward_title()

func cancel_activation() -> void:
	activator = null
	progress = 0.0
	ring_material.emission_energy_multiplier = 1.8
	label.text = "%s\n%s" % [tr(&"VOID_LABEL"), _reward_title()]

func reset() -> void:
	consumed = false
	cancel_activation()

func _build_visual() -> void:
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.35
	base_mesh.bottom_radius = 1.55
	base_mesh.height = 0.22
	base_mesh.radial_segments = 16
	base.mesh = base_mesh
	base.position.y = 0.11
	base.material_override = _material(Color("181020"), 0.45, 0.32)
	add_child(base)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.05
	torus.outer_radius = 1.22
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.position.y = 0.28
	ring_material = _material(_reward_color(), 0.35, 0.22)
	ring_material.emission_enabled = true
	ring_material.emission = _reward_color()
	ring_material.emission_energy_multiplier = 1.8
	ring.material_override = ring_material
	add_child(ring)
	for index: int in range(5):
		var shard := MeshInstance3D.new()
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(0.3, 0.8 + index * 0.08, 0.3)
		shard.mesh = shard_mesh
		var angle := index * TAU / 5.0
		shard.position = Vector3(cos(angle) * 0.74, 0.7, sin(angle) * 0.74)
		shard.rotation = Vector3(0.25, -angle, 0.18)
		shard.material_override = ring_material
		add_child(shard)
	label = Label3D.new()
	label.position.y = 1.75
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.font_size = 42
	label.pixel_size = 0.006
	label.outline_size = 9
	label.modulate = Color("fff2c7")
	label.text = "%s\n%s" % [tr(&"VOID_LABEL"), _reward_title()]
	add_child(label)

func _reward_title() -> String:
	return tr(StringName("VOID_REWARD_%s" % String(reward_id).to_upper()))

func _reward_color() -> Color:
	match reward_id:
		&"time":
			return Color("55d9ff")
		&"heal":
			return Color("71ff76")
		&"cleanse":
			return Color("d28cff")
		&"weapon":
			return Color("ff9b42")
	return Color("a95cff")

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

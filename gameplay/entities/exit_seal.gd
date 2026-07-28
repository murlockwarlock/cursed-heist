class_name ExitSeal
extends Node3D

signal broken(seal: ExitSeal, player: HeistPlayer)

const CHANNEL_SECONDS := 2.2
const CHANNEL_RANGE := 2.35

var seal_index := 0
var activator: HeistPlayer
var progress := 0.0
var is_broken := false
var ring_material: StandardMaterial3D
var label: Label3D

func configure(index: int) -> void:
	seal_index = index

func _ready() -> void:
	_build_visual()

func _process(delta: float) -> void:
	rotation.y += delta * 0.18
	if is_instance_valid(ring_material):
		ring_material.emission_energy_multiplier = 1.4 + sin(Time.get_ticks_msec() * 0.004 + seal_index) * 0.22

func update_carrier(carrier: HeistPlayer, delta: float) -> void:
	if is_broken:
		return
	if not is_instance_valid(carrier) or carrier.is_ghost or carrier.global_position.distance_to(global_position) > CHANNEL_RANGE:
		cancel_channel()
		return
	if activator != carrier:
		activator = carrier
		progress = 0.0
	progress = minf(progress + delta, CHANNEL_SECONDS)
	label.text = "%s · %d%%" % [tr(&"EXIT_SEAL_LABEL"), int(progress / CHANNEL_SECONDS * 100.0)]
	if progress >= CHANNEL_SECONDS:
		is_broken = true
		var player := activator
		activator = null
		label.text = tr(&"EXIT_SEAL_BROKEN")
		ring_material.albedo_color = Color("4c515d")
		ring_material.emission = Color("342a44")
		broken.emit(self, player)

func cancel_channel() -> void:
	if not is_instance_valid(activator):
		return
	activator = null
	progress = 0.0
	label.text = tr(&"EXIT_SEAL_LABEL")

func reset() -> void:
	activator = null
	progress = 0.0
	is_broken = false
	if is_instance_valid(label):
		label.text = tr(&"EXIT_SEAL_LABEL")
	if is_instance_valid(ring_material):
		ring_material.albedo_color = Color("b951ff")
		ring_material.emission = Color("9d35ff")

func _build_visual() -> void:
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.75
	base_mesh.bottom_radius = 0.95
	base_mesh.height = 0.28
	base_mesh.radial_segments = 12
	base.mesh = base_mesh
	base.position.y = 0.14
	base.material_override = _material(Color("20152d"), 0.38, 0.4)
	add_child(base)
	var pillar := MeshInstance3D.new()
	var pillar_mesh := PrismMesh.new()
	pillar_mesh.size = Vector3(0.62, 1.55, 0.62)
	pillar.mesh = pillar_mesh
	pillar.position.y = 0.94
	pillar.material_override = _material(Color("563a6c"), 0.22, 0.42)
	add_child(pillar)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.52
	torus.outer_radius = 0.66
	torus.rings = 24
	torus.ring_segments = 6
	ring.mesh = torus
	ring.position.y = 1.18
	ring.rotation.x = PI * 0.5
	ring_material = _material(Color("b951ff"), 0.48, 0.24)
	ring_material.emission_enabled = true
	ring_material.emission = Color("9d35ff")
	ring.material_override = ring_material
	add_child(ring)
	label = Label3D.new()
	label.position.y = 2.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 34
	label.pixel_size = 0.005
	label.outline_size = 8
	label.modulate = Color("fff0c2")
	label.text = tr(&"EXIT_SEAL_LABEL")
	add_child(label)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

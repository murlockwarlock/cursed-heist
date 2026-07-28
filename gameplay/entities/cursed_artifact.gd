class_name CursedArtifact
extends RigidBody3D

signal carrier_changed(previous: HeistPlayer, current: HeistPlayer)

var carrier: HeistPlayer
var last_carrier: HeistPlayer
var pickup_lock := 0.0
var pulse := 0.0
var heat := 0.0
var beacon: Node3D

func _ready() -> void:
	gravity_scale = 1.0
	linear_damp = 3.4
	angular_damp = 4.2
	continuous_cd = true
	can_sleep = false
	collision_layer = 2
	collision_mask = 4
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.42
	collider.shape = shape
	add_child(collider)
	_build_visual()

func _process(delta: float) -> void:
	pulse += delta
	pickup_lock = maxf(pickup_lock - delta, 0.0)
	if is_instance_valid(carrier):
		global_position = carrier.global_position + carrier.facing * 0.82 + Vector3.UP * 1.08
		rotation.y += delta * 2.4
	beacon.visible = not is_instance_valid(carrier)

func pick_up(player: HeistPlayer) -> bool:
	if is_instance_valid(carrier) or player.is_ghost:
		return false
	if pickup_lock > 0.0 and player == last_carrier:
		return false
	var previous := carrier
	last_carrier = player
	carrier = player
	player.carried_artifact = self
	freeze = true
	linear_velocity = Vector3.ZERO
	carrier_changed.emit(previous, carrier)
	return true

func drop(throw_velocity: Vector3) -> void:
	if not is_instance_valid(carrier):
		return
	var previous := carrier
	last_carrier = previous
	carrier.carried_artifact = null
	carrier = null
	freeze = false
	pickup_lock = 0.45
	linear_velocity = throw_velocity
	carrier_changed.emit(previous, null)

func reset_to(position: Vector3) -> void:
	if is_instance_valid(carrier):
		carrier.carried_artifact = null
		carrier = null
	last_carrier = null
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = position
	pickup_lock = 0.5

func _build_visual() -> void:
	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.39
	core_mesh.height = 0.78
	core_mesh.radial_segments = 32
	core_mesh.rings = 16
	core.mesh = core_mesh
	var core_material := StandardMaterial3D.new()
	core_material.albedo_color = Color("7d3cff")
	core_material.emission_enabled = true
	core_material.emission = Color("7d3cff")
	core_material.emission_energy_multiplier = 2.6
	core.material_override = core_material
	add_child(core)
	for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.42
		torus.outer_radius = 0.51
		torus.rings = 32
		torus.ring_segments = 8
		ring.mesh = torus
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("ffc942")
		material.metallic = 0.72
		material.roughness = 0.24
		ring.material_override = material
		if axis == Vector3.RIGHT:
			ring.rotation.z = PI * 0.5
		elif axis == Vector3.FORWARD:
			ring.rotation.x = PI * 0.5
		add_child(ring)
	beacon = Node3D.new()
	add_child(beacon)
	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.16
	beam_mesh.bottom_radius = 0.46
	beam_mesh.height = 6.0
	beam.mesh = beam_mesh
	beam.position.y = 3.0
	var beam_material := StandardMaterial3D.new()
	beam_material.albedo_color = Color(0.55, 0.18, 1.0, 0.13)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.emission_enabled = true
	beam_material.emission = Color("8f43ff")
	beam_material.emission_energy_multiplier = 1.5
	beam.material_override = beam_material
	beacon.add_child(beam)
	var label := Label3D.new()
	label.text = tr(&"ARTIFACT_LABEL")
	label.position.y = 1.25
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 48
	label.pixel_size = 0.006
	label.modulate = Color("fff0c2")
	label.outline_size = 10
	beacon.add_child(label)

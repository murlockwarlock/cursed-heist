class_name HeistArena
extends Node3D

const EXTRACTION_CENTER := Vector3(20.45, 0.0, 0.0)

var extraction_unlocked := false
var pulse := 0.0
var seal_material: StandardMaterial3D
var door_left: AnimatableBody3D
var door_right: AnimatableBody3D
var prop_spawner: MuseumPropSpawner
var chests: Array[LootChest] = []

func _ready() -> void:
	_build_environment()

func _process(delta: float) -> void:
	pulse += delta
	if is_instance_valid(seal_material):
		seal_material.emission_energy_multiplier = 2.0 + sin(pulse * 4.0) * 0.45
	var target_gap := 1.35 if extraction_unlocked else 0.0
	door_left.position.z = lerpf(door_left.position.z, -1.05 - target_gap, delta * 3.0)
	door_right.position.z = lerpf(door_right.position.z, 1.05 + target_gap, delta * 3.0)

func set_extraction_unlocked(value: bool) -> void:
	extraction_unlocked = value

func contains_extraction(point: Vector3) -> bool:
	return extraction_unlocked and absf(point.x - EXTRACTION_CENTER.x) < 1.6 and absf(point.z) < 2.4

func safe_artifact_position(point: Vector3) -> bool:
	return absf(point.x) <= 22.8 and absf(point.z) <= 15.8 and point.y > -2.0

func _build_environment() -> void:
	_create_box("Floor", Vector3(45.0, 0.5, 31.0), Vector3(0.0, -0.25, 0.0), Color("18102a"), true, 0.08)
	_build_zone_floors()
	_create_box("NorthWall", Vector3(45.0, 5.2, 0.55), Vector3(0.0, 2.6, -15.25), Color("2b1b43"), true, 0.12)
	_create_box("SouthWall", Vector3(45.0, 5.2, 0.55), Vector3(0.0, 2.6, 15.25), Color("2b1b43"), true, 0.12)
	_create_box("WestWall", Vector3(0.55, 5.2, 31.0), Vector3(-22.25, 2.6, 0.0), Color("2b1b43"), true, 0.12)
	_create_box("EastWallA", Vector3(0.55, 5.2, 11.3), Vector3(22.25, 2.6, -9.35), Color("2b1b43"), true, 0.12)
	_create_box("EastWallB", Vector3(0.55, 5.2, 11.3), Vector3(22.25, 2.6, 9.35), Color("2b1b43"), true, 0.12)
	for wall: Dictionary in MuseumLayout.WALLS:
		_create_box("GalleryWall", wall["size"], wall["position"], Color("392451"), true, 0.14)
	for x: float in [-18.0, -12.0, -6.0, 6.0, 12.0, 18.0]:
		_create_column(Vector3(x, 0.0, -14.2))
		_create_column(Vector3(x, 0.0, 14.2))
	for arch: Dictionary in MuseumLayout.ARCHES:
		_create_arch(arch["position"], arch["rotated"])
	_create_central_dais()
	_build_rotunda_accents()
	prop_spawner = MuseumPropSpawner.new()
	add_child(prop_spawner)
	prop_spawner.populate()
	chests = prop_spawner.chests
	_build_exit()

func reset_chests() -> void:
	prop_spawner.reset_chests()

func _build_zone_floors() -> void:
	for zone: Dictionary in MuseumLayout.ZONES:
		_create_box(String(zone["name"]), zone["size"], zone["position"], zone["color"], false, 0.08)
	for x: int in range(-21, 22, 2):
		for z: int in range(-14, 15, 2):
			var tile_color := _zone_tile_color(x, z).lightened(0.045) if (x + z) % 4 == 0 else _zone_tile_color(x, z)
			_create_box("FloorInlay", Vector3(1.78, 0.025, 1.78), Vector3(x, 0.085, z), tile_color, false, 0.18)
	for z: float in [-1.6, 0.0, 1.6]:
		_create_box("FoyerCarpet", Vector3(9.5, 0.04, 1.35), Vector3(-16.8, 0.115, z), Color("6d245a"), false, 0.02)
	for x: float in [3.0, 6.5, 10.0, 13.5]:
		_create_box("TreasuryRunner", Vector3(2.6, 0.04, 0.18), Vector3(x, 0.12, 9.7), Color("d38122"), false, 0.55)

func _zone_tile_color(x: float, z: float) -> Color:
	if x > 14.0 and absf(z) < 5.8:
		return Color("224754")
	if x > 0.0 and z > 5.8:
		return Color("552934")
	if x > 0.0 and z < -5.8:
		return Color("343d54")
	if x < -4.5 and z < -5.8:
		return Color("293766")
	if x < -9.0 and absf(z) < 5.8:
		return Color("49265a")
	return Color("3b265b")

func _build_rotunda_accents() -> void:
	for radius: float in [2.5, 4.7]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.09
		torus.outer_radius = radius + 0.09
		torus.rings = 48
		torus.ring_segments = 6
		ring.mesh = torus
		ring.position.y = 0.14
		ring.material_override = _emissive_material(Color("9c45ff"), 1.8)
		add_child(ring)
	for light_position: Vector3 in MuseumLayout.ROTUNDA_LIGHTS:
		var light := OmniLight3D.new()
		light.position = light_position + Vector3.UP * 1.2
		light.light_color = Color("9c54ff")
		light.light_energy = 1.8
		light.omni_range = 4.2
		add_child(light)

func _create_arch(position: Vector3, rotated: bool) -> void:
	var pillar_offset := Vector3(2.25, 1.5, 0.0) if not rotated else Vector3(0.0, 1.5, 2.25)
	var pillar_size := Vector3(0.7, 3.0, 1.0) if not rotated else Vector3(1.0, 3.0, 0.7)
	var beam_size := Vector3(5.2, 0.65, 1.0) if not rotated else Vector3(1.0, 0.65, 5.2)
	_create_box("ArchPillar", pillar_size, position + pillar_offset, Color("4a315f"), true, 0.18)
	_create_box("ArchPillar", pillar_size, position + Vector3(-pillar_offset.x, pillar_offset.y, -pillar_offset.z), Color("4a315f"), true, 0.18)
	_create_box("ArchBeam", beam_size, position + Vector3.UP * 3.25, Color("59406e"), true, 0.22)

func _create_central_dais() -> void:
	var base := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.4
	cylinder.bottom_radius = 1.65
	cylinder.height = 0.38
	cylinder.radial_segments = 32
	base.mesh = cylinder
	base.position.y = 0.19
	base.material_override = _material(Color("49306c"), 0.32, 0.38)
	add_child(base)
	var body := StaticBody3D.new()
	body.collision_layer = 4
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.5
	shape.height = 0.38
	collider.shape = shape
	collider.position.y = 0.19
	body.add_child(collider)
	add_child(body)

func _create_column(position: Vector3) -> void:
	var column := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.38
	mesh.bottom_radius = 0.48
	mesh.height = 3.7
	mesh.radial_segments = 16
	column.mesh = mesh
	column.position = position + Vector3.UP * 1.85
	column.material_override = _material(Color("5b4078"), 0.18, 0.55)
	add_child(column)

func _build_exit() -> void:
	door_left = _create_door("ExitDoorLeft", -1.05)
	door_right = _create_door("ExitDoorRight", 1.05)
	var seal := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.65
	torus.outer_radius = 0.83
	torus.rings = 32
	torus.ring_segments = 10
	seal.mesh = torus
	seal.position = Vector3(21.72, 2.0, 0.0)
	seal.rotation.z = PI * 0.5
	seal_material = _material(Color("ff4267"), 0.4, 0.3)
	seal_material.emission_enabled = true
	seal_material.emission = Color("ff234f")
	seal.material_override = seal_material
	add_child(seal)

func _create_door(name: String, z_position: float) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.name = name
	body.collision_layer = 4
	body.position = Vector3(22.0, 1.8, z_position)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.45, 3.6, 2.0)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(Color("5a3a70"), 0.62, 0.3)
	body.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.45, 3.6, 2.0)
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	return body

func _create_box(name: String, size: Vector3, position: Vector3, color: Color, collision: bool, metallic: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color, metallic, 0.5)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)
	if collision:
		var body := StaticBody3D.new()
		body.collision_layer = 4
		body.position = position
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
	return instance

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color, 0.4, 0.25)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

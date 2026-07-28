class_name HeistArena
extends Node3D

const EXTRACTION_CENTER := Vector3(38.5, 0.0, 0.0)
const ARTIFACT_HOME := Vector3(-6.0, 1.2, 0.0)
const ROTUNDA_CENTER := Vector3(-6.0, 0.0, 0.0)

var extraction_unlocked := false
var pulse := 0.0
var seal_material: StandardMaterial3D
var door_left: AnimatableBody3D
var door_right: AnimatableBody3D
var prop_spawner: MuseumPropSpawner
var chests: Array[LootChest] = []
var void_shrines: Array[VoidShrine] = []

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
	return absf(point.x) <= 40.8 and absf(point.z) <= 30.8 and point.y > -2.0

func _build_environment() -> void:
	_create_box("Floor", Vector3(81.0, 0.5, 61.0), Vector3(0.0, -0.25, 0.0), Color("151020"), true, 0.08)
	_build_zone_floors()
	_create_box("NorthWall", Vector3(81.0, 5.2, 0.55), Vector3(0.0, 2.6, -30.25), Color("2b1b43"), true, 0.12)
	_create_box("SouthWall", Vector3(81.0, 5.2, 0.55), Vector3(0.0, 2.6, 30.25), Color("2b1b43"), true, 0.12)
	_create_box("WestWall", Vector3(0.55, 5.2, 61.0), Vector3(-40.25, 2.6, 0.0), Color("2b1b43"), true, 0.12)
	_create_box("EastWallA", Vector3(0.55, 5.2, 27.6), Vector3(40.25, 2.6, -16.2), Color("2b1b43"), true, 0.12)
	_create_box("EastWallB", Vector3(0.55, 5.2, 27.6), Vector3(40.25, 2.6, 16.2), Color("2b1b43"), true, 0.12)
	_build_room_partitions()
	for x: float in [-36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0]:
		_create_column(Vector3(x, 0.0, -29.4))
		_create_column(Vector3(x, 0.0, 29.4))
	_create_central_dais()
	_build_rotunda_accents()
	prop_spawner = MuseumPropSpawner.new()
	add_child(prop_spawner)
	prop_spawner.populate()
	chests = prop_spawner.chests
	_build_void_shrines()
	_build_exit()

func reset_chests() -> void:
	prop_spawner.reset_chests()
	for shrine: VoidShrine in void_shrines:
		shrine.reset()

func _build_zone_floors() -> void:
	_create_box("MainHall", Vector3(80.0, 0.055, 15.0), Vector3(0.0, 0.028, 0.0), Color("332147"), false, 0.1)
	for room: Dictionary in MuseumLayout.ROOMS:
		_create_box(String(room["key"]), room["size"], room["position"], room["color"], false, 0.1)
		_create_room_border(room)
		_create_room_label(room)
	for z: float in [-2.4, 0.0, 2.4]:
		_create_box("MainRunner", Vector3(78.0, 0.035, 1.65), Vector3(0.0, 0.115, z), Color("4b285e"), false, 0.05)
	for x: float in [-36.0, -32.0, -28.0]:
		_create_box("FoyerInlay", Vector3(2.8, 0.04, 0.16), Vector3(x, 0.14, 0.0), Color("e1a441"), false, 0.62)

func _create_room_border(room: Dictionary) -> void:
	var size: Vector3 = room["size"]
	var position: Vector3 = room["position"]
	var color: Color = room["color"].lightened(0.16)
	_create_box("RoomEdge", Vector3(size.x, 0.035, 0.12), position + Vector3(0.0, 0.12, -size.z * 0.5), color, false, 0.38)
	_create_box("RoomEdge", Vector3(size.x, 0.035, 0.12), position + Vector3(0.0, 0.12, size.z * 0.5), color, false, 0.38)
	_create_box("RoomEdge", Vector3(0.12, 0.035, size.z), position + Vector3(-size.x * 0.5, 0.12, 0.0), color, false, 0.38)
	_create_box("RoomEdge", Vector3(0.12, 0.035, size.z), position + Vector3(size.x * 0.5, 0.12, 0.0), color, false, 0.38)

func _create_room_label(room: Dictionary) -> void:
	var label := Label3D.new()
	label.text = tr(room["key"])
	label.position = room["position"] + Vector3(0.0, 0.16, 0.0)
	label.rotation.x = -PI * 0.5
	label.font_size = 72
	label.pixel_size = 0.008
	label.modulate = Color(room["light"], 0.72)
	label.outline_size = 10
	add_child(label)

func _build_room_partitions() -> void:
	_build_horizontal_partition(-8.0)
	_build_horizontal_partition(8.0)
	for x: float in MuseumLayout.VERTICAL_PARTITIONS:
		_build_vertical_partition(x, -30.0, -8.0, -19.0)
		_build_vertical_partition(x, 8.0, 30.0, 19.0)

func _build_horizontal_partition(z: float) -> void:
	var cursor := -40.0
	for door_x: float in MuseumLayout.HORIZONTAL_DOORS:
		_create_wall_segment_x(cursor, door_x - 1.8, z)
		_create_door_posts(Vector3(door_x, 0.0, z), false)
		cursor = door_x + 1.8
	_create_wall_segment_x(cursor, 40.0, z)

func _build_vertical_partition(x: float, start_z: float, end_z: float, door_z: float) -> void:
	_create_wall_segment_z(start_z, door_z - 1.8, x)
	_create_door_posts(Vector3(x, 0.0, door_z), true)
	_create_wall_segment_z(door_z + 1.8, end_z, x)

func _create_wall_segment_x(start_x: float, end_x: float, z: float) -> void:
	if end_x - start_x <= 0.2:
		return
	_create_box("RoomWall", Vector3(end_x - start_x, 1.5, 0.42), Vector3((start_x + end_x) * 0.5, 0.75, z), Color("39254b"), true, 0.16)

func _create_wall_segment_z(start_z: float, end_z: float, x: float) -> void:
	if end_z - start_z <= 0.2:
		return
	_create_box("RoomWall", Vector3(0.42, 1.5, end_z - start_z), Vector3(x, 0.75, (start_z + end_z) * 0.5), Color("39254b"), true, 0.16)

func _create_door_posts(position: Vector3, rotated: bool) -> void:
	var offset := Vector3(1.58, 0.0, 0.0) if not rotated else Vector3(0.0, 0.0, 1.58)
	for side: float in [-1.0, 1.0]:
		_create_box("DoorPost", Vector3(0.34, 2.2, 0.62) if not rotated else Vector3(0.62, 2.2, 0.34), position + offset * side + Vector3.UP * 1.1, Color("6d477f"), true, 0.32)

func _build_rotunda_accents() -> void:
	for radius: float in [2.5, 4.7]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.09
		torus.outer_radius = radius + 0.09
		torus.rings = 48
		torus.ring_segments = 6
		ring.mesh = torus
		ring.position = ROTUNDA_CENTER + Vector3.UP * 0.14
		ring.material_override = _emissive_material(Color("9c45ff"), 1.8)
		add_child(ring)
	for light_position: Vector3 in [Vector3(-5.0, 0.0, 0.0), Vector3(5.0, 0.0, 0.0), Vector3(0.0, 0.0, -5.0), Vector3(0.0, 0.0, 5.0)]:
		var light := OmniLight3D.new()
		light.position = ROTUNDA_CENTER + light_position + Vector3.UP * 1.2
		light.light_color = Color("9c54ff")
		light.light_energy = 1.8
		light.omni_range = 4.2
		add_child(light)
func _create_central_dais() -> void:
	var base := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.4
	cylinder.bottom_radius = 1.65
	cylinder.height = 0.38
	cylinder.radial_segments = 32
	base.mesh = cylinder
	base.position = ROTUNDA_CENTER + Vector3.UP * 0.19
	base.material_override = _material(Color("49306c"), 0.32, 0.38)
	add_child(base)
	var body := StaticBody3D.new()
	body.collision_layer = 4
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.5
	shape.height = 0.38
	collider.shape = shape
	collider.position = ROTUNDA_CENTER + Vector3.UP * 0.19
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

func _build_void_shrines() -> void:
	for placement: Dictionary in MuseumLayout.VOIDS:
		var shrine := VoidShrine.new()
		shrine.configure(placement["reward"])
		shrine.position = placement["position"]
		void_shrines.append(shrine)
		add_child(shrine)

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
	seal.position = Vector3(39.72, 2.0, 0.0)
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
	body.position = Vector3(40.0, 1.8, z_position)
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

class_name HeistArena
extends Node3D

const EXTRACTION_CENTER := Vector3(10.6, 0.0, 0.0)

var extraction_unlocked := false
var pulse := 0.0
var seal_material: StandardMaterial3D
var door_left: AnimatableBody3D
var door_right: AnimatableBody3D

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
	return extraction_unlocked and absf(point.x - EXTRACTION_CENTER.x) < 1.3 and absf(point.z) < 2.2

func safe_artifact_position(point: Vector3) -> bool:
	return absf(point.x) <= 12.8 and absf(point.z) <= 8.8 and point.y > -2.0

func _build_environment() -> void:
	_create_box("Floor", Vector3(25.0, 0.5, 17.0), Vector3(0.0, -0.25, 0.0), Color("18102a"), true, 0.08)
	for x: int in range(-11, 12, 2):
		for z: int in range(-7, 8, 2):
			var tile_color := Color("24183b") if (x + z) % 4 == 0 else Color("201534")
			_create_box("Tile", Vector3(1.88, 0.05, 1.88), Vector3(x, 0.025, z), tile_color, false, 0.02)
	_create_box("NorthWall", Vector3(25.0, 4.2, 0.55), Vector3(0.0, 2.1, -8.25), Color("2b1b43"), true, 0.12)
	_create_box("SouthWall", Vector3(25.0, 4.2, 0.55), Vector3(0.0, 2.1, 8.25), Color("2b1b43"), true, 0.12)
	_create_box("WestWall", Vector3(0.55, 4.2, 17.0), Vector3(-12.25, 2.1, 0.0), Color("2b1b43"), true, 0.12)
	_create_box("EastWallA", Vector3(0.55, 4.2, 5.7), Vector3(12.25, 2.1, -5.65), Color("2b1b43"), true, 0.12)
	_create_box("EastWallB", Vector3(0.55, 4.2, 5.7), Vector3(12.25, 2.1, 5.65), Color("2b1b43"), true, 0.12)
	for x: float in [-8.6, -4.3, 4.3, 8.6]:
		_create_column(Vector3(x, 0.0, -7.3))
		_create_column(Vector3(x, 0.0, 7.3))
	for position: Vector3 in [Vector3(-5.0, 0.6, -3.0), Vector3(-5.0, 0.6, 3.0), Vector3(5.0, 0.6, -3.0), Vector3(5.0, 0.6, 3.0)]:
		_create_box("Display", Vector3(2.2, 1.2, 1.4), position, Color("392653"), true, 0.18)
		_create_glass_case(position + Vector3.UP * 1.25)
	_create_central_dais()
	_build_exit()

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

func _create_glass_case(position: Vector3) -> void:
	var case := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.35, 1.35, 0.85)
	case.mesh = mesh
	case.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.32, 0.76, 1.0, 0.16)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.15
	material.roughness = 0.1
	case.material_override = material
	add_child(case)

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
	seal.position = Vector3(11.72, 2.0, 0.0)
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
	body.position = Vector3(12.0, 1.8, z_position)
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

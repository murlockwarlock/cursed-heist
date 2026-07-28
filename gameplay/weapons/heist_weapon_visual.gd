class_name HeistWeaponVisual
extends Node3D

var weapon_id: StringName
var accent := Color.WHITE
var attack_tween: Tween

func configure(id: StringName, color: Color) -> void:
	weapon_id = id
	accent = color
	position = Vector3(0.5, 1.0, -0.48)
	match weapon_id:
		WeaponCatalog.BATON:
			_build_baton()
		WeaponCatalog.BLUNDERBUSS:
			_build_blunderbuss()
		WeaponCatalog.FOAM_SPRAYER:
			_build_foam_sprayer()

func play_attack() -> void:
	if is_instance_valid(attack_tween):
		attack_tween.kill()
	rotation.x = 0.0
	position.z = -0.48
	attack_tween = create_tween()
	attack_tween.tween_property(self, "rotation:x", -0.55, 0.08)
	attack_tween.parallel().tween_property(self, "position:z", -0.78, 0.08)
	attack_tween.tween_property(self, "rotation:x", 0.0, 0.16)
	attack_tween.parallel().tween_property(self, "position:z", -0.48, 0.16)

func _build_baton() -> void:
	_add_cylinder(Vector3.ZERO, 0.075, 0.9, Color("3a273f"), Vector3(PI * 0.5, 0.0, 0.0))
	_add_cylinder(Vector3(0.0, 0.0, -0.48), 0.14, 0.23, accent, Vector3(PI * 0.5, 0.0, 0.0), true)

func _build_blunderbuss() -> void:
	_add_box(Vector3(0.0, 0.0, 0.12), Vector3(0.18, 0.24, 0.72), Color("5a2e22"))
	_add_cylinder(Vector3(0.0, 0.0, -0.42), 0.12, 0.82, Color("c18a45"), Vector3(PI * 0.5, 0.0, 0.0))
	_add_cylinder(Vector3(0.0, 0.0, -0.88), 0.24, 0.22, accent, Vector3(PI * 0.5, 0.0, 0.0), true)

func _build_foam_sprayer() -> void:
	_add_box(Vector3(0.0, 0.0, 0.0), Vector3(0.34, 0.46, 0.62), Color("325466"))
	_add_cylinder(Vector3(0.0, 0.0, -0.48), 0.1, 0.55, Color("d9edf0"), Vector3(PI * 0.5, 0.0, 0.0))
	_add_sphere(Vector3(0.0, 0.25, 0.12), 0.18, accent, true)

func _add_box(mesh_position: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_mesh(mesh, mesh_position, color)

func _add_cylinder(mesh_position: Vector3, radius: float, height: float, color: Color, mesh_rotation: Vector3, emission := false) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.12
	mesh.height = height
	mesh.radial_segments = 10
	_add_mesh(mesh, mesh_position, color, mesh_rotation, emission)

func _add_sphere(mesh_position: Vector3, radius: float, color: Color, emission := false) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	_add_mesh(mesh, mesh_position, color, Vector3.ZERO, emission)

func _add_mesh(mesh: PrimitiveMesh, mesh_position: Vector3, color: Color, mesh_rotation := Vector3.ZERO, emission := false) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = mesh_position
	instance.rotation = mesh_rotation
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.35
	material.roughness = 0.34
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.4
	instance.material_override = material
	add_child(instance)

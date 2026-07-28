class_name HeistCharacterVisual
extends Node3D

var archetype: StringName
var accent := Color.WHITE
var body_root: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var face_root: Node3D
var accessory_root: Node3D
var base_height := 0.0

func configure(character_id: StringName, team_accent: Color) -> void:
	archetype = character_id
	accent = team_accent
	_build()

func animate(pulse: float, movement: float, emote: StringName, emote_seconds: float) -> void:
	var step := sin(pulse * 12.0) * movement
	left_leg.rotation.x = step * 0.72
	right_leg.rotation.x = -step * 0.72
	left_arm.rotation.x = -step * 0.52
	right_arm.rotation.x = step * 0.52
	body_root.position.y = base_height + absf(sin(pulse * 12.0)) * movement * 0.08
	face_root.rotation.z = sin(pulse * 2.2) * 0.025
	if emote == &"dance" and emote_seconds > 0.0:
		rotation.z = sin(pulse * 15.0) * 0.22
		rotation.y += 0.055
		scale = Vector3.ONE * (1.0 + sin(pulse * 18.0) * 0.05)
		left_arm.rotation.z = -1.25 + sin(pulse * 12.0) * 0.35
		right_arm.rotation.z = 1.25 - sin(pulse * 12.0) * 0.35
	else:
		rotation.z = lerpf(rotation.z, 0.0, 0.18)
		scale = scale.lerp(Vector3.ONE, 0.18)
		left_arm.rotation.z = lerpf(left_arm.rotation.z, 0.0, 0.18)
		right_arm.rotation.z = lerpf(right_arm.rotation.z, 0.0, 0.18)

func _build() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	face_root = Node3D.new()
	add_child(face_root)
	accessory_root = Node3D.new()
	add_child(accessory_root)
	match archetype:
		CharacterCatalog.FOX:
			_build_fox()
		CharacterCatalog.GOLEM:
			_build_golem()
		CharacterCatalog.ILLUSIONIST:
			_build_illusionist()
		CharacterCatalog.ALCHEMIST:
			_build_alchemist()
		_:
			_build_fox()

func _build_fox() -> void:
	base_height = 0.98
	body_root.position.y = base_height
	_add_mesh(_capsule(0.39, 1.05), Color("211a2b"), Vector3.ZERO, body_root)
	_add_mesh(_capsule(0.43, 0.24), accent.darkened(0.08), Vector3(0.0, 0.22, -0.05), body_root, Vector3(0.0, 0.0, PI * 0.5))
	_build_limbs(0.18, 0.58, 0.31, Color("17131d"), 0.24, 0.93)
	_add_mesh(_sphere(0.5, 0.55), Color("241a33"), Vector3(0.0, 1.53, 0.0), face_root)
	_add_cone(Vector3(-0.29, 2.02, 0.0), 0.22, 0.7, Color("2d2040"), -0.1)
	_add_cone(Vector3(0.29, 2.02, 0.0), 0.22, 0.7, Color("2d2040"), 0.1)
	_add_mesh(_sphere(0.38, 0.28), Color("eee9df"), Vector3(0.0, 1.48, -0.47), face_root, Vector3.ZERO, Vector3(1.0, 0.82, 0.32))
	_build_eyes(Vector3(-0.14, 1.54, -0.575), Vector3(0.14, 1.54, -0.575), 0.065, accent.lightened(0.5))
	var tail := _add_mesh(_capsule(0.17, 1.1), accent.darkened(0.12), Vector3(0.46, 0.72, 0.35), accessory_root, Vector3(0.25, 0.0, -0.75))
	tail.scale = Vector3(1.0, 1.0, 0.86)
	_add_mesh(_capsule(0.08, 0.86), accent, Vector3(-0.5, 1.28, 0.13), accessory_root, Vector3(0.15, 0.0, -0.9))
	_add_belt(0.49, 0.86)

func _build_golem() -> void:
	base_height = 0.96
	body_root.position.y = base_height
	_add_mesh(_sphere(0.72, 0.72), Color("393443"), Vector3(0.0, 0.04, 0.0), body_root, Vector3.ZERO, Vector3(1.2, 1.06, 0.86))
	_add_mesh(_box(Vector3(1.18, 0.42, 0.58)), Color("4a4353"), Vector3(0.0, 0.38, 0.0), body_root)
	_build_limbs(0.28, 0.6, 0.52, Color("302c38"), 0.34, 0.84)
	_add_mesh(_sphere(0.55, 0.48), Color("332b40"), Vector3(0.0, 1.48, 0.0), face_root, Vector3.ZERO, Vector3(1.08, 0.9, 0.9))
	_add_mesh(_box(Vector3(0.72, 0.28, 0.16)), Color("15121c"), Vector3(0.0, 1.47, -0.48), face_root)
	_build_eyes(Vector3(-0.2, 1.48, -0.575), Vector3(0.2, 1.48, -0.575), 0.075, accent.lightened(0.38))
	for side: float in [-1.0, 1.0]:
		_add_mesh(_sphere(0.36, 0.32), Color("4c4655"), Vector3(side * 0.72, 1.23, 0.0), accessory_root)
		_add_mesh(_sphere(0.34, 0.31), Color("514a59"), Vector3(side * 0.7, 0.62, -0.02), accessory_root)
	_add_mesh(_torus(0.2, 0.29), Color("b98a45"), Vector3(0.0, 1.02, -0.59), accessory_root, Vector3(PI * 0.5, 0.0, 0.0))
	_add_mesh(_sphere(0.13, 0.13), accent, Vector3(0.0, 1.02, -0.66), accessory_root, Vector3.ZERO, Vector3.ONE, true)
	_add_rune_cracks()

func _build_illusionist() -> void:
	base_height = 1.08
	body_root.position.y = base_height
	_add_mesh(_capsule(0.34, 1.28), Color("17151f"), Vector3.ZERO, body_root, Vector3.ZERO, Vector3(0.9, 1.08, 0.76))
	_build_limbs(0.13, 0.7, 0.22, Color("121018"), 0.22, 1.08)
	_add_mesh(_sphere(0.43, 0.48), Color("282034"), Vector3(0.0, 1.62, 0.0), face_root)
	_add_mesh(_sphere(0.32, 0.35), Color("e9e5df"), Vector3(0.0, 1.59, -0.39), face_root, Vector3.ZERO, Vector3(0.82, 1.08, 0.3))
	_build_eyes(Vector3(-0.12, 1.62, -0.485), Vector3(0.12, 1.62, -0.485), 0.052, accent.lightened(0.52))
	_add_cone(Vector3(0.0, 2.15, 0.04), 0.42, 1.22, Color("322340"), -0.22)
	_add_mesh(_torus(0.42, 0.5), Color("bd8d45"), Vector3(0.0, 1.93, 0.0), accessory_root)
	for side: float in [-1.0, 1.0]:
		var coat_tail := _add_mesh(_box(Vector3(0.3, 0.95, 0.11)), accent.darkened(0.35), Vector3(side * 0.24, 0.58, 0.25), accessory_root, Vector3(0.16 * side, 0.0, 0.08 * side))
		coat_tail.scale.y = 1.15
	_add_mesh(_sphere(0.12, 0.12), accent, Vector3(0.0, 1.13, -0.39), accessory_root, Vector3.ZERO, Vector3.ONE, true)
	_add_belt(0.39, 0.96)

func _build_alchemist() -> void:
	base_height = 0.88
	body_root.position.y = base_height
	_add_mesh(_sphere(0.66, 0.7), Color("211b28"), Vector3(0.0, 0.02, 0.0), body_root, Vector3.ZERO, Vector3(1.12, 1.02, 0.92))
	_build_limbs(0.2, 0.46, 0.38, Color("151219"), 0.3, 0.78)
	_add_mesh(_sphere(0.55, 0.5), Color("2d2238"), Vector3(0.0, 1.42, 0.0), face_root, Vector3.ZERO, Vector3(1.08, 0.94, 0.96))
	_add_mesh(_box(Vector3(0.65, 0.27, 0.16)), Color("15121b"), Vector3(0.0, 1.4, -0.49), face_root)
	for side: float in [-1.0, 1.0]:
		_add_mesh(_torus(0.14, 0.23), Color("bd8d45"), Vector3(side * 0.2, 1.45, -0.57), accessory_root, Vector3(PI * 0.5, 0.0, 0.0))
		_add_mesh(_sphere(0.145, 0.12), accent.lightened(0.38), Vector3(side * 0.2, 1.45, -0.595), accessory_root, Vector3.ZERO, Vector3(1.0, 0.82, 0.2), true)
	_add_mesh(_box(Vector3(0.78, 0.82, 0.28)), Color("5b3d31"), Vector3(0.0, 0.95, 0.47), accessory_root)
	for x: float in [-0.27, 0.0, 0.27]:
		_add_bottle(Vector3(x, 1.48 + absf(x) * 0.25, 0.55), accent.lightened(absf(x) * 0.7))
	_add_belt(0.55, 0.72)

func _build_limbs(radius: float, leg_height: float, arm_offset: float, color: Color, leg_x: float, arm_y: float) -> void:
	left_leg = Node3D.new()
	right_leg = Node3D.new()
	left_arm = Node3D.new()
	right_arm = Node3D.new()
	for limb: Node3D in [left_leg, right_leg, left_arm, right_arm]:
		add_child(limb)
	left_leg.position = Vector3(-leg_x, 0.56, 0.0)
	right_leg.position = Vector3(leg_x, 0.56, 0.0)
	left_arm.position = Vector3(-arm_offset - radius, arm_y, 0.0)
	right_arm.position = Vector3(arm_offset + radius, arm_y, 0.0)
	_add_mesh(_capsule(radius, leg_height), color, Vector3(0.0, -0.24, 0.0), left_leg)
	_add_mesh(_capsule(radius, leg_height), color, Vector3(0.0, -0.24, 0.0), right_leg)
	_add_mesh(_capsule(radius * 0.82, leg_height * 0.82), color.lightened(0.04), Vector3(0.0, -0.2, 0.0), left_arm)
	_add_mesh(_capsule(radius * 0.82, leg_height * 0.82), color.lightened(0.04), Vector3(0.0, -0.2, 0.0), right_arm)

func _build_eyes(left_position: Vector3, right_position: Vector3, radius: float, color: Color) -> void:
	for eye_position: Vector3 in [left_position, right_position]:
		_add_mesh(_sphere(radius, radius * 1.25), color, eye_position, face_root, Vector3.ZERO, Vector3(1.0, 1.0, 0.34), true)

func _add_belt(radius: float, y: float) -> void:
	_add_mesh(_torus(radius, radius + 0.055), Color("b98a45"), Vector3(0.0, y, 0.0), accessory_root)
	_add_mesh(_box(Vector3(0.2, 0.18, 0.09)), accent, Vector3(0.0, y, -radius - 0.04), accessory_root, Vector3.ZERO, Vector3.ONE, true)

func _add_rune_cracks() -> void:
	for offset: Vector3 in [Vector3(-0.38, 1.18, -0.47), Vector3(0.34, 0.78, -0.5), Vector3(0.12, 1.58, -0.48)]:
		_add_mesh(_box(Vector3(0.045, 0.28, 0.025)), accent, offset, accessory_root, Vector3(0.0, 0.0, offset.x * 0.9), Vector3.ONE, true)

func _add_bottle(position: Vector3, color: Color) -> void:
	_add_mesh(_sphere(0.11, 0.15), color, position, accessory_root, Vector3.ZERO, Vector3.ONE, true)
	_add_mesh(_cylinder(0.045, 0.14), Color("b98a45"), position + Vector3.UP * 0.14, accessory_root)

func _add_cone(position: Vector3, radius: float, height: float, color: Color, tilt: float) -> void:
	_add_mesh(_cone(radius, height), color, position, accessory_root, Vector3(0.0, 0.0, tilt))

func _add_mesh(mesh: PrimitiveMesh, color: Color, position: Vector3, parent: Node3D, rotation := Vector3.ZERO, mesh_scale := Vector3.ONE, emission := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.scale = mesh_scale
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	material.metallic = 0.12
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.8
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance

func _sphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height * 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	return mesh

func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 8
	return mesh

func _torus(inner_radius: float, outer_radius: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 20
	mesh.ring_segments = 8
	return mesh

func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _cone(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	return mesh

func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return mesh

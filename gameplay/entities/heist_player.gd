class_name HeistPlayer
extends CharacterBody3D

signal interaction_requested(player: HeistPlayer)
signal shove_requested(player: HeistPlayer)
signal emote_started(player: HeistPlayer, emote: StringName)
signal curses_changed(player: HeistPlayer)

const KEY_PROFILES: Array[Dictionary] = [
	{"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D, "interact": KEY_E, "shove": KEY_Q, "emote": KEY_F},
	{"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "interact": KEY_ENTER, "shove": KEY_SHIFT, "emote": KEY_CTRL},
	{"up": KEY_I, "down": KEY_K, "left": KEY_J, "right": KEY_L, "interact": KEY_O, "shove": KEY_U, "emote": KEY_P},
	{"up": KEY_C, "down": KEY_X, "left": KEY_Z, "right": KEY_V, "interact": KEY_B, "shove": KEY_N, "emote": KEY_M}
]

var player_index := 0
var player_name := ""
var body_color := Color.WHITE
var joy_device := -1
var score := 0.0
var carried_artifact: CursedArtifact
var active_curses: Dictionary[StringName, float] = {}
var facing := Vector3.FORWARD
var stun_seconds := 0.0
var shove_cooldown := 0.0
var emote_seconds := 0.0
var emote_name: StringName = &""
var dance_grace := 6.0
var pulse := 0.0
var is_bot := false
var bot_target := Vector3.ZERO
var movement_basis := Basis.IDENTITY
var visual: Node3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var body_mesh: MeshInstance3D
var _previous_actions := {"interact": false, "shove": false, "emote": false, "jump": false}

func _ready() -> void:
	collision_layer = 1
	collision_mask = 5
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(48.0)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.72
	collider.shape = shape
	collider.position.y = 0.86
	add_child(collider)
	_build_visual()

func configure(index: int, assigned_color: Color, controller: int) -> void:
	player_index = index
	player_name = "P%d" % (index + 1)
	body_color = assigned_color
	joy_device = controller
	is_bot = index > 0

func _process(delta: float) -> void:
	pulse += delta
	stun_seconds = maxf(stun_seconds - delta, 0.0)
	shove_cooldown = maxf(shove_cooldown - delta, 0.0)
	emote_seconds = maxf(emote_seconds - delta, 0.0)
	dance_grace = maxf(dance_grace - delta, 0.0)
	_tick_curses(delta)
	_animate_visual()

func _physics_process(delta: float) -> void:
	var input_vector := _movement_input()
	if stun_seconds > 0.0:
		input_vector = Vector3.ZERO
	if emote_name == &"dance" and emote_seconds > 0.0:
		input_vector *= 0.32
	if input_vector.length_squared() > 0.01:
		facing = input_vector.normalized()
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), delta * 12.0)
	var speed_multiplier := _speed_multiplier()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(input_vector * GameConstants.PLAYER_SPEED * speed_multiplier, GameConstants.PLAYER_ACCELERATION * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	global_position.x = clampf(global_position.x, -GameConstants.ARENA_HALF_SIZE.x + 0.8, GameConstants.ARENA_HALF_SIZE.x - 0.8)
	global_position.z = clampf(global_position.z, -GameConstants.ARENA_HALF_SIZE.y + 0.8, GameConstants.ARENA_HALF_SIZE.y - 0.8)
	if not is_bot:
		_poll_actions()

func add_curse(id: StringName, duration: float) -> void:
	active_curses[id] = maxf(active_curses.get(id, 0.0), duration)
	curses_changed.emit(self)

func clear_curses() -> void:
	active_curses.clear()
	curses_changed.emit(self)

func has_curse(id: StringName) -> bool:
	return active_curses.has(id)

func apply_shove(direction: Vector3) -> void:
	var horizontal := Vector3(direction.x, 0.0, direction.z).normalized()
	velocity += horizontal * GameConstants.SHOVE_FORCE + Vector3.UP * 2.8
	stun_seconds = 0.22

func begin_emote() -> void:
	emote_name = &"dance" if emote_name != &"dance" else &"taunt"
	emote_seconds = 1.4
	dance_grace = 7.0
	emote_started.emit(self, emote_name)

func set_bot_target(target: Vector3) -> void:
	bot_target = target

func trigger_bot_interaction() -> void:
	interaction_requested.emit(self)

func trigger_bot_shove() -> void:
	if shove_cooldown <= 0.0:
		shove_cooldown = 0.7
		shove_requested.emit(self)

func _movement_input() -> Vector3:
	if is_bot:
		var offset := bot_target - global_position
		offset.y = 0.0
		return offset.normalized() if offset.length() > 0.45 else Vector3.ZERO
	var profile: Dictionary = KEY_PROFILES[player_index]
	var keyboard := Vector2(
		float(Input.is_physical_key_pressed(profile["right"])) - float(Input.is_physical_key_pressed(profile["left"])),
		float(Input.is_physical_key_pressed(profile["down"])) - float(Input.is_physical_key_pressed(profile["up"]))
	)
	var controller := Vector2.ZERO
	if joy_device >= 0:
		controller = Vector2(Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_X), Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_Y))
		if controller.length() < 0.2:
			controller = Vector2.ZERO
	var combined := (keyboard + controller).limit_length(1.0)
	var camera_forward := -movement_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := movement_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	return (camera_right * combined.x + camera_forward * -combined.y).limit_length(1.0)

func _poll_actions() -> void:
	var profile: Dictionary = KEY_PROFILES[player_index]
	var states := {
		"interact": Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(profile["interact"]) or _joy_pressed(JOY_BUTTON_A),
		"shove": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(profile["shove"]) or _joy_pressed(JOY_BUTTON_X),
		"emote": Input.is_physical_key_pressed(profile["emote"]) or _joy_pressed(JOY_BUTTON_Y),
		"jump": Input.is_physical_key_pressed(KEY_SPACE) or _joy_pressed(JOY_BUTTON_B)
	}
	if states["interact"] and not _previous_actions["interact"]:
		interaction_requested.emit(self)
	if states["shove"] and not _previous_actions["shove"] and shove_cooldown <= 0.0:
		shove_cooldown = 0.7
		shove_requested.emit(self)
	if states["emote"] and not _previous_actions["emote"]:
		begin_emote()
	if states["jump"] and not _previous_actions["jump"] and is_on_floor() and stun_seconds <= 0.0:
		velocity.y = 8.2
	_previous_actions = states

func _joy_pressed(button: JoyButton) -> bool:
	return joy_device >= 0 and Input.is_joy_button_pressed(joy_device, button)

func _tick_curses(delta: float) -> void:
	var expired: Array[StringName] = []
	for id: StringName in active_curses:
		active_curses[id] -= delta
		if active_curses[id] <= 0.0:
			expired.append(id)
	for id: StringName in expired:
		active_curses.erase(id)
	if not expired.is_empty():
		curses_changed.emit(self)

func _speed_multiplier() -> float:
	var multiplier := 1.0
	if has_curse(CurseCatalog.HEAVY):
		multiplier *= 0.72
	if has_curse(CurseCatalog.GREED):
		multiplier *= clampf(1.0 + score * 0.007, 1.0, 1.32)
	if has_curse(CurseCatalog.DANCE_FEVER) and dance_grace <= 0.0:
		multiplier *= 0.48
	return multiplier

func _build_visual() -> void:
	visual = Node3D.new()
	add_child(visual)
	body_mesh = _mesh_instance(_capsule(0.54, 1.2), body_color.darkened(0.12), Vector3(0.0, 0.93, 0.0))
	visual.add_child(body_mesh)
	var hood := _mesh_instance(_sphere(0.66, 0.78), body_color, Vector3(0.0, 1.55, 0.0))
	visual.add_child(hood)
	var face := _mesh_instance(_sphere(0.49, 0.42), Color("151020"), Vector3(0.0, 1.54, -0.43))
	face.scale.z = 0.28
	visual.add_child(face)
	for eye_x: float in [-0.18, 0.18]:
		var eye := _mesh_instance(_sphere(0.09, 0.12), Color("fff8de"), Vector3(eye_x, 1.6, -0.56))
		eye.scale.z = 0.35
		visual.add_child(eye)
	left_leg = _mesh_instance(_capsule(0.17, 0.55), body_color.darkened(0.32), Vector3(-0.25, 0.3, 0.0))
	right_leg = _mesh_instance(_capsule(0.17, 0.55), body_color.darkened(0.32), Vector3(0.25, 0.3, 0.0))
	visual.add_child(left_leg)
	visual.add_child(right_leg)
	var rim := _mesh_instance(_torus(0.53, 0.62), Color("fff0bf"), Vector3(0.0, 1.54, -0.07))
	rim.rotation.x = PI * 0.5
	visual.add_child(rim)

func _animate_visual() -> void:
	var movement := clampf(Vector2(velocity.x, velocity.z).length() / GameConstants.PLAYER_SPEED, 0.0, 1.0)
	var step := sin(pulse * 12.0) * movement
	left_leg.rotation.x = step * 0.65
	right_leg.rotation.x = -step * 0.65
	body_mesh.position.y = 0.93 + abs(sin(pulse * 12.0)) * movement * 0.08
	if emote_name == &"dance" and emote_seconds > 0.0:
		visual.rotation.z = sin(pulse * 15.0) * 0.22
		visual.scale = Vector3.ONE * (1.0 + sin(pulse * 18.0) * 0.05)
	else:
		visual.rotation.z = lerpf(visual.rotation.z, 0.0, 0.18)
		visual.scale = visual.scale.lerp(Vector3.ONE, 0.18)

func _mesh_instance(mesh: PrimitiveMesh, color: Color, position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	material.metallic = 0.08
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance

func _sphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return mesh

func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.rings = 8
	return mesh

func _torus(inner_radius: float, outer_radius: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 24
	mesh.ring_segments = 8
	return mesh

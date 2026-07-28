class_name HeistPlayer
extends CharacterBody3D

const PlayerWorldMarkerScript = preload("res://ui/player_world_marker.gd")
signal interaction_requested(player: HeistPlayer)
signal shove_requested(player: HeistPlayer)
signal emote_started(player: HeistPlayer, emote: StringName)
signal curses_changed(player: HeistPlayer)
signal health_changed(player: HeistPlayer)
signal defeated(player: HeistPlayer)
signal weapon_changed(player: HeistPlayer)

const KEY_PROFILES: Array[Dictionary] = [
	{"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D, "interact": KEY_E, "shove": KEY_Q, "emote": KEY_F},
	{"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "interact": KEY_ENTER, "shove": KEY_SHIFT, "emote": KEY_CTRL},
	{"up": KEY_I, "down": KEY_K, "left": KEY_J, "right": KEY_L, "interact": KEY_O, "shove": KEY_U, "emote": KEY_P},
	{"up": KEY_C, "down": KEY_X, "left": KEY_Z, "right": KEY_V, "interact": KEY_B, "shove": KEY_N, "emote": KEY_M}
]
const HIT_CONTROL_FACTOR := 0.28
const HEAVY_SPEED_FACTOR := 0.72
const DANCE_FEVER_SPEED_FACTOR := 0.58
const FOAM_SPEED_FACTOR := 0.64

var player_index := 0
var player_name := ""
var character_id: StringName = CharacterCatalog.FOX
var body_color := Color.WHITE
var joy_device := -1
var score := 0.0
var health := GameConstants.MAX_HEALTH
var is_ghost := false
var weapon_id: StringName = WeaponCatalog.BATON
var carried_artifact: CursedArtifact
var active_curses: Dictionary[StringName, float] = {}
var facing := Vector3.FORWARD
var aim_direction := Vector3.FORWARD
var stun_seconds := 0.0
var shove_cooldown := 0.0
var emote_seconds := 0.0
var emote_name: StringName = &""
var dance_grace := 6.0
var pulse := 0.0
var slowed_seconds := 0.0
var respawn_seconds := 0.0
var spawn_protection_seconds := 0.0
var is_bot := false
var bot_target := Vector3.ZERO
var movement_basis := Basis.IDENTITY
var visual: HeistCharacterVisual
var weapon_visual: HeistWeaponVisual
var world_marker: Node3D
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
	world_marker = PlayerWorldMarkerScript.new()
	world_marker.configure(self)
	add_child(world_marker)

func configure(index: int, assigned_color: Color, controller: int, assigned_character: StringName = CharacterCatalog.FOX) -> void:
	player_index = index
	player_name = "P%d" % (index + 1)
	body_color = assigned_color
	joy_device = controller
	character_id = assigned_character
	is_bot = index > 0

func assign_character(assigned_character: StringName) -> void:
	character_id = assigned_character
	if is_instance_valid(visual):
		visual.free()
		_build_visual()

func assign_weapon(assigned_weapon: StringName) -> void:
	weapon_id = assigned_weapon
	if is_instance_valid(weapon_visual):
		weapon_visual.free()
	_build_weapon_visual()
	weapon_changed.emit(self)

func cycle_weapon() -> void:
	assign_weapon(WeaponCatalog.next(weapon_id))

func _process(delta: float) -> void:
	pulse += delta
	stun_seconds = maxf(stun_seconds - delta, 0.0)
	shove_cooldown = maxf(shove_cooldown - delta, 0.0)
	emote_seconds = maxf(emote_seconds - delta, 0.0)
	dance_grace = maxf(dance_grace - delta, 0.0)
	slowed_seconds = maxf(slowed_seconds - delta, 0.0)
	spawn_protection_seconds = maxf(spawn_protection_seconds - delta, 0.0)
	_tick_curses(delta)
	_animate_visual()

func _physics_process(delta: float) -> void:
	if not is_bot:
		_poll_actions()
	var input_vector := _movement_input()
	if is_ghost:
		velocity = input_vector * GameConstants.PLAYER_SPEED * 1.18
		move_and_slide()
		global_position.y = 0.45 + sin(pulse * 2.6) * 0.12
		_clamp_to_arena()
		return
	if stun_seconds > 0.0:
		input_vector *= HIT_CONTROL_FACTOR
	if emote_name == &"dance" and emote_seconds > 0.0:
		input_vector *= 0.32
	if input_vector.length_squared() > 0.01:
		facing = input_vector.normalized()
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), delta * 12.0)
	var speed_multiplier := movement_speed_multiplier()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(input_vector * GameConstants.PLAYER_SPEED * speed_multiplier, GameConstants.PLAYER_ACCELERATION * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif velocity.y <= 0.0:
		velocity.y = -0.5
	move_and_slide()
	_clamp_to_arena()

func take_damage(amount: float) -> void:
	if is_ghost or spawn_protection_seconds > 0.0 or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(self)
	if health <= 0.0:
		is_ghost = true
		collision_layer = 0
		collision_mask = 0
		stun_seconds = 0.0
		visual.set_ghost_mode(true)
		defeated.emit(self)

func heal(amount: float) -> void:
	if is_ghost or amount <= 0.0:
		return
	health = minf(health + amount, GameConstants.MAX_HEALTH)
	health_changed.emit(self)

func revive() -> void:
	health = GameConstants.MAX_HEALTH
	is_ghost = false
	respawn_seconds = 0.0
	collision_layer = 1
	collision_mask = 5
	if is_instance_valid(visual):
		visual.set_ghost_mode(false)
	health_changed.emit(self)

func revive_at(point: Vector3) -> void:
	global_position = point
	velocity = Vector3.ZERO
	stun_seconds = 0.0
	slowed_seconds = 0.0
	spawn_protection_seconds = GameConstants.SPAWN_PROTECTION_SECONDS
	clear_curses()
	revive()

func add_curse(id: StringName, duration: float) -> void:
	active_curses[id] = maxf(active_curses.get(id, 0.0), duration)
	curses_changed.emit(self)

func clear_curses() -> void:
	active_curses.clear()
	curses_changed.emit(self)

func has_curse(id: StringName) -> bool:
	return active_curses.has(id)

func apply_shove(direction: Vector3) -> void:
	apply_impact(direction, GameConstants.SHOVE_FORCE)

func apply_impact(direction: Vector3, force: float) -> void:
	var horizontal := Vector3(direction.x, 0.0, direction.z).normalized()
	velocity += horizontal * force + Vector3.UP * minf(force * 0.32, 3.8)
	stun_seconds = 0.14

func apply_slow(seconds: float) -> void:
	slowed_seconds = maxf(slowed_seconds, seconds)

func play_weapon_attack() -> void:
	if is_instance_valid(weapon_visual):
		weapon_visual.play_attack()

func begin_emote() -> void:
	emote_name = &"dance" if emote_name != &"dance" else &"taunt"
	emote_seconds = 1.4
	dance_grace = 7.0
	emote_started.emit(self, emote_name)

func try_jump() -> bool:
	if not is_on_floor() or stun_seconds > 0.0 or is_ghost:
		return false
	velocity.y = 8.2
	return true

func set_bot_target(target: Vector3) -> void:
	bot_target = target

func trigger_bot_interaction() -> void:
	if is_ghost:
		return
	interaction_requested.emit(self)

func trigger_bot_shove() -> void:
	if not is_ghost and shove_cooldown <= 0.0:
		shove_cooldown = WeaponCatalog.definition(weapon_id)["cooldown"]
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
	if states["interact"] and not _previous_actions["interact"] and not is_ghost:
		interaction_requested.emit(self)
	if states["shove"] and not _previous_actions["shove"] and shove_cooldown <= 0.0 and not is_ghost:
		shove_cooldown = WeaponCatalog.definition(weapon_id)["cooldown"]
		shove_requested.emit(self)
	if states["emote"] and not _previous_actions["emote"]:
		begin_emote()
	if states["jump"] and not _previous_actions["jump"] and is_on_floor() and stun_seconds <= 0.0 and not is_ghost:
		try_jump()
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

func movement_speed_multiplier() -> float:
	var slow_factor := 1.0
	if has_curse(CurseCatalog.HEAVY):
		slow_factor = minf(slow_factor, HEAVY_SPEED_FACTOR)
	if has_curse(CurseCatalog.DANCE_FEVER) and dance_grace <= 0.0:
		slow_factor = minf(slow_factor, DANCE_FEVER_SPEED_FACTOR)
	if slowed_seconds > 0.0:
		slow_factor = minf(slow_factor, FOAM_SPEED_FACTOR)
	var speed_bonus := clampf(1.0 + score * 0.007, 1.0, 1.32) if has_curse(CurseCatalog.GREED) else 1.0
	return slow_factor * speed_bonus

func _build_visual() -> void:
	visual = HeistCharacterVisual.new()
	visual.configure(character_id, body_color)
	add_child(visual)
	_build_weapon_visual()

func _build_weapon_visual() -> void:
	if not is_instance_valid(visual):
		return
	weapon_visual = HeistWeaponVisual.new()
	weapon_visual.configure(weapon_id, body_color)
	visual.add_child(weapon_visual)

func set_local_camera_hidden(hidden: bool) -> void:
	if not is_instance_valid(visual):
		return
	for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		mesh_instance.set_layer_mask_value(1, not hidden)
		mesh_instance.set_layer_mask_value(2, hidden)

func _animate_visual() -> void:
	var movement := clampf(Vector2(velocity.x, velocity.z).length() / GameConstants.PLAYER_SPEED, 0.0, 1.0)
	visual.animate(pulse, movement, emote_name, emote_seconds)

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, -GameConstants.ARENA_HALF_SIZE.x + 0.8, GameConstants.ARENA_HALF_SIZE.x - 0.8)
	global_position.z = clampf(global_position.z, -GameConstants.ARENA_HALF_SIZE.y + 0.8, GameConstants.ARENA_HALF_SIZE.y - 0.8)

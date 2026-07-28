class_name HeistPlayer
extends CharacterBody2D

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
var facing := Vector2.DOWN
var stun_seconds := 0.0
var shove_cooldown := 0.0
var emote_seconds := 0.0
var emote_name: StringName = &""
var dance_grace := 6.0
var pulse := 0.0
var _previous_actions := {"interact": false, "shove": false, "emote": false}

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = GameConstants.PLAYER_RADIUS
	collider.shape = shape
	add_child(collider)
	queue_redraw()

func configure(index: int, assigned_color: Color, controller: int) -> void:
	player_index = index
	player_name = "P%d" % (index + 1)
	body_color = assigned_color
	joy_device = controller
	z_index = 10

func _process(delta: float) -> void:
	pulse += delta
	stun_seconds = maxf(stun_seconds - delta, 0.0)
	shove_cooldown = maxf(shove_cooldown - delta, 0.0)
	emote_seconds = maxf(emote_seconds - delta, 0.0)
	dance_grace = maxf(dance_grace - delta, 0.0)
	_tick_curses(delta)
	queue_redraw()

func _physics_process(delta: float) -> void:
	var input_vector := _movement_input()
	if stun_seconds > 0.0:
		input_vector = Vector2.ZERO
	if emote_name == &"dance" and emote_seconds > 0.0:
		input_vector *= 0.32
	if input_vector.length_squared() > 0.01:
		facing = input_vector.normalized()
	var speed_multiplier := _speed_multiplier()
	velocity = velocity.move_toward(input_vector * GameConstants.PLAYER_SPEED * speed_multiplier, GameConstants.PLAYER_ACCELERATION * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, GameConstants.ARENA_RECT.position.x + GameConstants.PLAYER_RADIUS, GameConstants.ARENA_RECT.end.x - GameConstants.PLAYER_RADIUS)
	global_position.y = clampf(global_position.y, GameConstants.ARENA_RECT.position.y + GameConstants.PLAYER_RADIUS, GameConstants.ARENA_RECT.end.y - GameConstants.PLAYER_RADIUS)
	_poll_actions()

func add_curse(id: StringName, duration: float) -> void:
	active_curses[id] = maxf(active_curses.get(id, 0.0), duration)
	curses_changed.emit(self)

func clear_curses() -> void:
	active_curses.clear()
	curses_changed.emit(self)

func has_curse(id: StringName) -> bool:
	return active_curses.has(id)

func apply_shove(direction: Vector2) -> void:
	velocity += direction.normalized() * GameConstants.SHOVE_FORCE
	stun_seconds = 0.22

func begin_emote() -> void:
	emote_name = &"dance" if emote_name != &"dance" else &"taunt"
	emote_seconds = 1.4
	dance_grace = 7.0
	emote_started.emit(self, emote_name)

func _movement_input() -> Vector2:
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
	return (keyboard + controller).limit_length(1.0)

func _poll_actions() -> void:
	var profile: Dictionary = KEY_PROFILES[player_index]
	var states := {
		"interact": Input.is_physical_key_pressed(profile["interact"]) or _joy_pressed(JOY_BUTTON_A),
		"shove": Input.is_physical_key_pressed(profile["shove"]) or _joy_pressed(JOY_BUTTON_X),
		"emote": Input.is_physical_key_pressed(profile["emote"]) or _joy_pressed(JOY_BUTTON_Y)
	}
	if states["interact"] and not _previous_actions["interact"]:
		interaction_requested.emit(self)
	if states["shove"] and not _previous_actions["shove"] and shove_cooldown <= 0.0:
		shove_cooldown = 0.7
		shove_requested.emit(self)
	if states["emote"] and not _previous_actions["emote"]:
		begin_emote()
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

func _draw() -> void:
	var bob := sin(pulse * 8.0) * minf(velocity.length() / 220.0, 1.0) * 2.5
	var dance_rotation := sin(pulse * 16.0) * 0.22 if emote_name == &"dance" and emote_seconds > 0.0 else 0.0
	draw_set_transform(Vector2(0.0, bob), dance_rotation)
	draw_circle(Vector2(0.0, 5.0), 24.0, Color(0.02, 0.015, 0.04, 0.45))
	draw_circle(Vector2.ZERO, GameConstants.PLAYER_RADIUS, body_color.darkened(0.18))
	draw_circle(Vector2(0.0, -3.0), 18.5, body_color)
	draw_arc(Vector2.ZERO, GameConstants.PLAYER_RADIUS, 0.0, TAU, 32, Color("f8f1ff"), 3.0)
	draw_circle(Vector2(-7.0, -6.0), 3.3, Color("171125"))
	draw_circle(Vector2(7.0, -6.0), 3.3, Color("171125"))
	var mouth_width := 7.0 if emote_name == &"taunt" and emote_seconds > 0.0 else 4.0
	draw_line(Vector2(-mouth_width, 6.0), Vector2(mouth_width, 6.0), Color("171125"), 2.5, true)
	draw_set_transform(Vector2.ZERO, 0.0)
	draw_string(ThemeDB.fallback_font, Vector2(-13.0, -31.0), player_name, HORIZONTAL_ALIGNMENT_CENTER, 26.0, 13, Color.WHITE)
	var curse_x := -float(active_curses.size() - 1) * 7.0
	for id: StringName in active_curses:
		draw_circle(Vector2(curse_x, -44.0), 5.0, CurseCatalog.color(id))
		curse_x += 14.0
	if emote_seconds > 0.0:
		var symbol := "♪" if emote_name == &"dance" else "!"
		draw_string(ThemeDB.fallback_font, Vector2(24.0, -24.0), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color("ffd447"))

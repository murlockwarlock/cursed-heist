class_name HeistCamera
extends Node3D

var target: HeistPlayer
var camera: Camera3D
var weapon_view: HeistWeaponVisual
var yaw := 0.0
var pitch := 0.0
var sensitivity := 0.0023
var bob_phase := 0.0
var hidden_visual_instance_id := 0

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 76.0
	camera.near = 0.04
	camera.far = 95.0
	camera.set_cull_mask_value(2, false)
	add_child(camera)
	target.weapon_changed.connect(_rebuild_weapon_view)
	target.shove_requested.connect(_on_shove_requested)
	_rebuild_weapon_view(target)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity, -1.38, 1.28)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if is_instance_valid(target.visual) and hidden_visual_instance_id != target.visual.get_instance_id():
		target.set_local_camera_hidden(true)
		hidden_visual_instance_id = target.visual.get_instance_id()
	var horizontal_speed := Vector2(target.velocity.x, target.velocity.z).length()
	bob_phase += delta * horizontal_speed * 1.45
	var bob_strength := clampf(horizontal_speed / GameConstants.PLAYER_SPEED, 0.0, 1.0)
	var bob := Vector3(cos(bob_phase * 0.5) * 0.018, absf(sin(bob_phase)) * 0.028, 0.0) * bob_strength
	global_position = target.global_position + Vector3.UP * 1.55 + Basis(Vector3.UP, yaw) * bob
	rotation.y = yaw
	camera.rotation.x = pitch
	target.movement_basis = Basis(Vector3.UP, yaw)
	target.aim_direction = -camera.global_transform.basis.z.normalized()
	if is_instance_valid(weapon_view):
		weapon_view.rotation.z = lerpf(weapon_view.rotation.z, -target.velocity.dot(global_transform.basis.x) * 0.008, delta * 8.0)

func _rebuild_weapon_view(_player: HeistPlayer) -> void:
	if is_instance_valid(weapon_view):
		weapon_view.queue_free()
	weapon_view = HeistWeaponVisual.new()
	weapon_view.configure(target.weapon_id, target.body_color, true)
	camera.add_child(weapon_view)

func _on_shove_requested(_player: HeistPlayer) -> void:
	if is_instance_valid(weapon_view):
		weapon_view.play_attack()

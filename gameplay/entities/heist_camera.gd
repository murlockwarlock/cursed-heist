class_name HeistCamera
extends Node3D

var target: HeistPlayer
var camera: Camera3D
var yaw := 0.0
var pitch := -0.58
var distance := 10.5
var sensitivity := 0.0026

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 54.0
	camera.near = 0.12
	camera.far = 140.0
	add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity, -1.08, -0.18)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var focus := target.global_position + Vector3.UP * 1.0
	global_position = global_position.lerp(focus, 1.0 - exp(-delta * 6.5))
	var orbit := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var desired := global_position + orbit * Vector3(0.0, 0.0, distance)
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.8, desired, 4)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		desired = result["position"] + result["normal"] * 0.35
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-delta * 9.0))
	camera.look_at(focus, Vector3.UP)
	target.movement_basis = Basis(Vector3.UP, yaw)
	target.aim_direction = -target.movement_basis.z

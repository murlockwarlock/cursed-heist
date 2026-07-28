class_name CursedArtifact
extends RigidBody2D

signal carrier_changed(previous: HeistPlayer, current: HeistPlayer)

var carrier: HeistPlayer
var pickup_lock := 0.0
var pulse := 0.0
var heat := 0.0

func _ready() -> void:
	gravity_scale = 0.0
	linear_damp = 3.4
	angular_damp = 4.2
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	can_sleep = false
	collision_layer = 2
	collision_mask = 4
	z_index = 12
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 17.0
	collider.shape = shape
	add_child(collider)

func _process(delta: float) -> void:
	pulse += delta
	pickup_lock = maxf(pickup_lock - delta, 0.0)
	if is_instance_valid(carrier):
		global_position = carrier.global_position + carrier.facing * 31.0 + Vector2(0.0, -5.0)
	queue_redraw()

func pick_up(player: HeistPlayer) -> bool:
	if pickup_lock > 0.0 or is_instance_valid(carrier):
		return false
	var previous := carrier
	carrier = player
	player.carried_artifact = self
	freeze = true
	linear_velocity = Vector2.ZERO
	carrier_changed.emit(previous, carrier)
	return true

func drop(throw_velocity: Vector2) -> void:
	if not is_instance_valid(carrier):
		return
	var previous := carrier
	carrier.carried_artifact = null
	carrier = null
	freeze = false
	pickup_lock = 0.45
	linear_velocity = throw_velocity
	carrier_changed.emit(previous, null)

func reset_to(position: Vector2) -> void:
	if is_instance_valid(carrier):
		carrier.carried_artifact = null
	carrier = null
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = position
	pickup_lock = 0.5

func _draw() -> void:
	var glow := 22.0 + sin(pulse * 5.0) * 3.0
	var hot_color := Color("ff493d")
	var core_color := Color("7d3cff").lerp(hot_color, heat)
	draw_circle(Vector2.ZERO, glow + heat * 10.0, Color(core_color, 0.18 + heat * 0.2))
	draw_circle(Vector2.ZERO, 17.0 + sin(pulse * 18.0) * heat * 2.0, core_color)
	draw_circle(Vector2(-4.0, -5.0), 8.0, Color("ffc942"))
	draw_circle(Vector2(-6.0, -7.0), 2.2, Color.WHITE)
	draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color("fff2ad"), 2.5)

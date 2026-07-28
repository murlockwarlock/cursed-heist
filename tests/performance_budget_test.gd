extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame: int in range(12):
		await physics_frame
	var meshes := game.find_children("*", "MeshInstance3D", true, false).size()
	var lights := game.find_children("*", "Light3D", true, false)
	var shadow_lights := 0
	for light: Light3D in lights:
		if light.shadow_enabled:
			shadow_lights += 1
	var collision_shapes := game.find_children("*", "CollisionShape3D", true, false).size()
	print("Performance sample: %d meshes, %d lights, %d shadows, %d colliders" % [meshes, lights.size(), shadow_lights, collision_shapes])
	if meshes > 420:
		await _fail("Mesh instance budget exceeded: %d" % meshes)
		return
	if lights.size() > 22 or shadow_lights > 3:
		await _fail("Dynamic light budget exceeded: %d lights, %d shadows" % [lights.size(), shadow_lights])
		return
	if collision_shapes > 170:
		await _fail("Collision shape budget exceeded: %d" % collision_shapes)
		return
	print("Performance budget: %d meshes, %d lights, %d shadows, %d colliders" % [meshes, lights.size(), shadow_lights, collision_shapes])
	game.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	game.queue_free()
	await process_frame
	quit(1)

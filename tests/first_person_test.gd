extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame: int in range(12):
		await physics_frame
	var player: HeistPlayer = game.players[0]
	var camera: Camera3D = game.camera_rig.camera
	if camera.global_position.distance_to(player.global_position) > 1.8:
		await _fail("Camera is not attached to first-person eye position")
		return
	if camera.get_cull_mask_value(2):
		await _fail("First-person camera renders the local body layer")
		return
	if not is_instance_valid(game.camera_rig.weapon_view):
		await _fail("First-person weapon view was not created")
		return
	var hidden_meshes := 0
	for node: Node in player.visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.get_layer_mask_value(2) and not mesh.get_layer_mask_value(1):
			hidden_meshes += 1
	if hidden_meshes == 0:
		await _fail("Local character meshes were not isolated from the camera")
		return
	game.reset_round()
	for frame: int in range(4):
		await physics_frame
	hidden_meshes = 0
	for node: Node in player.visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.get_layer_mask_value(2) and not mesh.get_layer_mask_value(1):
			hidden_meshes += 1
	if hidden_meshes == 0:
		await _fail("Local character became visible after round reset")
		return
	print("First-person camera: local body isolated, weapon view active")
	game.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	game.queue_free()
	await process_frame
	quit(1)

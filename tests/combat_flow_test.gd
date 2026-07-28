extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame: int in range(8):
		await physics_frame
	game.audio.streams.clear()
	var player: HeistPlayer = game.players[0]
	var spawn_before := player.global_position
	game.artifact.global_position = player.global_position + Vector3.FORWARD
	if not game.artifact.pick_up(player):
		push_error("Artifact pickup failed")
		game.queue_free()
		await process_frame
		quit(1)
		return
	player.take_damage(GameConstants.MAX_HEALTH)
	await process_frame
	if not player.is_ghost or game.artifact.carrier == player:
		push_error("Defeat did not enter ghost mode or release artifact")
		game.queue_free()
		await process_frame
		quit(1)
		return
	player.respawn_seconds = 0.04
	for frame: int in range(8):
		await physics_frame
	if player.is_ghost or player.health != GameConstants.MAX_HEALTH or player.global_position == spawn_before:
		push_error("Timed respawn did not restore the player at a new spawn")
		game.queue_free()
		await process_frame
		quit(1)
		return
	if player.spawn_protection_seconds <= 0.0:
		push_error("Respawn did not grant temporary protection")
		game.queue_free()
		await process_frame
		quit(1)
		return
	print("Combat flow: pickup, defeat, ghost, safe respawn")
	for frame: int in range(20):
		await physics_frame
	game.audio.stop_all()
	for frame: int in range(2):
		await process_frame
	game.queue_free()
	await process_frame
	quit()

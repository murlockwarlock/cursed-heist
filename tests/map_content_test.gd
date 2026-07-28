extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame: int in range(8):
		await physics_frame
	if game.arena.chests.size() != MuseumLayout.CHESTS.size():
		await _fail("Chest layout did not spawn completely")
		return
	if game.arena.extraction_unlocked or game.arena.seal_visual.visible:
		await _fail("Extraction was visually revealed before unlock")
		return
	game.arena.set_extraction_unlocked(true)
	if not game.arena.seal_visual.visible:
		await _fail("Extraction seal did not appear after unlock")
		return
	game.arena.set_extraction_unlocked(false)
	var player: HeistPlayer = game.players[0]
	var chest: LootChest = game.arena.chests[0]
	player.take_damage(40.0)
	var damaged_health := player.health
	player.global_position = chest.global_position + Vector3(0.0, 0.0, 1.3)
	chest.interact(player)
	await process_frame
	if not chest.opened or player.health <= damaged_health or player.score < 4.0:
		await _fail("Chest interaction did not grant its reward")
		return
	game.reset_round()
	if chest.opened:
		await _fail("Chest state did not reset with the round")
		return
	game.bot_director.enabled = false
	var shrine: VoidShrine = game.arena.void_shrines[0]
	player.global_position = shrine.global_position + Vector3(0.0, 0.0, 1.4)
	var time_before: float = game.round_director.time_left
	shrine.begin_activation(player)
	for frame: int in range(170):
		await physics_frame
	if not shrine.consumed or game.round_director.time_left <= time_before:
		await _fail("Void reward did not activate")
		return
	print("Museum V2: %d rooms, %d props, %d chests, %d voids" % [MuseumLayout.ROOMS.size(), MuseumLayout.PROPS.size(), game.arena.chests.size(), game.arena.void_shrines.size()])
	game.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	game.queue_free()
	await process_frame
	quit(1)

extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame: int in range(8):
		await physics_frame
	game.bot_director.enabled = false
	var player: HeistPlayer = game.players[0]
	game.artifact.global_position = player.global_position + Vector3.FORWARD
	if not game.artifact.pick_up(player):
		await _fail("Artifact pickup failed before seal route")
		return
	for seal: ExitSeal in game.arena.exit_seals:
		player.global_position = seal.global_position
		seal.update_carrier(player, ExitSeal.CHANNEL_SECONDS)
		await process_frame
	if game.round_director.seals_broken() != GameConstants.EXIT_SEAL_COUNT:
		await _fail("Physical seal route did not register every seal")
		return
	if not game.round_director.extraction_unlocked or not game.arena.seal_visual.visible:
		await _fail("Breaking all physical seals did not reveal extraction")
		return
	print("Seal flow: three room objectives unlocked hidden extraction")
	game.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	game.queue_free()
	await process_frame
	quit(1)

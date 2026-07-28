extends SceneTree

var game: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	for frame: int in range(8):
		await physics_frame
	var player: HeistPlayer = game.players[0]
	var start_y := player.global_position.y
	if not player.try_jump():
		push_error("Grounded player rejected jump input")
		game.queue_free()
		await process_frame
		quit(1)
		return
	for frame: int in range(2):
		await physics_frame
	var peak_y := start_y
	for frame: int in range(30):
		await physics_frame
		peak_y = maxf(peak_y, player.global_position.y)
	if peak_y <= start_y + 0.5:
		push_error("Jump height %.3f is below threshold" % (peak_y - start_y))
		game.queue_free()
		await process_frame
		quit(1)
		return
	print("Jump height: %.3f" % (peak_y - start_y))
	game.queue_free()
	await process_frame
	quit()

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
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	for frame: int in range(2):
		await physics_frame
	var release_event := InputEventKey.new()
	release_event.physical_keycode = KEY_SPACE
	release_event.pressed = false
	Input.parse_input_event(release_event)
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

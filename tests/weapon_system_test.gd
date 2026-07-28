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
	var attacker: HeistPlayer = game.players[0]
	var target: HeistPlayer = game.players[1]
	attacker.global_position = Vector3(-35.0, 0.1, 0.0)
	target.global_position = Vector3(-33.2, 0.1, 0.0)
	attacker.aim_direction = Vector3.RIGHT
	attacker.assign_weapon(WeaponCatalog.BATON)
	var health_before := target.health
	attacker.trigger_bot_shove()
	await physics_frame
	if target.health >= health_before:
		await _fail("Baton did not damage a nearby target")
		return
	attacker.shove_cooldown = 0.0
	attacker.assign_weapon(WeaponCatalog.BLUNDERBUSS)
	target.velocity = Vector3.ZERO
	target.global_position = Vector3(-30.2, 0.1, 0.0)
	attacker.aim_direction = Vector3.RIGHT
	health_before = target.health
	attacker.trigger_bot_shove()
	await physics_frame
	if target.health >= health_before:
		await _fail("Blunderbuss did not damage a distant target")
		return
	attacker.shove_cooldown = 0.0
	attacker.assign_weapon(WeaponCatalog.FOAM_SPRAYER)
	target.velocity = Vector3.ZERO
	target.global_position = Vector3(-31.8, 0.1, 0.0)
	attacker.aim_direction = Vector3.RIGHT
	attacker.trigger_bot_shove()
	await physics_frame
	if target.slowed_seconds <= 0.0:
		await _fail("Foam sprayer did not slow its target")
		return
	print("Weapons: baton, blunderbuss and foam sprayer verified")
	for frame: int in range(20):
		await physics_frame
	game.queue_free()
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	game.queue_free()
	await process_frame
	quit(1)

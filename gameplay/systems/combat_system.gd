class_name CombatSystem
extends Node

signal ghost_haunted(player: HeistPlayer)

var players: Array[HeistPlayer] = []
var artifact: CursedArtifact
var recorder: MatchRecorder
var audio: AudioDirector
var enabled := true

func configure(assigned_players: Array[HeistPlayer], assigned_artifact: CursedArtifact, assigned_recorder: MatchRecorder, assigned_audio: AudioDirector) -> void:
	players = assigned_players
	artifact = assigned_artifact
	recorder = assigned_recorder
	audio = assigned_audio
	for player: HeistPlayer in players:
		player.shove_requested.connect(_on_shove_requested)
		player.defeated.connect(_on_player_defeated)
		player.emote_started.connect(_on_emote_started)

func explode_artifact(carrier: HeistPlayer) -> void:
	recorder.increment(carrier, &"explosions")
	recorder.record(&"artifact_exploded", carrier)
	artifact.drop(carrier.facing * -4.0 + Vector3.UP * 5.0)
	carrier.add_curse(CurseCatalog.HEAVY, 9.0)
	for player: HeistPlayer in players:
		if player.is_ghost:
			continue
		var offset := player.global_position - carrier.global_position
		if offset.length() > 4.8:
			continue
		var direction := offset.normalized() if offset.length_squared() > 0.1 else Vector3.RIGHT.rotated(Vector3.UP, player.player_index * TAU / 4.0)
		player.apply_shove(direction * 1.35)
		player.take_damage(GameConstants.EXPLOSION_DAMAGE * (1.0 - offset.length() / 7.2))
	audio.play(&"curse", 0.58)

func _on_shove_requested(player: HeistPlayer) -> void:
	if not enabled:
		return
	var definition := WeaponCatalog.definition(player.weapon_id)
	var range: float = definition["range"]
	var attack_direction := Vector3(player.aim_direction.x, 0.0, player.aim_direction.z).normalized()
	player.facing = attack_direction
	player.play_weapon_attack()
	audio.play(&"shove", _weapon_pitch(player.weapon_id) + player.player_index * 0.025)
	_spawn_attack_effect(player.global_position + Vector3.UP * 0.9, attack_direction, range, definition["color"])
	for target: HeistPlayer in players:
		if target == player or target.is_ghost:
			continue
		var offset := target.global_position - player.global_position
		offset.y = 0.0
		if offset.length() > range:
			continue
		if attack_direction.dot(offset.normalized()) < definition["cone"]:
			continue
		if not _has_line_of_sight(player, target):
			continue
		var falloff := clampf(1.15 - offset.length() / (range * 1.7), 0.48, 1.0)
		target.apply_impact(offset, definition["force"] * falloff)
		target.take_damage(definition["damage"] * falloff)
		if player.weapon_id == WeaponCatalog.FOAM_SPRAYER:
			target.apply_slow(5.0)
		recorder.increment(player, &"shoves")
		recorder.increment(player, &"weapon_hits")
		recorder.record(player.weapon_id, player, target)
		if artifact.carrier == target:
			artifact.drop(offset.normalized() * definition["force"] + Vector3.UP * 2.2)

func _has_line_of_sight(player: HeistPlayer, target: HeistPlayer) -> bool:
	var from := player.global_position + Vector3.UP
	var to := target.global_position + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, to, 4)
	return player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _weapon_pitch(id: StringName) -> float:
	match id:
		WeaponCatalog.BATON:
			return 0.82
		WeaponCatalog.BLUNDERBUSS:
			return 0.55
		WeaponCatalog.FOAM_SPRAYER:
			return 1.42
	return 1.0

func _spawn_attack_effect(origin: Vector3, direction: Vector3, range: float, color: Color) -> void:
	var effect := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	mesh.radial_segments = 12
	mesh.rings = 6
	effect.mesh = mesh
	add_child(effect)
	effect.position = origin + direction * range * 0.42
	effect.scale = Vector3(0.7, 0.7, range * 0.9)
	effect.rotation.y = atan2(direction.x, direction.z)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, 0.34)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	effect.material_override = material
	var tween := effect.create_tween()
	tween.tween_property(effect, "scale", effect.scale * 1.28, 0.14)
	tween.parallel().tween_property(effect, "transparency", 1.0, 0.14)
	tween.tween_callback(effect.queue_free)

func _on_player_defeated(player: HeistPlayer) -> void:
	if artifact.carrier == player:
		artifact.drop(Vector3.UP * 3.5)
	player.clear_curses()
	recorder.increment(player, &"deaths")
	recorder.record(&"player_defeated", player)
	audio.play(&"curse", 0.42)

func _on_emote_started(player: HeistPlayer, _emote: StringName) -> void:
	if not enabled or not player.is_ghost:
		return
	if artifact.carrier == null and player.global_position.distance_to(artifact.global_position) <= 5.0:
		var direction := (artifact.global_position - player.global_position).normalized()
		artifact.apply_central_impulse(direction * 3.0 + Vector3.UP * 2.5)
	for target: HeistPlayer in players:
		if target.is_ghost or target.global_position.distance_to(player.global_position) > 4.0:
			continue
		target.add_curse(CurseCatalog.ECHO, 4.0)
	recorder.increment(player, &"haunts")
	recorder.record(&"ghost_haunted", player)
	audio.play(&"curse", 1.45)
	ghost_haunted.emit(player)

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
	audio.play(&"shove", 0.94 + player.player_index * 0.04)
	for target: HeistPlayer in players:
		if target == player or target.is_ghost:
			continue
		var offset := target.global_position - player.global_position
		offset.y = 0.0
		if offset.length() > GameConstants.SHOVE_RANGE:
			continue
		if player.facing.dot(offset.normalized()) < 0.15:
			continue
		target.apply_shove(offset)
		target.take_damage(GameConstants.SHOVE_DAMAGE)
		recorder.increment(player, &"shoves")
		recorder.record(&"player_shoved", player, target)
		if artifact.carrier == target:
			artifact.drop(offset.normalized() * 9.5 + Vector3.UP * 2.2)

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

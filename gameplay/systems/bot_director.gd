class_name BotDirector
extends Node

const SimulationAuthorityScript = preload("res://core/simulation_authority.gd")
var players: Array[HeistPlayer] = []
var artifact: CursedArtifact
var round_director: RoundDirector
var action_seconds := 0.0
var enabled := true

func configure(assigned_players: Array[HeistPlayer], assigned_artifact: CursedArtifact, assigned_round_director: RoundDirector) -> void:
	players = assigned_players
	artifact = assigned_artifact
	round_director = assigned_round_director

func _process(delta: float) -> void:
	if not enabled or not SimulationAuthorityScript.can_mutate(self):
		return
	action_seconds = maxf(action_seconds - delta, 0.0)
	for player: HeistPlayer in players:
		if not player.is_bot or player.is_ghost:
			continue
		_update_bot(player)

func reset() -> void:
	action_seconds = 0.0
	enabled = true

func _update_bot(player: HeistPlayer) -> void:
	if artifact.carrier == player:
		var escape_target := HeistArena.EXTRACTION_CENTER if round_director.extraction_unlocked else round_director.next_seal_position(player.global_position)
		player.set_bot_target(MuseumRoutePlanner.next_target(player.global_position, escape_target))
	elif artifact.carrier == null:
		player.set_bot_target(MuseumRoutePlanner.next_target(player.global_position, artifact.global_position))
		if player.global_position.distance_to(artifact.global_position) <= GameConstants.INTERACTION_RANGE and action_seconds <= 0.0:
			player.trigger_bot_interaction()
			action_seconds = 0.32
	else:
		player.set_bot_target(MuseumRoutePlanner.next_target(player.global_position, artifact.carrier.global_position))
		var weapon_range: float = WeaponCatalog.definition(player.weapon_id)["range"]
		if player.global_position.distance_to(artifact.carrier.global_position) <= weapon_range * 0.88 and action_seconds <= 0.0:
			player.trigger_bot_shove()
			action_seconds = 0.28

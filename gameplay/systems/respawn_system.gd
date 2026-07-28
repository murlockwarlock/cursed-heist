class_name RespawnSystem
extends Node

const SimulationAuthorityScript = preload("res://core/simulation_authority.gd")
signal respawn_started(player: HeistPlayer)
signal player_respawned(player: HeistPlayer)

var players: Array[HeistPlayer] = []
var artifact: CursedArtifact
var enabled := true
var rng := RandomNumberGenerator.new()

func configure(assigned_players: Array[HeistPlayer], assigned_artifact: CursedArtifact) -> void:
	players = assigned_players
	artifact = assigned_artifact
	rng.randomize()
	for player: HeistPlayer in players:
		player.defeated.connect(_on_player_defeated)

func _process(delta: float) -> void:
	if not enabled or not SimulationAuthorityScript.can_mutate(self):
		return
	for player: HeistPlayer in players:
		if not player.is_ghost or player.respawn_seconds <= 0.0:
			continue
		player.respawn_seconds = maxf(player.respawn_seconds - delta, 0.0)
		if player.respawn_seconds <= 0.0:
			_respawn(player)

func reset() -> void:
	enabled = true
	for player: HeistPlayer in players:
		player.respawn_seconds = 0.0

func _on_player_defeated(player: HeistPlayer) -> void:
	if not enabled or not SimulationAuthorityScript.can_mutate(self):
		return
	player.respawn_seconds = GameConstants.RESPAWN_SECONDS
	respawn_started.emit(player)

func _respawn(player: HeistPlayer) -> void:
	player.revive_at(_choose_spawn(player))
	player_respawned.emit(player)

func _choose_spawn(player: HeistPlayer) -> Vector3:
	var ranked: Array[Dictionary] = []
	for point: Vector3 in MuseumLayout.RESPAWN_POINTS:
		var nearest_player := 1000.0
		for other: HeistPlayer in players:
			if other == player or other.is_ghost:
				continue
			nearest_player = minf(nearest_player, point.distance_to(other.global_position))
		var artifact_distance := point.distance_to(artifact.global_position)
		ranked.append({"point": point, "score": nearest_player + minf(artifact_distance, 18.0) * 0.35})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	var candidate_count := mini(3, ranked.size())
	return ranked[rng.randi_range(0, candidate_count - 1)]["point"]

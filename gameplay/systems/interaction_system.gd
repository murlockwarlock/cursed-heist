class_name InteractionSystem
extends Node

var players: Array[HeistPlayer] = []
var artifact: CursedArtifact
var chests: Array[LootChest] = []
var recorder: MatchRecorder
var audio: AudioDirector
var enabled := true

func configure(assigned_players: Array[HeistPlayer], assigned_artifact: CursedArtifact, assigned_chests: Array[LootChest], assigned_recorder: MatchRecorder, assigned_audio: AudioDirector) -> void:
	players = assigned_players
	artifact = assigned_artifact
	chests = assigned_chests
	recorder = assigned_recorder
	audio = assigned_audio
	for player: HeistPlayer in players:
		player.interaction_requested.connect(_on_interaction_requested)
	for chest: LootChest in chests:
		chest.opened_by.connect(_on_chest_opened)

func process_auto_catch() -> void:
	if not enabled or is_instance_valid(artifact.carrier) or artifact.linear_velocity.length() < 2.2:
		return
	for player: HeistPlayer in players:
		if player.is_ghost or player == artifact.last_carrier:
			continue
		if player.global_position.distance_to(artifact.global_position) > 1.05:
			continue
		var passer := artifact.last_carrier
		if artifact.pick_up(player):
			recorder.increment(player, &"catches")
			recorder.record(&"artifact_passed", passer, player)
			audio.play(&"pickup", 1.22)
			return

func context_prompt(player: HeistPlayer) -> StringName:
	if player.is_ghost:
		return &"PROMPT_GHOST"
	if artifact.carrier == player:
		return &"PROMPT_THROW"
	if artifact.carrier == null and player.global_position.distance_to(artifact.global_position) <= GameConstants.INTERACTION_RANGE:
		return &"PROMPT_PICKUP"
	if is_instance_valid(_nearest_chest(player)):
		return &"PROMPT_OPEN_CHEST"
	if is_instance_valid(artifact.carrier) and player.global_position.distance_to(artifact.carrier.global_position) <= GameConstants.SHOVE_RANGE + 0.5:
		return &"PROMPT_STEAL"
	return &""

func _on_interaction_requested(player: HeistPlayer) -> void:
	if not enabled:
		return
	if artifact.carrier == player:
		var throw_speed := 12.0 if not player.has_curse(CurseCatalog.HEAVY) else 7.0
		artifact.drop(player.aim_direction.normalized() * throw_speed + player.velocity * 0.35 + Vector3.UP * 3.1)
		recorder.increment(player, &"throws")
		recorder.record(&"artifact_thrown", player)
		audio.play(&"drop")
		return
	if artifact.carrier == null and player.global_position.distance_to(artifact.global_position) <= GameConstants.INTERACTION_RANGE:
		if artifact.pick_up(player):
			recorder.increment(player, &"pickups")
			recorder.record(&"artifact_picked_up", player)
			audio.play(&"pickup", 1.0 + player.player_index * 0.04)
		return
	var chest := _nearest_chest(player)
	if is_instance_valid(chest):
		chest.interact(player)

func _nearest_chest(player: HeistPlayer) -> LootChest:
	var nearest: LootChest
	var nearest_distance := INF
	for chest: LootChest in chests:
		if not chest.can_interact(player):
			continue
		var distance := player.global_position.distance_to(chest.global_position)
		if distance < nearest_distance:
			nearest = chest
			nearest_distance = distance
	return nearest

func _on_chest_opened(_chest: LootChest, player: HeistPlayer) -> void:
	player.score += 4.0
	player.heal(24.0)
	recorder.increment(player, &"chests")
	recorder.record(&"chest_opened", player)
	audio.play(&"pickup", 1.38)

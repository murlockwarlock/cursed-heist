class_name RoundDirector
extends Node

signal completed(winner: HeistPlayer, reason: StringName)

var players: Array[HeistPlayer] = []
var arena: HeistArena
var artifact: CursedArtifact
var combat: CombatSystem
var recorder: MatchRecorder
var audio: AudioDirector
var time_left := GameConstants.ROUND_SECONDS
var artifact_charge := 0.0
var artifact_heat := 0.0
var extraction_unlocked := false
var enabled := false
var last_carrier: HeistPlayer

func configure(assigned_players: Array[HeistPlayer], assigned_arena: HeistArena, assigned_artifact: CursedArtifact, assigned_combat: CombatSystem, assigned_recorder: MatchRecorder, assigned_audio: AudioDirector) -> void:
	players = assigned_players
	arena = assigned_arena
	artifact = assigned_artifact
	combat = assigned_combat
	recorder = assigned_recorder
	audio = assigned_audio
	artifact.carrier_changed.connect(_on_carrier_changed)

func _process(delta: float) -> void:
	if not enabled:
		return
	time_left = maxf(time_left - delta, 0.0)
	if is_instance_valid(artifact.carrier):
		_process_carrier(delta, artifact.carrier)
	else:
		artifact_heat = maxf(artifact_heat - delta * 0.04, 0.0)
		artifact.heat = artifact_heat
	if not arena.safe_artifact_position(artifact.global_position):
		artifact.reset_to(HeistArena.ARTIFACT_HOME)
		audio.play(&"drop")
	if time_left <= 0.0:
		completed.emit(_highest_scoring_player(), &"WIN_POWER")

func reset() -> void:
	time_left = GameConstants.ROUND_SECONDS
	artifact_charge = 0.0
	artifact_heat = 0.0
	extraction_unlocked = false
	last_carrier = null
	enabled = true
	arena.set_extraction_unlocked(false)
	artifact.heat = 0.0

func add_time(seconds: float) -> void:
	time_left = minf(time_left + seconds, GameConstants.ROUND_SECONDS + 60.0)

func seals_broken() -> int:
	return mini(int(artifact_charge / (GameConstants.EXTRACTION_CHARGE / GameConstants.EXIT_SEAL_COUNT)), GameConstants.EXIT_SEAL_COUNT)

func _process_carrier(delta: float, carrier: HeistPlayer) -> void:
	artifact_heat = minf(artifact_heat + delta / 8.0, 1.0)
	artifact.heat = artifact_heat
	recorder.increment(carrier, &"carry_seconds", delta)
	var charge_rate := 2.6 if carrier.emote_name == &"dance" and carrier.emote_seconds > 0.0 else 1.0
	carrier.score += delta * charge_rate
	artifact_charge += delta * charge_rate
	if artifact_charge >= GameConstants.EXTRACTION_CHARGE and not extraction_unlocked:
		extraction_unlocked = true
		arena.set_extraction_unlocked(true)
		audio.play(&"unlock")
	if extraction_unlocked and arena.contains_extraction(carrier.global_position):
		completed.emit(carrier, &"WIN_EXTRACTION")
	if artifact_heat >= 1.0:
		artifact_heat = 0.16
		artifact.heat = artifact_heat
		combat.explode_artifact(carrier)

func _highest_scoring_player() -> HeistPlayer:
	var winner := players[0]
	for player: HeistPlayer in players:
		if player.score > winner.score:
			winner = player
	return winner

func _on_carrier_changed(previous: HeistPlayer, current: HeistPlayer) -> void:
	if is_instance_valid(previous):
		previous.stun_seconds = maxf(previous.stun_seconds, 0.08)
	if is_instance_valid(current):
		if is_instance_valid(last_carrier) and last_carrier != current:
			artifact_heat *= 0.42
		last_carrier = current
		current.add_curse(CurseCatalog.GREED, 12.0)

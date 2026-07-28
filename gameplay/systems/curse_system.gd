class_name CurseSystem
extends Node

signal curse_applied(player: HeistPlayer, curse_id: StringName)

var players: Array[HeistPlayer] = []
var artifact: CursedArtifact
var rng := RandomNumberGenerator.new()
var next_curse_seconds := 4.0

func configure(assigned_players: Array[HeistPlayer], assigned_artifact: CursedArtifact) -> void:
	players = assigned_players
	artifact = assigned_artifact
	rng.seed = 0xC0FFEE

func reset() -> void:
	next_curse_seconds = 4.0
	for player: HeistPlayer in players:
		player.clear_curses()

func _process(delta: float) -> void:
	if not is_instance_valid(artifact) or not is_instance_valid(artifact.carrier):
		return
	next_curse_seconds -= delta
	if next_curse_seconds > 0.0:
		return
	var carrier := artifact.carrier
	var candidates := CurseCatalog.ALL.filter(func(id: StringName) -> bool: return not carrier.has_curse(id))
	if candidates.is_empty():
		candidates = CurseCatalog.ALL.duplicate()
	var curse_id: StringName = candidates[rng.randi_range(0, candidates.size() - 1)]
	carrier.add_curse(curse_id, rng.randf_range(13.0, 19.0))
	next_curse_seconds = rng.randf_range(5.0, 8.0)
	curse_applied.emit(carrier, curse_id)

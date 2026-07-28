extends Node3D

const PLAYER_COLORS: Array[Color] = [Color("ff4d61"), Color("36d3ff"), Color("ffd43b"), Color("87f558")]
const SPAWN_POINTS: Array[Vector3] = [Vector3(-17.7, 0.1, 0.0), Vector3(-16.0, 0.1, -2.0), Vector3(-16.0, 0.1, 2.0), Vector3(-12.0, 0.1, 0.0)]
const ARTIFACT_SPAWN := Vector3(0.0, 1.2, 0.0)

var arena: HeistArena
var artifact: CursedArtifact
var curse_system: CurseSystem
var audio: AudioDirector
var hud: HeistHud
var recorder: MatchRecorder
var camera_rig: HeistCamera
var interactions: InteractionSystem
var combat: CombatSystem
var round_director: RoundDirector
var bot_director: BotDirector
var players: Array[HeistPlayer] = []
var round_finished := false
var restart_key_down := false

func _ready() -> void:
	add_child(MuseumLighting.new())
	audio = AudioDirector.new()
	add_child(audio)
	arena = HeistArena.new()
	add_child(arena)
	_create_players()
	artifact = CursedArtifact.new()
	artifact.position = ARTIFACT_SPAWN
	add_child(artifact)
	recorder = MatchRecorder.new()
	recorder.configure(players.size())
	add_child(recorder)
	interactions = InteractionSystem.new()
	interactions.configure(players, artifact, arena.chests, recorder, audio)
	add_child(interactions)
	combat = CombatSystem.new()
	combat.configure(players, artifact, recorder, audio)
	combat.ghost_haunted.connect(_on_ghost_haunted)
	add_child(combat)
	round_director = RoundDirector.new()
	round_director.configure(players, arena, artifact, combat, recorder, audio)
	round_director.completed.connect(_on_round_completed)
	add_child(round_director)
	bot_director = BotDirector.new()
	bot_director.configure(players, artifact, round_director)
	add_child(bot_director)
	curse_system = CurseSystem.new()
	curse_system.configure(players, artifact)
	curse_system.curse_applied.connect(_on_curse_applied)
	add_child(curse_system)
	hud = HeistHud.new()
	add_child(hud)
	camera_rig = HeistCamera.new()
	camera_rig.target = players[0]
	camera_rig.position = players[0].position
	add_child(camera_rig)
	reset_round()

func _process(_delta: float) -> void:
	if round_finished:
		var restart_pressed := Input.is_physical_key_pressed(KEY_ENTER)
		if restart_pressed and not restart_key_down:
			reset_round()
		restart_key_down = restart_pressed
		return
	interactions.process_auto_catch()
	hud.update_state(players, round_director.time_left, round_director.artifact_charge, round_director.extraction_unlocked, round_director.artifact_heat)
	_update_context_prompt()

func _create_players() -> void:
	var devices: PackedInt32Array = Input.get_connected_joypads()
	var character_order := CharacterCatalog.random_order()
	for index: int in range(4):
		var player := HeistPlayer.new()
		var device: int = devices[index] if index < devices.size() else -1
		player.configure(index, PLAYER_COLORS[index], device, character_order[index])
		player.position = SPAWN_POINTS[index]
		player.emote_started.connect(_on_emote_started)
		players.append(player)
		add_child(player)

func reset_round() -> void:
	round_finished = false
	restart_key_down = Input.is_physical_key_pressed(KEY_ENTER)
	artifact.reset_to(ARTIFACT_SPAWN)
	var character_order := CharacterCatalog.random_order()
	for index: int in range(players.size()):
		var player := players[index]
		player.assign_character(character_order[index])
		player.global_position = SPAWN_POINTS[index]
		player.velocity = Vector3.ZERO
		player.score = 0.0
		player.stun_seconds = 0.0
		player.revive()
		player.clear_curses()
	curse_system.reset()
	recorder.reset()
	interactions.enabled = true
	arena.reset_chests()
	combat.enabled = true
	bot_director.reset()
	round_director.reset()
	hud.hide_result()

func finish_round(winner: HeistPlayer, reason: String) -> void:
	if round_finished:
		return
	round_finished = true
	round_director.enabled = false
	interactions.enabled = false
	combat.enabled = false
	bot_director.enabled = false
	for player: HeistPlayer in players:
		player.velocity = Vector3.ZERO
	if is_instance_valid(artifact.carrier):
		artifact.drop(Vector3.ZERO)
	audio.play(&"win")
	hud.show_result(winner, reason, recorder.titles(players))

func _on_emote_started(player: HeistPlayer, emote: StringName) -> void:
	if player.is_ghost:
		return
	var pitch := 1.18 if emote == &"dance" else 0.82
	audio.play(&"emote", pitch)
	recorder.increment(player, &"emotes")
	recorder.record(emote, player)
	if player.has_curse(CurseCatalog.DANCE_FEVER):
		player.score += 1.0

func _on_curse_applied(player: HeistPlayer, curse_id: StringName) -> void:
	audio.play(&"curse", 0.86 + float(CurseCatalog.ALL.find(curse_id)) * 0.09)
	player.score += 0.5
	recorder.increment(player, &"curses")
	recorder.record(curse_id, player)

func _update_context_prompt() -> void:
	var prompt_key := interactions.context_prompt(players[0])
	if prompt_key != &"":
		hud.update_prompt(tr(prompt_key))
	elif artifact.carrier == null:
		hud.update_prompt(tr(&"PROMPT_FIND") % int(players[0].global_position.distance_to(artifact.global_position)))
	elif artifact.carrier != players[0]:
		hud.update_prompt(tr(&"PROMPT_CHASE") % artifact.carrier.player_name)
	else:
		hud.update_prompt("")

func _on_round_completed(winner: HeistPlayer, reason: StringName) -> void:
	finish_round(winner, tr(reason))

func _on_ghost_haunted(_player: HeistPlayer) -> void:
	round_director.artifact_heat = minf(round_director.artifact_heat + 0.08, 0.95)

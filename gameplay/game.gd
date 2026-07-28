extends Node2D

const PLAYER_COLORS: Array[Color] = [Color("ff5b66"), Color("42c8ff"), Color("ffd447"), Color("8bff78")]
const SPAWN_POINTS: Array[Vector2] = [Vector2(142.0, 180.0), Vector2(142.0, 540.0), Vector2(1040.0, 160.0), Vector2(1040.0, 560.0)]
const ARTIFACT_SPAWN := Vector2(640.0, 356.0)

var arena: HeistArena
var artifact: CursedArtifact
var curse_system: CurseSystem
var audio: AudioDirector
var hud: HeistHud
var recorder: MatchRecorder
var players: Array[HeistPlayer] = []
var time_left := GameConstants.ROUND_SECONDS
var artifact_charge := 0.0
var extraction_unlocked := false
var round_finished := false
var restart_key_down := false
var artifact_heat := 0.0
var last_carrier: HeistPlayer

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("080512"))
	audio = AudioDirector.new()
	add_child(audio)
	arena = HeistArena.new()
	add_child(arena)
	_create_players()
	artifact = CursedArtifact.new()
	artifact.position = ARTIFACT_SPAWN
	artifact.carrier_changed.connect(_on_carrier_changed)
	add_child(artifact)
	curse_system = CurseSystem.new()
	curse_system.configure(players, artifact)
	curse_system.curse_applied.connect(_on_curse_applied)
	add_child(curse_system)
	recorder = MatchRecorder.new()
	recorder.configure(players.size())
	add_child(recorder)
	hud = HeistHud.new()
	add_child(hud)
	reset_round()

func _process(delta: float) -> void:
	if round_finished:
		var restart_pressed := Input.is_physical_key_pressed(KEY_ENTER)
		if restart_pressed and not restart_key_down:
			reset_round()
		restart_key_down = restart_pressed
		return
	time_left = maxf(time_left - delta, 0.0)
	if is_instance_valid(artifact.carrier):
		var carrier := artifact.carrier
		artifact_heat = minf(artifact_heat + delta / 8.0, 1.0)
		artifact.heat = artifact_heat
		recorder.increment(carrier, &"carry_seconds", delta)
		var charge_rate := 1.0
		if carrier.emote_name == &"dance" and carrier.emote_seconds > 0.0:
			charge_rate = 2.6
		carrier.score += delta * charge_rate
		artifact_charge += delta * charge_rate
		if artifact_charge >= GameConstants.EXTRACTION_CHARGE and not extraction_unlocked:
			extraction_unlocked = true
			arena.set_extraction_unlocked(true)
			audio.play(&"unlock")
		if extraction_unlocked and arena.contains_extraction(carrier.global_position):
			finish_round(carrier, tr(&"WIN_EXTRACTION"))
		if artifact_heat >= 1.0:
			_explode_artifact(carrier)
	else:
		artifact_heat = maxf(artifact_heat - delta * 0.04, 0.0)
		artifact.heat = artifact_heat
	if not arena.safe_artifact_position(artifact.global_position):
		artifact.reset_to(ARTIFACT_SPAWN)
		audio.play(&"drop")
	if time_left <= 0.0:
		var winner: HeistPlayer = players[0]
		for player: HeistPlayer in players:
			if player.score > winner.score:
				winner = player
		finish_round(winner, tr(&"WIN_POWER"))
	hud.update_state(players, time_left, artifact_charge, extraction_unlocked, artifact_heat)

func _create_players() -> void:
	var devices: PackedInt32Array = Input.get_connected_joypads()
	for index: int in range(4):
		var player := HeistPlayer.new()
		var device: int = devices[index] if index < devices.size() else -1
		player.configure(index, PLAYER_COLORS[index], device)
		player.position = SPAWN_POINTS[index]
		player.interaction_requested.connect(_on_interaction_requested)
		player.shove_requested.connect(_on_shove_requested)
		player.emote_started.connect(_on_emote_started)
		players.append(player)
		add_child(player)

func reset_round() -> void:
	round_finished = false
	restart_key_down = Input.is_physical_key_pressed(KEY_ENTER)
	time_left = GameConstants.ROUND_SECONDS
	artifact_charge = 0.0
	artifact_heat = 0.0
	artifact.heat = 0.0
	last_carrier = null
	extraction_unlocked = false
	arena.set_extraction_unlocked(false)
	artifact.reset_to(ARTIFACT_SPAWN)
	for index: int in range(players.size()):
		var player := players[index]
		player.global_position = SPAWN_POINTS[index]
		player.velocity = Vector2.ZERO
		player.score = 0.0
		player.stun_seconds = 0.0
		player.clear_curses()
	curse_system.reset()
	recorder.reset()
	hud.hide_result()

func finish_round(winner: HeistPlayer, reason: String) -> void:
	if round_finished:
		return
	round_finished = true
	for player: HeistPlayer in players:
		player.velocity = Vector2.ZERO
	if is_instance_valid(artifact.carrier):
		artifact.drop(Vector2.ZERO)
	audio.play(&"win")
	hud.show_result(winner, reason, recorder.titles(players))

func _on_interaction_requested(player: HeistPlayer) -> void:
	if round_finished:
		return
	if artifact.carrier == player:
		var throw_speed := 620.0 if not player.has_curse(CurseCatalog.HEAVY) else 340.0
		artifact.drop(player.facing * throw_speed + player.velocity * 0.35)
		recorder.increment(player, &"throws")
		recorder.record(&"artifact_thrown", player)
		audio.play(&"drop")
		return
	if artifact.carrier == null and player.global_position.distance_to(artifact.global_position) <= GameConstants.INTERACTION_RANGE:
		if artifact.pick_up(player):
			recorder.increment(player, &"pickups")
			recorder.record(&"artifact_picked_up", player)
			audio.play(&"pickup", 1.0 + player.player_index * 0.04)

func _on_shove_requested(player: HeistPlayer) -> void:
	if round_finished:
		return
	audio.play(&"shove", 0.94 + player.player_index * 0.04)
	for target: HeistPlayer in players:
		if target == player:
			continue
		var offset := target.global_position - player.global_position
		if offset.length() > GameConstants.SHOVE_RANGE:
			continue
		if player.facing.dot(offset.normalized()) < 0.15:
			continue
		target.apply_shove(offset)
		recorder.increment(player, &"shoves")
		recorder.record(&"player_shoved", player, target)
		if artifact.carrier == target:
			artifact.drop(offset.normalized() * 510.0)

func _on_emote_started(player: HeistPlayer, emote: StringName) -> void:
	var pitch := 1.18 if emote == &"dance" else 0.82
	audio.play(&"emote", pitch)
	recorder.increment(player, &"emotes")
	recorder.record(emote, player)
	if player.has_curse(CurseCatalog.DANCE_FEVER):
		player.score += 1.0

func _on_carrier_changed(previous: HeistPlayer, current: HeistPlayer) -> void:
	if is_instance_valid(previous):
		previous.stun_seconds = maxf(previous.stun_seconds, 0.08)
	if is_instance_valid(current):
		if is_instance_valid(last_carrier) and last_carrier != current:
			artifact_heat *= 0.42
		last_carrier = current
		current.add_curse(CurseCatalog.GREED, 12.0)

func _on_curse_applied(player: HeistPlayer, curse_id: StringName) -> void:
	audio.play(&"curse", 0.86 + float(CurseCatalog.ALL.find(curse_id)) * 0.09)
	player.score += 0.5
	recorder.increment(player, &"curses")
	recorder.record(curse_id, player)

func _explode_artifact(carrier: HeistPlayer) -> void:
	artifact_heat = 0.16
	artifact.heat = artifact_heat
	recorder.increment(carrier, &"explosions")
	recorder.record(&"artifact_exploded", carrier)
	artifact.drop(carrier.facing * -280.0)
	carrier.add_curse(CurseCatalog.HEAVY, 9.0)
	for player: HeistPlayer in players:
		var offset := player.global_position - carrier.global_position
		if offset.length() <= 210.0:
			var direction := offset.normalized() if offset.length_squared() > 1.0 else Vector2.RIGHT.rotated(player.player_index * TAU / 4.0)
			player.apply_shove(direction * 1.35)
	audio.play(&"curse", 0.58)

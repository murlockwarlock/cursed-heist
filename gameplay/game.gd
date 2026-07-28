extends Node3D

const PLAYER_COLORS: Array[Color] = [Color("ff4d61"), Color("36d3ff"), Color("ffd43b"), Color("87f558")]
const SPAWN_POINTS: Array[Vector3] = [Vector3(-9.2, 0.1, 0.0), Vector3(-6.8, 0.1, -4.6), Vector3(-6.8, 0.1, 4.6), Vector3(7.0, 0.1, 4.8)]
const ARTIFACT_SPAWN := Vector3(0.0, 1.2, 0.0)

var arena: HeistArena
var artifact: CursedArtifact
var curse_system: CurseSystem
var audio: AudioDirector
var hud: HeistHud
var recorder: MatchRecorder
var camera_rig: HeistCamera
var players: Array[HeistPlayer] = []
var time_left := GameConstants.ROUND_SECONDS
var artifact_charge := 0.0
var artifact_heat := 0.0
var extraction_unlocked := false
var round_finished := false
var restart_key_down := false
var last_carrier: HeistPlayer
var bot_action_seconds := 0.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("080512"))
	_build_world()
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
	camera_rig = HeistCamera.new()
	camera_rig.target = players[0]
	camera_rig.position = players[0].position
	add_child(camera_rig)
	reset_round()

func _process(delta: float) -> void:
	if round_finished:
		var restart_pressed := Input.is_physical_key_pressed(KEY_ENTER)
		if restart_pressed and not restart_key_down:
			reset_round()
		restart_key_down = restart_pressed
		return
	time_left = maxf(time_left - delta, 0.0)
	_update_bots(delta)
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

func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("090319")
	sky_material.sky_horizon_color = Color("2d164b")
	sky_material.ground_bottom_color = Color("05020c")
	sky_material.ground_horizon_color = Color("201036")
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("7755aa")
	environment.ambient_light_energy = 0.52
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("301c4b")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.008
	world_environment.environment = environment
	add_child(world_environment)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("a895ff")
	moon.light_energy = 1.15
	moon.rotation_degrees = Vector3(-56.0, -38.0, 0.0)
	moon.shadow_enabled = true
	add_child(moon)
	for light_position: Vector3 in [Vector3(-7.0, 3.6, -5.0), Vector3(-7.0, 3.6, 5.0), Vector3(0.0, 4.5, 0.0), Vector3(7.0, 3.6, -5.0), Vector3(7.0, 3.6, 5.0)]:
		var light := OmniLight3D.new()
		light.position = light_position
		light.light_color = Color("a957ff") if absf(light_position.x) < 1.0 else Color("ffbf62")
		light.light_energy = 3.2
		light.omni_range = 7.0
		light.shadow_enabled = true
		add_child(light)

func _create_players() -> void:
	var devices: PackedInt32Array = Input.get_connected_joypads()
	var character_order := CharacterCatalog.random_order()
	for index: int in range(4):
		var player := HeistPlayer.new()
		var device: int = devices[index] if index < devices.size() else -1
		player.configure(index, PLAYER_COLORS[index], device, character_order[index])
		player.position = SPAWN_POINTS[index]
		player.interaction_requested.connect(_on_interaction_requested)
		player.shove_requested.connect(_on_shove_requested)
		player.emote_started.connect(_on_emote_started)
		players.append(player)
		add_child(player)

func _update_bots(delta: float) -> void:
	bot_action_seconds = maxf(bot_action_seconds - delta, 0.0)
	for player: HeistPlayer in players:
		if not player.is_bot:
			continue
		if artifact.carrier == player:
			var escape_target := HeistArena.EXTRACTION_CENTER if extraction_unlocked else Vector3(-8.0 + player.player_index * 4.0, 0.0, -5.6 + player.player_index * 3.2)
			player.set_bot_target(escape_target)
		elif artifact.carrier == null:
			player.set_bot_target(artifact.global_position)
			if player.global_position.distance_to(artifact.global_position) <= GameConstants.INTERACTION_RANGE and bot_action_seconds <= 0.0:
				player.trigger_bot_interaction()
				bot_action_seconds = 0.32
		else:
			player.set_bot_target(artifact.carrier.global_position)
			if player.global_position.distance_to(artifact.carrier.global_position) <= GameConstants.SHOVE_RANGE and bot_action_seconds <= 0.0:
				player.trigger_bot_shove()
				bot_action_seconds = 0.28

func reset_round() -> void:
	round_finished = false
	restart_key_down = Input.is_physical_key_pressed(KEY_ENTER)
	time_left = GameConstants.ROUND_SECONDS
	artifact_charge = 0.0
	artifact_heat = 0.0
	extraction_unlocked = false
	last_carrier = null
	bot_action_seconds = 0.0
	arena.set_extraction_unlocked(false)
	artifact.heat = 0.0
	artifact.reset_to(ARTIFACT_SPAWN)
	var character_order := CharacterCatalog.random_order()
	for index: int in range(players.size()):
		var player := players[index]
		player.assign_character(character_order[index])
		player.global_position = SPAWN_POINTS[index]
		player.velocity = Vector3.ZERO
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
		player.velocity = Vector3.ZERO
	if is_instance_valid(artifact.carrier):
		artifact.drop(Vector3.ZERO)
	audio.play(&"win")
	hud.show_result(winner, reason, recorder.titles(players))

func _on_interaction_requested(player: HeistPlayer) -> void:
	if round_finished:
		return
	if artifact.carrier == player:
		var throw_speed := 12.0 if not player.has_curse(CurseCatalog.HEAVY) else 7.0
		artifact.drop(player.facing * throw_speed + player.velocity * 0.35 + Vector3.UP * 3.1)
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
		offset.y = 0.0
		if offset.length() > GameConstants.SHOVE_RANGE:
			continue
		if player.facing.dot(offset.normalized()) < 0.15:
			continue
		target.apply_shove(offset)
		recorder.increment(player, &"shoves")
		recorder.record(&"player_shoved", player, target)
		if artifact.carrier == target:
			artifact.drop(offset.normalized() * 9.5 + Vector3.UP * 2.2)

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
	artifact.drop(carrier.facing * -4.0 + Vector3.UP * 5.0)
	carrier.add_curse(CurseCatalog.HEAVY, 9.0)
	for player: HeistPlayer in players:
		var offset := player.global_position - carrier.global_position
		if offset.length() <= 4.8:
			var direction := offset.normalized() if offset.length_squared() > 0.1 else Vector3.RIGHT.rotated(Vector3.UP, player.player_index * TAU / 4.0)
			player.apply_shove(direction * 1.35)
	audio.play(&"curse", 0.58)

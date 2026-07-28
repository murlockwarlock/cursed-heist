class_name MatchRecorder
extends Node

var counters: Array[Dictionary] = []
var timeline: Array[Dictionary] = []

func configure(player_count: int) -> void:
	counters.clear()
	for index: int in range(player_count):
		counters.append({
			"pickups": 0,
			"throws": 0,
			"shoves": 0,
			"emotes": 0,
			"curses": 0,
			"explosions": 0,
			"carry_seconds": 0.0
		})

func reset() -> void:
	timeline.clear()
	for counter: Dictionary in counters:
		for key: Variant in counter:
			counter[key] = 0.0 if key == "carry_seconds" else 0

func record(type: StringName, actor: HeistPlayer, target: HeistPlayer = null) -> void:
	timeline.append({
		"time": Time.get_ticks_msec(),
		"type": type,
		"actor": actor.player_index if is_instance_valid(actor) else -1,
		"target": target.player_index if is_instance_valid(target) else -1
	})
	if timeline.size() > 96:
		timeline.pop_front()

func increment(player: HeistPlayer, key: StringName, amount: float = 1.0) -> void:
	if not is_instance_valid(player) or not counters[player.player_index].has(key):
		return
	counters[player.player_index][key] += amount

func titles(players: Array[HeistPlayer]) -> Array[String]:
	var result: Array[String] = []
	for player: HeistPlayer in players:
		var data: Dictionary = counters[player.player_index]
		var title := TranslationServer.translate(&"TITLE_UNPREDICTABLE")
		if data["explosions"] >= 2:
			title = TranslationServer.translate(&"TITLE_HOT_POTATO_VICTIM")
		elif data["shoves"] >= 5:
			title = TranslationServer.translate(&"TITLE_JUDAS")
		elif data["emotes"] >= 4:
			title = TranslationServer.translate(&"TITLE_DANCE_KING")
		elif data["curses"] >= 4:
			title = TranslationServer.translate(&"TITLE_CURSE_SPONGE")
		elif data["throws"] >= 4:
			title = TranslationServer.translate(&"TITLE_PASS_MASTER")
		elif data["carry_seconds"] >= 20.0:
			title = TranslationServer.translate(&"TITLE_GREEDY_HANDS")
		elif data["pickups"] == 0:
			title = TranslationServer.translate(&"TITLE_TOURIST")
		result.append("%s — %s" % [player.player_name, title])
	return result

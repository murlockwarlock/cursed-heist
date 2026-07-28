class_name AudioDirector
extends Node

var streams: Dictionary[StringName, AudioStreamWAV] = {}
var players: Array[AudioStreamPlayer] = []
var cursor := 0

func _ready() -> void:
	streams[&"pickup"] = _tone(520.0, 820.0, 0.13, 0.34)
	streams[&"drop"] = _tone(310.0, 160.0, 0.16, 0.3)
	streams[&"shove"] = _tone(130.0, 70.0, 0.11, 0.42)
	streams[&"curse"] = _tone(260.0, 980.0, 0.28, 0.32)
	streams[&"emote"] = _tone(660.0, 880.0, 0.18, 0.25)
	streams[&"unlock"] = _tone(420.0, 1260.0, 0.42, 0.3)
	streams[&"win"] = _tone(520.0, 1560.0, 0.68, 0.34)
	for index: int in range(10):
		var audio_player := AudioStreamPlayer.new()
		audio_player.bus = &"Master"
		players.append(audio_player)
		add_child(audio_player)

func play(id: StringName, pitch: float = 1.0) -> void:
	if not streams.has(id):
		return
	var audio_player := players[cursor]
	cursor = (cursor + 1) % players.size()
	audio_player.stream = streams[id]
	audio_player.pitch_scale = pitch
	audio_player.play()

func _tone(start_frequency: float, end_frequency: float, seconds: float, volume: float) -> AudioStreamWAV:
	var mix_rate := 44100
	var sample_count := int(seconds * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index: int in range(sample_count):
		var progress := float(sample_index) / float(sample_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		var envelope := pow(1.0 - progress, 2.2)
		var sample := sin(TAU * frequency * float(sample_index) / float(mix_rate)) * envelope * volume
		bytes.encode_s16(sample_index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	return stream

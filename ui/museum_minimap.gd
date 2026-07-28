class_name MuseumMinimap
extends Control

var players: Array[HeistPlayer] = []
var artifact: CursedArtifact
var void_shrines: Array[VoidShrine] = []

func configure(assigned_artifact: CursedArtifact, assigned_void_shrines: Array[VoidShrine]) -> void:
	artifact = assigned_artifact
	void_shrines = assigned_void_shrines

func update_players(assigned_players: Array[HeistPlayer]) -> void:
	players = assigned_players
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("0b0812e8"), true)
	draw_rect(bounds, Color("ffe8b0"), false, 2.0)
	var hall_from := _map_point(Vector3(-40.0, 0.0, -7.5))
	var hall_to := _map_point(Vector3(40.0, 0.0, 7.5))
	draw_rect(Rect2(hall_from, hall_to - hall_from), Color("3b274d"), true)
	for room: Dictionary in MuseumLayout.ROOMS:
		var room_position: Vector3 = room["position"]
		var room_size: Vector3 = room["size"]
		var from := _map_point(room_position - Vector3(room_size.x * 0.5, 0.0, room_size.z * 0.5))
		var to := _map_point(room_position + Vector3(room_size.x * 0.5, 0.0, room_size.z * 0.5))
		draw_rect(Rect2(from, to - from), Color(room["color"], 0.86), true)
		draw_rect(Rect2(from, to - from), Color(room["light"], 0.5), false, 1.0)
	for shrine: VoidShrine in void_shrines:
		var color := Color("594468") if shrine.consumed else Color("ca66ff")
		draw_circle(_map_point(shrine.global_position), 3.5, color)
	if is_instance_valid(artifact):
		var artifact_point := _map_point(artifact.global_position)
		var diamond := PackedVector2Array([artifact_point + Vector2(0.0, -5.0), artifact_point + Vector2(5.0, 0.0), artifact_point + Vector2(0.0, 5.0), artifact_point + Vector2(-5.0, 0.0)])
		draw_colored_polygon(diamond, Color("ffd34f"))
	for player: HeistPlayer in players:
		if player.player_index > 0 and player.carried_artifact == null and player.global_position.distance_to(players[0].global_position) > 8.0:
			continue
		var point := _map_point(player.global_position)
		var color := player.body_color
		color.a = 0.45 if player.is_ghost else 1.0
		draw_circle(point, 4.5 if player.player_index == 0 else 3.5, color)
		if player.player_index == 0:
			draw_arc(point, 6.5, 0.0, TAU, 16, Color.WHITE, 1.5)

func _map_point(world_position: Vector3) -> Vector2:
	return Vector2(
		(world_position.x + GameConstants.ARENA_HALF_SIZE.x) / (GameConstants.ARENA_HALF_SIZE.x * 2.0) * size.x,
		(world_position.z + GameConstants.ARENA_HALF_SIZE.y) / (GameConstants.ARENA_HALF_SIZE.y * 2.0) * size.y
	)

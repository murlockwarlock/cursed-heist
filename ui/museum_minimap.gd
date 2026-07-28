class_name MuseumMinimap
extends Control

var players: Array[HeistPlayer] = []
var artifact: CursedArtifact
var void_shrines: Array[VoidShrine] = []
var exit_seals: Array[ExitSeal] = []

func configure(assigned_artifact: CursedArtifact, assigned_void_shrines: Array[VoidShrine], assigned_exit_seals: Array[ExitSeal]) -> void:
	artifact = assigned_artifact
	void_shrines = assigned_void_shrines
	exit_seals = assigned_exit_seals

func update_players(assigned_players: Array[HeistPlayer]) -> void:
	players = assigned_players
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 5.0
	draw_circle(center, radius, Color("090711dc"))
	draw_arc(center, radius, 0.0, TAU, 64, Color("d7bd7c"), 2.0)
	draw_arc(center, radius * 0.52, 0.0, TAU, 48, Color("71598a66"), 1.0)
	draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), Color("71598a44"), 1.0)
	draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), Color("71598a44"), 1.0)
	if players.is_empty():
		return
	var local_player := players[0]
	for shrine: VoidShrine in void_shrines:
		if shrine.consumed:
			continue
		draw_circle(_radar_point(local_player, shrine.global_position, center, radius), 3.0, Color("c96cff"))
	for seal: ExitSeal in exit_seals:
		if seal.is_broken:
			continue
		var seal_point := _radar_point(local_player, seal.global_position, center, radius)
		draw_rect(Rect2(seal_point - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), Color("bb79ff"), true)
	if is_instance_valid(artifact):
		var point := _radar_point(local_player, artifact.global_position, center, radius)
		var diamond := PackedVector2Array([point + Vector2(0.0, -5.0), point + Vector2(5.0, 0.0), point + Vector2(0.0, 5.0), point + Vector2(-5.0, 0.0)])
		draw_colored_polygon(diamond, Color("ffd34f"))
	for player: HeistPlayer in players:
		if player == local_player:
			continue
		var distance := player.global_position.distance_to(local_player.global_position)
		if distance > 13.0 and player.carried_artifact == null:
			continue
		var point := _radar_point(local_player, player.global_position, center, radius)
		var color := Color(player.body_color, 0.42 if player.is_ghost else 1.0)
		draw_circle(point, 4.0, color)
		if player.carried_artifact != null:
			draw_arc(point, 7.0, 0.0, TAU, 20, Color("ffd34f"), 2.0)
	var direction := Vector2(local_player.facing.x, local_player.facing.z).normalized()
	draw_colored_polygon(PackedVector2Array([center + direction * 7.0, center + direction.rotated(2.5) * 5.0, center + direction.rotated(-2.5) * 5.0]), Color.WHITE)

func _radar_point(local_player: HeistPlayer, world_position: Vector3, center: Vector2, radius: float) -> Vector2:
	var offset := Vector2(world_position.x - local_player.global_position.x, world_position.z - local_player.global_position.z)
	return center + (offset / GameConstants.RADAR_RANGE * radius).limit_length(radius - 8.0)

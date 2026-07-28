class_name HeistArena
extends Node2D

const EXTRACTION_RECT := Rect2(1032.0, 272.0, 138.0, 180.0)
const OBSTACLES: Array[Rect2] = [
	Rect2(284.0, 180.0, 150.0, 56.0),
	Rect2(284.0, 492.0, 150.0, 56.0),
	Rect2(548.0, 290.0, 184.0, 132.0),
	Rect2(840.0, 160.0, 78.0, 120.0),
	Rect2(840.0, 440.0, 78.0, 120.0)
]

var extraction_unlocked := false
var pulse := 0.0

func _ready() -> void:
	z_index = -5
	_create_boundary()
	for obstacle: Rect2 in OBSTACLES:
		_create_wall(obstacle)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func set_extraction_unlocked(value: bool) -> void:
	extraction_unlocked = value
	queue_redraw()

func contains_extraction(point: Vector2) -> bool:
	return EXTRACTION_RECT.grow(-18.0).has_point(point)

func safe_artifact_position(point: Vector2) -> bool:
	return GameConstants.ARENA_RECT.grow(-20.0).has_point(point)

func _create_boundary() -> void:
	var rect := GameConstants.ARENA_RECT
	_create_wall(Rect2(rect.position - Vector2(28.0, 28.0), Vector2(rect.size.x + 56.0, 28.0)))
	_create_wall(Rect2(Vector2(rect.position.x - 28.0, rect.end.y), Vector2(rect.size.x + 56.0, 28.0)))
	_create_wall(Rect2(rect.position - Vector2(28.0, 0.0), Vector2(28.0, rect.size.y)))
	_create_wall(Rect2(Vector2(rect.end.x, rect.position.y), Vector2(28.0, rect.size.y)))

func _create_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 4
	body.collision_mask = 3
	body.position = rect.get_center()
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func _draw() -> void:
	draw_rect(GameConstants.ARENA_RECT, Color("171229"), true)
	draw_rect(GameConstants.ARENA_RECT, Color("5d4c80"), false, 5.0)
	for x: int in range(96, 1216, 48):
		draw_line(Vector2(x, 78.0), Vector2(x, 652.0), Color(0.3, 0.24, 0.48, 0.12), 1.0)
	for y: int in range(96, 656, 48):
		draw_line(Vector2(66.0, y), Vector2(1214.0, y), Color(0.3, 0.24, 0.48, 0.12), 1.0)
	for obstacle: Rect2 in OBSTACLES:
		draw_rect(obstacle, Color("2c2345"), true)
		draw_rect(obstacle, Color("7c68a1"), false, 3.0)
	var extraction_color := Color("54f59b") if extraction_unlocked else Color("5d526f")
	var alpha := 0.22 + sin(pulse * 5.0) * 0.06 if extraction_unlocked else 0.12
	draw_rect(EXTRACTION_RECT, Color(extraction_color, alpha), true)
	draw_rect(EXTRACTION_RECT, extraction_color, false, 4.0)
	draw_string(ThemeDB.fallback_font, EXTRACTION_RECT.position + Vector2(18.0, 96.0), TranslationServer.translate(&"EXIT_LABEL"), HORIZONTAL_ALIGNMENT_CENTER, 102.0, 18, extraction_color)
	draw_circle(Vector2(640.0, 356.0), 54.0 + sin(pulse * 3.0) * 3.0, Color(0.49, 0.24, 1.0, 0.11))

class_name LootChest
extends Node3D

signal opened_by(chest: LootChest, player: HeistPlayer)

var opened := false
var lid: Node3D
var closed_lid_transform := Transform3D.IDENTITY
var model_scene: PackedScene

func configure(scene: PackedScene) -> void:
	model_scene = scene

func _ready() -> void:
	var model := model_scene.instantiate()
	add_child(model)
	lid = model.find_child("Lid", true, false) as Node3D
	if is_instance_valid(lid):
		closed_lid_transform = lid.transform
	var body := StaticBody3D.new()
	body.collision_layer = 4
	body.position.y = 0.6
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 1.2, 1.0)
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func can_interact(player: HeistPlayer) -> bool:
	return not opened and not player.is_ghost and player.global_position.distance_to(global_position) <= GameConstants.INTERACTION_RANGE

func interact(player: HeistPlayer) -> void:
	if not can_interact(player):
		return
	opened = true
	if is_instance_valid(lid):
		var tween := create_tween().set_parallel(true)
		tween.tween_property(lid, "rotation_degrees:x", -68.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(lid, "position:y", lid.position.y + 0.15, 0.35)
	_flash_glow()
	opened_by.emit(self, player)

func reset() -> void:
	opened = false
	if is_instance_valid(lid):
		lid.transform = closed_lid_transform

func _flash_glow() -> void:
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.25, 0.0)
	glow.light_color = Color("ffd14a")
	glow.light_energy = 0.0
	glow.omni_range = 3.5
	add_child(glow)
	var tween := create_tween()
	tween.tween_property(glow, "light_energy", 4.0, 0.1)
	tween.tween_property(glow, "light_energy", 0.0, 0.7)
	tween.tween_callback(glow.queue_free)

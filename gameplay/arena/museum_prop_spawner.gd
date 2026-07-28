class_name MuseumPropSpawner
extends Node3D

const MODEL_PATHS := {
	&"chest": "res://assets/environment/models/chest.glb",
	&"bookshelf": "res://assets/environment/models/bookshelf.glb",
	&"statue": "res://assets/environment/models/statue.glb",
	&"sarcophagus": "res://assets/environment/models/sarcophagus.glb",
	&"urn": "res://assets/environment/models/urn.glb",
	&"bench": "res://assets/environment/models/bench.glb",
	&"painting": "res://assets/environment/models/painting.glb",
	&"chandelier": "res://assets/environment/models/chandelier.glb",
	&"crate": "res://assets/environment/models/crate.glb",
	&"brazier": "res://assets/environment/models/brazier.glb",
	&"reception": "res://assets/environment/models/reception.glb",
	&"mask_case": "res://assets/environment/models/mask_case.glb",
}

var scenes: Dictionary[StringName, PackedScene] = {}
var chests: Array[LootChest] = []

func populate() -> void:
	for id: StringName in MODEL_PATHS:
		scenes[id] = load(MODEL_PATHS[id]) as PackedScene
	for placement: Dictionary in MuseumLayout.PROPS:
		_spawn_prop(placement)
	for placement: Dictionary in MuseumLayout.CHESTS:
		_spawn_chest(placement)

func reset_chests() -> void:
	for chest: LootChest in chests:
		chest.reset()

func _spawn_prop(placement: Dictionary) -> void:
	var root := Node3D.new()
	root.name = String(placement["id"]).to_pascal_case()
	root.position = placement["position"]
	root.rotation.y = placement.get("rotation", 0.0)
	root.add_child(scenes[placement["id"]].instantiate())
	add_child(root)
	if placement.has("collision"):
		_add_collision(root, placement["collision"])

func _spawn_chest(placement: Dictionary) -> void:
	var chest := LootChest.new()
	chest.configure(scenes[&"chest"])
	chest.position = placement["position"]
	chest.rotation.y = placement.get("rotation", 0.0)
	chests.append(chest)
	add_child(chest)

func _add_collision(root: Node3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 4
	body.position.y = size.y * 0.5
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	root.add_child(body)

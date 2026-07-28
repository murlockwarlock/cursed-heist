class_name SimulationAuthority
extends RefCounted

static func can_mutate(node: Node) -> bool:
	return not node.multiplayer.has_multiplayer_peer() or node.multiplayer.is_server()

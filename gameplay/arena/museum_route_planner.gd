class_name MuseumRoutePlanner
extends RefCounted

static func next_target(from: Vector3, destination: Vector3) -> Vector3:
	var from_band := _band(from.z)
	var destination_band := _band(destination.z)
	if from_band == destination_band:
		if from_band != 0:
			var wing_center := 19.0 * from_band
			if absf(from.z - wing_center) > 1.4:
				return Vector3(from.x, 0.0, wing_center)
		return destination
	if from_band != 0:
		var from_center := 19.0 * from_band
		if absf(from.z - from_center) > 1.4:
			return Vector3(from.x, 0.0, from_center)
		var exit_x := _nearest_door(from.x)
		if absf(from.x - exit_x) > 1.4:
			return Vector3(exit_x, 0.0, from_center)
		return Vector3(exit_x, 0.0, 5.5 * from_band)
	var entrance_x := _nearest_door(destination.x)
	if absf(from.x - entrance_x) > 1.4:
		return Vector3(entrance_x, 0.0, from.z)
	return Vector3(entrance_x, 0.0, 11.0 * destination_band)

static func _band(z: float) -> int:
	if z < -8.0:
		return -1
	if z > 8.0:
		return 1
	return 0

static func _nearest_door(x: float) -> float:
	var nearest: float = MuseumLayout.HORIZONTAL_DOORS[0]
	for door_x: float in MuseumLayout.HORIZONTAL_DOORS:
		if absf(x - door_x) < absf(x - nearest):
			nearest = door_x
	return nearest

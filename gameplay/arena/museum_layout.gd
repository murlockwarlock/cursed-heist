class_name MuseumLayout
extends RefCounted

const ZONES: Array[Dictionary] = [
	{"name": &"Foyer", "position": Vector3(-16.2, 0.03, 0.0), "size": Vector3(10.8, 0.06, 12.0), "color": Color("3f214e")},
	{"name": &"MaskGallery", "position": Vector3(-10.5, 0.035, -10.0), "size": Vector3(12.0, 0.07, 8.5), "color": Color("26325c")},
	{"name": &"Archive", "position": Vector3(7.8, 0.035, -10.0), "size": Vector3(14.5, 0.07, 8.5), "color": Color("30374b")},
	{"name": &"Treasury", "position": Vector3(8.0, 0.035, 9.6), "size": Vector3(16.0, 0.07, 9.2), "color": Color("4b252f")},
	{"name": &"Vault", "position": Vector3(17.5, 0.04, 0.0), "size": Vector3(8.5, 0.08, 9.0), "color": Color("203c48")},
	{"name": &"Rotunda", "position": Vector3(0.0, 0.045, 0.0), "size": Vector3(12.0, 0.09, 12.0), "color": Color("362254")},
]

const WALLS: Array[Dictionary] = [
	{"position": Vector3(-9.0, 0.72, -5.8), "size": Vector3(8.0, 1.44, 0.45)},
	{"position": Vector3(-18.8, 0.72, -5.8), "size": Vector3(6.5, 1.44, 0.45)},
	{"position": Vector3(-9.0, 0.72, 5.8), "size": Vector3(8.0, 1.44, 0.45)},
	{"position": Vector3(-18.8, 0.72, 5.8), "size": Vector3(6.5, 1.44, 0.45)},
	{"position": Vector3(4.8, 0.72, -5.8), "size": Vector3(5.0, 1.44, 0.45)},
	{"position": Vector3(13.2, 0.72, -5.8), "size": Vector3(5.0, 1.44, 0.45)},
	{"position": Vector3(4.8, 0.72, 5.8), "size": Vector3(5.0, 1.44, 0.45)},
	{"position": Vector3(13.2, 0.72, 5.8), "size": Vector3(5.0, 1.44, 0.45)},
	{"position": Vector3(14.0, 0.72, -3.1), "size": Vector3(0.45, 1.44, 5.8)},
	{"position": Vector3(14.0, 0.72, 3.1), "size": Vector3(0.45, 1.44, 5.8)},
]

const ARCHES: Array[Dictionary] = [
	{"position": Vector3(-9.0, 0.0, 0.0), "rotated": false},
	{"position": Vector3(9.0, 0.0, 0.0), "rotated": false},
	{"position": Vector3(0.0, 0.0, -5.8), "rotated": true},
	{"position": Vector3(0.0, 0.0, 5.8), "rotated": true},
	{"position": Vector3(-14.0, 0.0, -5.8), "rotated": false},
	{"position": Vector3(-14.0, 0.0, 5.8), "rotated": false},
	{"position": Vector3(9.0, 0.0, -5.8), "rotated": false},
	{"position": Vector3(9.0, 0.0, 5.8), "rotated": false},
	{"position": Vector3(14.0, 0.0, 0.0), "rotated": true},
]

const PROPS: Array[Dictionary] = [
	{"id": &"reception", "position": Vector3(-20.4, 0.0, 0.0), "rotation": 0.0, "collision": Vector3(3.6, 1.5, 1.1)},
	{"id": &"bench", "position": Vector3(-15.2, 0.0, -3.5), "rotation": 0.0, "collision": Vector3(2.5, 0.9, 0.8)},
	{"id": &"bench", "position": Vector3(-15.2, 0.0, 3.5), "rotation": 0.0, "collision": Vector3(2.5, 0.9, 0.8)},
	{"id": &"statue", "position": Vector3(-20.3, 0.0, -4.2), "rotation": 0.3, "collision": Vector3(1.2, 2.5, 1.0)},
	{"id": &"statue", "position": Vector3(-20.3, 0.0, 4.2), "rotation": -0.3, "collision": Vector3(1.2, 2.5, 1.0)},
	{"id": &"painting", "position": Vector3(-21.85, 1.1, -8.5), "rotation": -PI * 0.5},
	{"id": &"painting", "position": Vector3(-21.85, 1.1, 8.5), "rotation": -PI * 0.5},
	{"id": &"chandelier", "position": Vector3(-16.0, 2.7, 0.0), "rotation": 0.0},
	{"id": &"mask_case", "position": Vector3(-13.0, 0.0, -10.3), "rotation": 0.15, "collision": Vector3(1.1, 2.2, 0.9)},
	{"id": &"mask_case", "position": Vector3(-9.3, 0.0, -11.5), "rotation": -0.2, "collision": Vector3(1.1, 2.2, 0.9)},
	{"id": &"mask_case", "position": Vector3(-6.0, 0.0, -9.2), "rotation": 0.25, "collision": Vector3(1.1, 2.2, 0.9)},
	{"id": &"sarcophagus", "position": Vector3(-17.8, 0.0, -10.4), "rotation": PI * 0.5, "collision": Vector3(1.2, 1.1, 2.6)},
	{"id": &"brazier", "position": Vector3(-5.4, 0.0, -13.4), "rotation": 0.0, "collision": Vector3(1.2, 1.9, 1.2)},
	{"id": &"bookshelf", "position": Vector3(3.0, 0.0, -13.2), "rotation": 0.0, "collision": Vector3(2.6, 3.2, 0.7)},
	{"id": &"bookshelf", "position": Vector3(7.0, 0.0, -10.5), "rotation": PI * 0.5, "collision": Vector3(0.7, 3.2, 2.6)},
	{"id": &"bookshelf", "position": Vector3(11.0, 0.0, -13.2), "rotation": 0.0, "collision": Vector3(2.6, 3.2, 0.7)},
	{"id": &"bookshelf", "position": Vector3(11.0, 0.0, -8.1), "rotation": 0.0, "collision": Vector3(2.6, 3.2, 0.7)},
	{"id": &"bookshelf", "position": Vector3(3.0, 0.0, -8.1), "rotation": 0.0, "collision": Vector3(2.6, 3.2, 0.7)},
	{"id": &"urn", "position": Vector3(5.1, 0.0, -10.4), "rotation": 0.0, "collision": Vector3(1.1, 1.6, 1.1)},
	{"id": &"brazier", "position": Vector3(13.0, 0.0, -10.3), "rotation": 0.0, "collision": Vector3(1.2, 1.9, 1.2)},
	{"id": &"chandelier", "position": Vector3(8.0, 2.7, -10.0), "rotation": 0.0},
	{"id": &"crate", "position": Vector3(3.5, 0.0, 8.2), "rotation": 0.18, "collision": Vector3(1.15, 1.15, 1.15)},
	{"id": &"crate", "position": Vector3(5.0, 0.0, 9.0), "rotation": -0.12, "collision": Vector3(1.15, 1.15, 1.15)},
	{"id": &"crate", "position": Vector3(11.8, 0.0, 12.5), "rotation": 0.28, "collision": Vector3(1.15, 1.15, 1.15)},
	{"id": &"urn", "position": Vector3(7.0, 0.0, 12.7), "rotation": 0.0, "collision": Vector3(1.1, 1.6, 1.1)},
	{"id": &"urn", "position": Vector3(12.5, 0.0, 7.2), "rotation": 0.0, "collision": Vector3(1.1, 1.6, 1.1)},
	{"id": &"sarcophagus", "position": Vector3(16.5, 0.0, 8.7), "rotation": 0.0, "collision": Vector3(1.2, 1.1, 2.6)},
	{"id": &"brazier", "position": Vector3(2.0, 0.0, 13.4), "rotation": 0.0, "collision": Vector3(1.2, 1.9, 1.2)},
	{"id": &"brazier", "position": Vector3(13.4, 0.0, 13.3), "rotation": 0.0, "collision": Vector3(1.2, 1.9, 1.2)},
	{"id": &"statue", "position": Vector3(-4.2, 0.0, -4.2), "rotation": 0.6, "collision": Vector3(1.2, 2.5, 1.0)},
	{"id": &"statue", "position": Vector3(4.2, 0.0, 4.2), "rotation": -2.5, "collision": Vector3(1.2, 2.5, 1.0)},
	{"id": &"mask_case", "position": Vector3(4.2, 0.0, -4.2), "rotation": -0.6, "collision": Vector3(1.1, 2.2, 0.9)},
	{"id": &"mask_case", "position": Vector3(-4.2, 0.0, 4.2), "rotation": 2.5, "collision": Vector3(1.1, 2.2, 0.9)},
	{"id": &"brazier", "position": Vector3(15.8, 0.0, -3.3), "rotation": 0.0, "collision": Vector3(1.2, 1.9, 1.2)},
	{"id": &"brazier", "position": Vector3(15.8, 0.0, 3.3), "rotation": 0.0, "collision": Vector3(1.2, 1.9, 1.2)},
]

const CHESTS: Array[Dictionary] = [
	{"position": Vector3(-7.0, 0.0, -13.0), "rotation": 0.15},
	{"position": Vector3(2.2, 0.0, -8.2), "rotation": -0.15},
	{"position": Vector3(3.0, 0.0, 11.6), "rotation": 0.12},
	{"position": Vector3(9.0, 0.0, 8.4), "rotation": -0.18},
	{"position": Vector3(13.0, 0.0, 11.4), "rotation": 0.2},
	{"position": Vector3(17.6, 0.0, -2.8), "rotation": PI * 0.5},
]

const ROTUNDA_LIGHTS: Array[Vector3] = [
	Vector3(-5.2, 0.0, 0.0),
	Vector3(5.2, 0.0, 0.0),
	Vector3(0.0, 0.0, -5.2),
	Vector3(0.0, 0.0, 5.2),
]

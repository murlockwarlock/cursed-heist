class_name MuseumLighting
extends Node3D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("080512"))
	_build_environment()
	_build_lights()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("090319")
	sky_material.sky_horizon_color = Color("2d164b")
	sky_material.ground_bottom_color = Color("05020c")
	sky_material.ground_horizon_color = Color("201036")
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("7755aa")
	environment.ambient_light_energy = 0.52
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("301c4b")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.006
	world_environment.environment = environment
	add_child(world_environment)

func _build_lights() -> void:
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("a895ff")
	moon.light_energy = 1.15
	moon.rotation_degrees = Vector3(-56.0, -38.0, 0.0)
	moon.shadow_enabled = true
	add_child(moon)
	var positions: Array[Vector3] = []
	for x: float in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		for z: float in [-10.0, 0.0, 10.0]:
			positions.append(Vector3(x, 4.5, z))
	for index: int in range(positions.size()):
		var light := OmniLight3D.new()
		light.position = positions[index]
		light.light_color = Color("a957ff") if index % 3 == 1 else Color("ffbf62")
		light.light_energy = 2.8
		light.omni_range = 8.5
		light.shadow_enabled = index % 2 == 0
		add_child(light)

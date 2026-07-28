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
	environment.ambient_light_energy = 0.46
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.08
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 1.08
	environment.fog_enabled = true
	environment.fog_light_color = Color("301c4b")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.0035
	world_environment.environment = environment
	add_child(world_environment)

func _build_lights() -> void:
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("a895ff")
	moon.light_energy = 0.82
	moon.rotation_degrees = Vector3(-56.0, -38.0, 0.0)
	moon.shadow_enabled = true
	add_child(moon)
	for index: int in range(MuseumLayout.ROOMS.size()):
		var room: Dictionary = MuseumLayout.ROOMS[index]
		var light := OmniLight3D.new()
		light.position = room["position"] + Vector3.UP * 4.2
		light.light_color = room["light"]
		light.light_energy = room["energy"]
		light.omni_range = maxf(room["size"].x, room["size"].z) * 0.72
		light.shadow_enabled = index in [0, 6]
		add_child(light)

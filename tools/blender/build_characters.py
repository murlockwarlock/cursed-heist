import math
import os

import bpy
from mathutils import Vector


PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
MODEL_DIR = os.path.join(PROJECT_DIR, "assets/characters/models")
SOURCE_DIR = os.path.join(PROJECT_DIR, "assets/characters/source")
PREVIEW_PATH = os.path.join(PROJECT_DIR, "assets/visual/blender_character_roster.png")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)


def material(name, color, metallic=0.0, roughness=0.45, emission=0.0):
    value = bpy.data.materials.get(name)
    if value:
        return value
    value = bpy.data.materials.new(name)
    value.diffuse_color = (*color, 1.0)
    value.use_nodes = True
    shader = value.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    metallic_input = shader.inputs.get("Metallic") or shader.inputs.get("Metallic IOR Level")
    metallic_input.default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        shader.inputs["Emission Color"].default_value = (*color, 1.0)
        shader.inputs["Emission Strength"].default_value = emission
    return value


def move_to_collection(obj, collection):
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def empty(name, collection, parent=None, location=(0.0, 0.0, 0.0)):
    obj = bpy.data.objects.new(name, None)
    collection.objects.link(obj)
    obj.parent = parent
    obj.location = location
    return obj


def finish_mesh(obj, name, collection, parent, location, scale, mat, rotation=(0.0, 0.0, 0.0), bevel=0.0):
    obj.name = name
    move_to_collection(obj, collection)
    obj.parent = parent
    obj.location = location
    obj.rotation_euler = rotation
    obj.scale = scale
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new("SoftBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.data.materials.append(mat)
    return obj


def sphere(name, collection, parent, location, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20)
    return finish_mesh(bpy.context.object, name, collection, parent, location, scale, mat)


def box(name, collection, parent, location, scale, mat, rotation=(0.0, 0.0, 0.0), bevel=0.08):
    bpy.ops.mesh.primitive_cube_add()
    return finish_mesh(bpy.context.object, name, collection, parent, location, scale, mat, rotation, bevel)


def cylinder(name, collection, parent, location, radius, depth, mat, rotation=(0.0, 0.0, 0.0), vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth)
    return finish_mesh(bpy.context.object, name, collection, parent, location, (1.0, 1.0, 1.0), mat, rotation, 0.035)


def cone(name, collection, parent, location, radius, depth, mat, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=radius, radius2=0.025, depth=depth)
    return finish_mesh(bpy.context.object, name, collection, parent, location, (1.0, 1.0, 1.0), mat, rotation, 0.025)


def torus(name, collection, parent, location, major_radius, minor_radius, mat, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_radius, minor_radius=minor_radius, major_segments=32, minor_segments=12)
    return finish_mesh(bpy.context.object, name, collection, parent, location, (1.0, 1.0, 1.0), mat, rotation)


def curve(name, collection, parent, points, radius, mat):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.bevel_depth = radius
    data.bevel_resolution = 4
    spline = data.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for index, point in enumerate(points):
        handle = spline.bezier_points[index]
        handle.co = point
        handle.handle_left_type = "AUTO"
        handle.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(mat)
    return obj


def create_parts(name):
    collection = bpy.data.collections.new(name.capitalize())
    bpy.context.scene.collection.children.link(collection)
    root = empty(name.capitalize(), collection)
    parts = {
        "root": root,
        "body": empty("BodyRoot", collection, root),
        "face": empty("FaceRoot", collection, root),
        "accessories": empty("AccessoryRoot", collection, root),
        "left_leg": empty("LeftLeg", collection, root),
        "right_leg": empty("RightLeg", collection, root),
        "left_arm": empty("LeftArm", collection, root),
        "right_arm": empty("RightArm", collection, root),
    }
    return collection, parts


def add_eyes(collection, parent, z, spacing, glow, scale=(0.08, 0.035, 0.11)):
    sphere("EyeL", collection, parent, (-spacing, -0.455, z), scale, glow)
    sphere("EyeR", collection, parent, (spacing, -0.455, z), scale, glow)


def add_belt(collection, parent, z, width, gold, accent):
    box("Belt", collection, parent, (0.0, -0.01, z), (width, 0.36, 0.055), gold, bevel=0.025)
    box("Accent_Buckle", collection, parent, (0.0, -0.39, z), (0.11, 0.045, 0.1), accent, bevel=0.025)


def build_vix(materials):
    collection, p = create_parts("vix")
    dark, cloth, accent, gold, mask, glow = materials
    p["body"].location.z = 1.05
    sphere("Torso", collection, p["body"], (0.0, 0.0, 0.0), (0.42, 0.32, 0.63), dark)
    sphere("Coat", collection, p["body"], (0.0, -0.04, 0.14), (0.46, 0.34, 0.37), cloth)
    p["face"].location.z = 1.68
    sphere("Hood", collection, p["face"], (0.0, 0.0, 0.0), (0.53, 0.46, 0.52), cloth)
    sphere("Mask", collection, p["face"], (0.0, -0.41, -0.03), (0.35, 0.08, 0.26), mask)
    add_eyes(collection, p["face"], 0.01, 0.13, glow, (0.07, 0.032, 0.095))
    cone("EarL", collection, p["face"], (-0.28, 0.0, 0.52), 0.19, 0.62, cloth, (0.0, -0.12, -0.1))
    cone("EarR", collection, p["face"], (0.28, 0.0, 0.52), 0.19, 0.62, cloth, (0.0, 0.12, 0.1))
    for side, key in [(-1.0, "left_leg"), (1.0, "right_leg")]:
        p[key].location = (side * 0.22, 0.0, 0.54)
        sphere("Boot", collection, p[key], (0.0, -0.05, -0.26), (0.17, 0.23, 0.34), dark)
        torus("GoldBootRing", collection, p[key], (0.0, 0.0, -0.02), 0.17, 0.035, gold)
    for side, key in [(-1.0, "left_arm"), (1.0, "right_arm")]:
        p[key].location = (side * 0.49, 0.0, 1.18)
        sphere("Sleeve", collection, p[key], (0.0, 0.0, -0.2), (0.14, 0.14, 0.42), cloth)
        sphere("Glove", collection, p[key], (0.0, -0.02, -0.49), (0.16, 0.15, 0.16), dark)
    add_belt(collection, p["accessories"], 0.94, 0.43, gold, accent)
    curve("Accent_Scarf", collection, p["accessories"], [(0.2, 0.2, 1.52), (0.62, 0.32, 1.32), (0.92, 0.12, 1.16)], 0.075, accent)
    curve("Accent_Tail", collection, p["accessories"], [(0.22, 0.22, 0.85), (0.65, 0.48, 0.82), (0.86, 0.34, 1.13), (0.67, 0.2, 1.38)], 0.16, accent)
    return collection, p["root"]


def build_bulwark(materials):
    collection, p = create_parts("bulwark")
    dark, cloth, accent, gold, mask, glow = materials
    stone = material("Stone", (0.21, 0.19, 0.25), 0.05, 0.66)
    p["body"].location.z = 1.0
    sphere("StoneCore", collection, p["body"], (0.0, 0.0, 0.0), (0.74, 0.52, 0.72), stone)
    box("ShoulderSlab", collection, p["body"], (0.0, 0.0, 0.35), (0.72, 0.39, 0.19), cloth, bevel=0.12)
    p["face"].location.z = 1.62
    box("HoodBlock", collection, p["face"], (0.0, 0.0, 0.0), (0.43, 0.37, 0.36), cloth, bevel=0.15)
    box("FaceVoid", collection, p["face"], (0.0, -0.37, -0.03), (0.3, 0.05, 0.16), dark, bevel=0.08)
    add_eyes(collection, p["face"], -0.03, 0.16, glow, (0.085, 0.025, 0.075))
    for side, key in [(-1.0, "left_leg"), (1.0, "right_leg")]:
        p[key].location = (side * 0.34, 0.0, 0.55)
        box("StoneFoot", collection, p[key], (0.0, -0.07, -0.23), (0.28, 0.34, 0.32), stone, bevel=0.1)
        box("GoldToe", collection, p[key], (0.0, -0.36, -0.3), (0.27, 0.07, 0.12), gold, bevel=0.04)
    for side, key in [(-1.0, "left_arm"), (1.0, "right_arm")]:
        p[key].location = (side * 0.78, 0.0, 1.2)
        sphere("BoulderArm", collection, p[key], (0.0, 0.0, -0.2), (0.3, 0.28, 0.48), stone)
        box("GoldBracer", collection, p[key], (0.0, -0.01, -0.38), (0.31, 0.29, 0.18), gold, bevel=0.07)
        sphere("StoneFist", collection, p[key], (0.0, -0.03, -0.63), (0.34, 0.32, 0.31), stone)
    torus("VaultRing", collection, p["accessories"], (0.0, -0.55, 1.03), 0.29, 0.075, gold, (math.pi / 2.0, 0.0, 0.0))
    cylinder("Accent_Keyhole", collection, p["accessories"], (0.0, -0.63, 1.03), 0.12, 0.04, accent, (math.pi / 2.0, 0.0, 0.0))
    for x, z, tilt in [(-0.4, 1.18, -0.5), (0.32, 0.82, 0.4), (0.1, 1.52, -0.25)]:
        box("Accent_Rune", collection, p["accessories"], (x, -0.53, z), (0.025, 0.025, 0.16), glow, (0.0, tilt, 0.0), 0.01)
    return collection, p["root"]


def build_mirage(materials):
    collection, p = create_parts("mirage")
    dark, cloth, accent, gold, mask, glow = materials
    p["body"].location.z = 1.15
    sphere("TailoredTorso", collection, p["body"], (0.0, 0.0, 0.0), (0.34, 0.26, 0.7), dark)
    box("HighCollar", collection, p["body"], (0.0, 0.0, 0.42), (0.43, 0.3, 0.18), cloth, bevel=0.08)
    p["face"].location.z = 1.83
    sphere("CrescentHood", collection, p["face"], (0.0, 0.0, 0.0), (0.46, 0.4, 0.5), cloth)
    sphere("PorcelainMask", collection, p["face"], (0.0, -0.37, -0.03), (0.29, 0.065, 0.36), mask)
    add_eyes(collection, p["face"], 0.03, 0.105, glow, (0.052, 0.025, 0.08))
    cone("CrescentTip", collection, p["face"], (0.12, 0.05, 0.62), 0.35, 1.05, cloth, (0.0, 0.4, -0.2))
    torus("GoldHoodBand", collection, p["face"], (0.0, 0.0, 0.22), 0.42, 0.035, gold)
    for side, key in [(-1.0, "left_leg"), (1.0, "right_leg")]:
        p[key].location = (side * 0.2, 0.0, 0.64)
        sphere("Boot", collection, p[key], (0.0, -0.05, -0.31), (0.14, 0.18, 0.43), dark)
        cone("GoldToe", collection, p[key], (0.0, -0.25, -0.43), 0.14, 0.32, gold, (math.pi / 2.0, 0.0, 0.0))
    for side, key in [(-1.0, "left_arm"), (1.0, "right_arm")]:
        p[key].location = (side * 0.46, 0.0, 1.4)
        sphere("Sleeve", collection, p[key], (0.0, 0.0, -0.26), (0.12, 0.12, 0.46), cloth)
        sphere("Glove", collection, p[key], (0.0, -0.02, -0.55), (0.13, 0.12, 0.16), dark)
    for side in [-1.0, 1.0]:
        box("Accent_CoatTail", collection, p["accessories"], (side * 0.23, 0.18, 0.64), (0.2, 0.09, 0.62), accent, (0.0, side * 0.12, side * 0.12), 0.07)
    add_belt(collection, p["accessories"], 1.02, 0.36, gold, accent)
    sphere("Accent_Brooch", collection, p["accessories"], (0.0, -0.31, 1.42), (0.11, 0.045, 0.11), glow)
    return collection, p["root"]


def build_bubbles(materials):
    collection, p = create_parts("bubbles")
    dark, cloth, accent, gold, mask, glow = materials
    leather = material("Leather", (0.25, 0.14, 0.1), 0.05, 0.58)
    p["body"].location.z = 0.88
    sphere("RoundBody", collection, p["body"], (0.0, 0.0, 0.0), (0.68, 0.55, 0.67), dark)
    sphere("Apron", collection, p["body"], (0.0, -0.36, -0.04), (0.52, 0.12, 0.48), cloth)
    p["face"].location.z = 1.5
    sphere("PaddedHood", collection, p["face"], (0.0, 0.0, 0.0), (0.57, 0.48, 0.49), cloth)
    box("FaceVoid", collection, p["face"], (0.0, -0.43, -0.02), (0.34, 0.055, 0.2), dark, bevel=0.1)
    for side in [-1.0, 1.0]:
        torus("GoldGoggle", collection, p["face"], (side * 0.2, -0.5, 0.03), 0.16, 0.05, gold, (math.pi / 2.0, 0.0, 0.0))
        sphere("Accent_Lens", collection, p["face"], (side * 0.2, -0.525, 0.03), (0.13, 0.025, 0.13), glow)
    for side, key in [(-1.0, "left_leg"), (1.0, "right_leg")]:
        p[key].location = (side * 0.29, 0.0, 0.43)
        sphere("Boot", collection, p[key], (0.0, -0.05, -0.18), (0.22, 0.27, 0.27), dark)
    for side, key in [(-1.0, "left_arm"), (1.0, "right_arm")]:
        p[key].location = (side * 0.66, 0.0, 0.98)
        sphere("Sleeve", collection, p[key], (0.0, 0.0, -0.18), (0.2, 0.2, 0.36), cloth)
        sphere("Glove", collection, p[key], (0.0, -0.02, -0.43), (0.2, 0.18, 0.19), dark)
    box("Backpack", collection, p["accessories"], (0.0, 0.48, 1.02), (0.48, 0.24, 0.52), leather, bevel=0.13)
    for x, z, size in [(-0.28, 1.35, 0.13), (0.0, 1.52, 0.16), (0.28, 1.31, 0.12)]:
        sphere("Accent_Potion", collection, p["accessories"], (x, 0.69, z), (size, size, size * 1.35), glow)
        cylinder("GoldCork", collection, p["accessories"], (x, 0.69, z + size * 1.35), size * 0.34, size * 0.55, gold)
    add_belt(collection, p["accessories"], 0.72, 0.57, gold, accent)
    return collection, p["root"]


def export_character(name, collection):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = collection.objects.get(name.capitalize())
    path = os.path.join(MODEL_DIR, f"{name}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)


def point_camera(camera, target):
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


def build_preview(roots):
    for root, x in zip(roots, [-3.6, -1.25, 1.25, 3.6]):
        root.location.x = x
    ground = material("StudioGround", (0.035, 0.025, 0.055), 0.0, 0.58)
    bpy.ops.mesh.primitive_plane_add(size=24, location=(0.0, 0.0, 0.0))
    bpy.context.object.data.materials.append(ground)
    bpy.ops.object.camera_add(location=(0.0, -13.5, 4.6))
    camera = bpy.context.object
    point_camera(camera, (0.0, 0.0, 1.25))
    camera.data.lens = 58
    bpy.context.scene.camera = camera
    for location, energy, size, color in [((-5.0, -5.0, 7.0), 1500.0, 4.0, (1.0, 0.58, 0.32)), ((5.0, -2.0, 6.0), 1250.0, 3.0, (0.48, 0.28, 1.0)), ((0.0, 4.0, 7.0), 1800.0, 5.0, (0.62, 0.42, 1.0))]:
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        point_camera(light, (0.0, 0.0, 1.1))
    world = bpy.context.scene.world
    world.color = (0.012, 0.008, 0.025)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = PREVIEW_PATH
    scene.render.film_transparent = False
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE_DIR, "character_roster.blend"))
    bpy.ops.render.render(write_still=True)


def main():
    os.makedirs(MODEL_DIR, exist_ok=True)
    os.makedirs(SOURCE_DIR, exist_ok=True)
    clear_scene()
    materials = (
        material("Dark", (0.035, 0.025, 0.055), 0.02, 0.42),
        material("Cloth", (0.12, 0.065, 0.19), 0.0, 0.55),
        material("Accent_Customizable", (0.45, 0.08, 0.8), 0.08, 0.32, 0.6),
        material("Gold", (0.62, 0.34, 0.08), 0.72, 0.24),
        material("Mask", (0.78, 0.76, 0.72), 0.04, 0.3),
        material("Glow", (0.55, 0.12, 1.0), 0.02, 0.24, 4.0),
    )
    builders = {
        "vix": build_vix,
        "bulwark": build_bulwark,
        "mirage": build_mirage,
        "bubbles": build_bubbles,
    }
    roots = []
    for name, builder in builders.items():
        collection, root = builder(materials)
        export_character(name, collection)
        roots.append(root)
    build_preview(roots)


main()

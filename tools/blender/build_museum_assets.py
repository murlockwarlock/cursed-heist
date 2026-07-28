import math
import os
import random

import bpy
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODEL_DIR = os.path.join(ROOT, "assets", "environment", "models")
SOURCE_PATH = os.path.join(ROOT, "assets", "environment", "source", "museum_assets.blend")
PREVIEW_PATH = os.path.join(ROOT, "assets", "visual", "museum_asset_kit.png")

PALETTE = {
    "stone": (0.13, 0.075, 0.22, 1.0),
    "stone_light": (0.26, 0.16, 0.38, 1.0),
    "wood": (0.18, 0.075, 0.035, 1.0),
    "wood_light": (0.34, 0.13, 0.055, 1.0),
    "gold": (0.95, 0.52, 0.08, 1.0),
    "purple": (0.48, 0.08, 0.82, 1.0),
    "lime": (0.34, 0.95, 0.22, 1.0),
    "coral": (1.0, 0.18, 0.27, 1.0),
    "cream": (0.94, 0.77, 0.48, 1.0),
    "glass": (0.2, 0.75, 0.95, 0.24),
}


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(name, color, metallic=0.0, roughness=0.48, emission=None):
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    mat.use_nodes = True
    node = mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = color
    node.inputs["Metallic"].default_value = metallic
    node.inputs["Roughness"].default_value = roughness
    node.inputs["Alpha"].default_value = color[3]
    if color[3] < 1.0:
        mat.surface_render_method = "DITHERED"
    if emission:
        node.inputs["Emission Color"].default_value = emission
        node.inputs["Emission Strength"].default_value = 3.0
    return mat


def cube(name, location, scale, color, bevel=0.08, metallic=0.0):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] * 0.5, scale[1] * 0.5, scale[2] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material(color, PALETTE[color], metallic))
    if bevel > 0.0:
        modifier = obj.modifiers.new("ChunkyBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return obj


def cylinder(name, location, radius, depth, color, vertices=12, metallic=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material(color, PALETTE[color], metallic))
    modifier = obj.modifiers.new("ChunkyBevel", "BEVEL")
    modifier.width = min(radius * 0.12, 0.08)
    modifier.segments = 2
    return obj


def sphere(name, location, scale, color, metallic=0.0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material(color, PALETTE[color], metallic))
    return obj


def torus(name, location, major_radius, minor_radius, color, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_radius, minor_radius=minor_radius, major_segments=16, minor_segments=6, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material(color, PALETTE[color], 0.75))
    return obj


def build_chest():
    root = bpy.data.objects.new("Chest", None)
    bpy.context.collection.objects.link(root)
    for part in [
        cube("ChestBody", (0, 0, 0.52), (1.55, 0.95, 0.82), "wood", 0.12),
        cube("BodyBandA", (-0.55, 0, 0.54), (0.14, 1.02, 0.9), "gold", 0.04, 0.8),
        cube("BodyBandB", (0.55, 0, 0.54), (0.14, 1.02, 0.9), "gold", 0.04, 0.8),
        cube("Lock", (0, -0.5, 0.58), (0.34, 0.12, 0.4), "gold", 0.06, 0.8),
    ]:
        part.parent = root
    lid = bpy.data.objects.new("Lid", None)
    bpy.context.collection.objects.link(lid)
    lid.location = (0, 0.42, 0.98)
    lid.parent = root
    for part in [
        cube("LidWood", (0, -0.42, 0.16), (1.58, 0.95, 0.36), "wood_light", 0.15),
        cube("LidBandA", (-0.55, -0.42, 0.16), (0.14, 1.02, 0.42), "gold", 0.04, 0.8),
        cube("LidBandB", (0.55, -0.42, 0.16), (0.14, 1.02, 0.42), "gold", 0.04, 0.8),
    ]:
        part.parent = lid
    sphere("ChestEye", (0, -0.61, 0.72), (0.12, 0.06, 0.1), "purple", 0.25).parent = root


def build_bookshelf():
    root = bpy.data.objects.new("Bookshelf", None)
    bpy.context.collection.objects.link(root)
    for x in (-1.15, 1.15):
        cube("Frame", (x, 0, 1.6), (0.22, 0.55, 3.2), "wood_light", 0.06).parent = root
    for z in (0.18, 1.05, 1.92, 2.78):
        cube("Shelf", (0, 0, z), (2.55, 0.62, 0.18), "wood_light", 0.05).parent = root
    colors = ["purple", "coral", "gold", "lime", "cream"]
    random.seed(18)
    for row in range(3):
        cursor = -1.0
        while cursor < 0.92:
            width = random.uniform(0.16, 0.3)
            height = random.uniform(0.48, 0.72)
            book = cube("Book", (cursor + width * 0.5, -0.19, 0.29 + row * 0.87 + height * 0.5), (width, 0.32, height), random.choice(colors), 0.025)
            book.rotation_euler.y = random.uniform(-0.08, 0.08)
            book.parent = root
            cursor += width + 0.055


def build_statue():
    root = bpy.data.objects.new("GargoyleStatue", None)
    bpy.context.collection.objects.link(root)
    cube("Plinth", (0, 0, 0.25), (1.15, 0.95, 0.5), "stone_light", 0.12).parent = root
    cube("PlinthTop", (0, 0, 0.56), (0.9, 0.78, 0.18), "gold", 0.05, 0.5).parent = root
    sphere("Body", (0, 0, 1.28), (0.52, 0.4, 0.72), "stone_light").parent = root
    sphere("Head", (0, -0.05, 2.02), (0.43, 0.38, 0.4), "stone_light").parent = root
    for x in (-0.24, 0.24):
        ear = cube("Ear", (x, -0.02, 2.42), (0.25, 0.2, 0.48), "stone_light", 0.06)
        ear.rotation_euler.y = -x * 0.7
        ear.parent = root
        sphere("Eye", (x * 0.75, -0.4, 2.08), (0.075, 0.045, 0.075), "lime", 0.15).parent = root
    for x in (-0.46, 0.46):
        wing = cube("Wing", (x, 0.1, 1.45), (0.34, 0.16, 1.05), "stone", 0.07)
        wing.rotation_euler.y = x * 0.9
        wing.parent = root


def build_sarcophagus():
    root = bpy.data.objects.new("Sarcophagus", None)
    bpy.context.collection.objects.link(root)
    cube("StoneCoffin", (0, 0, 0.42), (1.15, 2.55, 0.74), "stone_light", 0.14).parent = root
    cube("GoldInset", (0, 0, 0.84), (0.86, 2.22, 0.12), "gold", 0.06, 0.72).parent = root
    sphere("Face", (0, -0.64, 0.96), (0.29, 0.4, 0.16), "cream").parent = root
    for y in (-0.15, 0.3, 0.72):
        cube("Band", (0, y, 0.94), (0.92, 0.1, 0.15), "purple", 0.03).parent = root


def build_urn():
    root = bpy.data.objects.new("CursedUrn", None)
    bpy.context.collection.objects.link(root)
    cylinder("Foot", (0, 0, 0.12), 0.35, 0.24, "gold", 12, 0.7).parent = root
    sphere("UrnBody", (0, 0, 0.68), (0.55, 0.55, 0.68), "purple", 0.15).parent = root
    cylinder("Neck", (0, 0, 1.18), 0.29, 0.38, "gold", 12, 0.7).parent = root
    cylinder("Lid", (0, 0, 1.43), 0.42, 0.14, "gold", 12, 0.7).parent = root
    sphere("Glow", (0, -0.49, 0.75), (0.12, 0.05, 0.12), "lime").parent = root


def build_bench():
    root = bpy.data.objects.new("MuseumBench", None)
    bpy.context.collection.objects.link(root)
    cube("Seat", (0, 0, 0.72), (2.4, 0.72, 0.22), "coral", 0.12).parent = root
    cube("Trim", (0, -0.37, 0.72), (2.45, 0.1, 0.25), "gold", 0.04, 0.7).parent = root
    for x in (-0.88, 0.88):
        cube("Leg", (x, 0, 0.35), (0.2, 0.58, 0.7), "wood_light", 0.06).parent = root


def build_painting():
    root = bpy.data.objects.new("HauntedPainting", None)
    bpy.context.collection.objects.link(root)
    cube("Frame", (0, 0.02, 1.25), (1.7, 0.15, 2.5), "gold", 0.12, 0.76).parent = root
    cube("Canvas", (0, -0.08, 1.25), (1.38, 0.08, 2.15), "purple", 0.02).parent = root
    sphere("PortraitHead", (0, -0.15, 1.55), (0.34, 0.06, 0.42), "cream").parent = root
    cube("PortraitBody", (0, -0.14, 0.75), (0.75, 0.08, 0.7), "coral", 0.12).parent = root
    for x in (-0.13, 0.13):
        sphere("PortraitEye", (x, -0.22, 1.62), (0.055, 0.025, 0.065), "lime").parent = root


def build_chandelier():
    root = bpy.data.objects.new("Chandelier", None)
    bpy.context.collection.objects.link(root)
    cylinder("Chain", (0, 0, 2.25), 0.06, 1.5, "gold", 8, 0.8).parent = root
    torus("Ring", (0, 0, 1.35), 0.95, 0.09, "gold").parent = root
    for index in range(8):
        angle = index * math.tau / 8.0
        x = math.cos(angle) * 0.95
        y = math.sin(angle) * 0.95
        cylinder("Candle", (x, y, 1.55), 0.07, 0.38, "cream", 8).parent = root
        sphere("Flame", (x, y, 1.83), (0.1, 0.1, 0.18), "coral").parent = root


def build_crate():
    root = bpy.data.objects.new("BreakableCrate", None)
    bpy.context.collection.objects.link(root)
    cube("CrateBody", (0, 0, 0.55), (1.1, 1.1, 1.1), "wood", 0.08).parent = root
    for z in (0.12, 0.98):
        cube("Band", (0, -0.57, z), (1.18, 0.09, 0.14), "gold", 0.03, 0.5).parent = root
    for tilt in (-0.68, 0.68):
        brace = cube("Brace", (0, -0.59, 0.55), (0.14, 0.08, 1.28), "wood_light", 0.03)
        brace.rotation_euler.y = tilt
        brace.parent = root


def build_brazier():
    root = bpy.data.objects.new("CursedBrazier", None)
    bpy.context.collection.objects.link(root)
    cylinder("Foot", (0, 0, 0.12), 0.42, 0.24, "stone_light", 10).parent = root
    cylinder("Stem", (0, 0, 0.72), 0.16, 1.0, "gold", 10, 0.65).parent = root
    bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.72, radius2=0.48, depth=0.46, location=(0, 0, 1.35))
    bowl = bpy.context.object
    bowl.name = "Bowl"
    bowl.data.materials.append(material("stone", PALETTE["stone"], 0.15))
    bowl.parent = root
    for offset in ((0, 0, 0), (-0.16, 0.06, -0.06), (0.15, 0.04, -0.08)):
        flame = sphere("Flame", (offset[0], offset[1], 1.82 + offset[2]), (0.2, 0.2, 0.45), "lime")
        flame.parent = root


def build_reception():
    root = bpy.data.objects.new("ReceptionDesk", None)
    bpy.context.collection.objects.link(root)
    cube("Desk", (0, 0, 0.72), (3.5, 1.0, 1.35), "wood", 0.16).parent = root
    cube("Counter", (0, -0.05, 1.45), (3.75, 1.15, 0.18), "gold", 0.06, 0.55).parent = root
    cube("FrontInset", (0, -0.54, 0.72), (2.5, 0.08, 0.75), "purple", 0.06).parent = root
    sphere("Bell", (0.95, -0.22, 1.66), (0.17, 0.17, 0.16), "gold", 0.75).parent = root


def build_mask_case():
    root = bpy.data.objects.new("MaskDisplay", None)
    bpy.context.collection.objects.link(root)
    cube("Plinth", (0, 0, 0.42), (1.1, 0.9, 0.84), "stone_light", 0.1).parent = root
    cube("Glass", (0, 0, 1.45), (0.9, 0.72, 1.3), "glass", 0.03).parent = root
    sphere("Mask", (0, -0.2, 1.48), (0.3, 0.1, 0.43), "gold", 0.62).parent = root
    for x in (-0.12, 0.12):
        sphere("EyeHole", (x, -0.3, 1.56), (0.055, 0.025, 0.075), "stone").parent = root


def build_plant():
    root = bpy.data.objects.new("MoonPlant", None)
    bpy.context.collection.objects.link(root)
    cylinder("Pot", (0, 0, 0.34), 0.42, 0.68, "coral", 10).parent = root
    cylinder("Stem", (0, 0, 1.0), 0.08, 0.8, "wood", 8).parent = root
    for index in range(7):
        angle = index * math.tau / 7.0
        leaf = sphere("Leaf", (math.cos(angle) * 0.34, math.sin(angle) * 0.34, 1.34 + index % 2 * 0.18), (0.18, 0.42, 0.16), "lime")
        leaf.rotation_euler.z = angle
        leaf.parent = root
    sphere("Bloom", (0, 0, 1.72), (0.26, 0.26, 0.28), "purple").parent = root


def build_armor():
    root = bpy.data.objects.new("ArmorDisplay", None)
    bpy.context.collection.objects.link(root)
    cube("Plinth", (0, 0, 0.18), (1.0, 0.85, 0.36), "stone_light", 0.1).parent = root
    cube("Torso", (0, 0, 1.35), (0.72, 0.42, 0.86), "stone_light", 0.16, 0.72).parent = root
    sphere("Helmet", (0, 0, 2.05), (0.38, 0.35, 0.36), "stone_light", 0.72).parent = root
    cube("Visor", (0, -0.34, 2.02), (0.5, 0.08, 0.15), "gold", 0.04, 0.8).parent = root
    for x in (-0.48, 0.48):
        sphere("Shoulder", (x, 0, 1.65), (0.25, 0.3, 0.24), "gold", 0.75).parent = root
    cylinder("Spear", (0.7, 0, 1.45), 0.055, 2.9, "gold", 8, 0.8).parent = root


def build_clock():
    root = bpy.data.objects.new("MoonClock", None)
    bpy.context.collection.objects.link(root)
    cube("ClockBody", (0, 0, 1.35), (1.05, 0.55, 2.7), "wood", 0.16).parent = root
    sphere("ClockFace", (0, -0.34, 1.92), (0.4, 0.08, 0.4), "cream").parent = root
    for angle in (0.0, 1.9):
        hand = cube("Hand", (0, -0.44, 1.92), (0.06, 0.04, 0.31), "purple", 0.02)
        hand.rotation_euler.y = angle
        hand.parent = root
    sphere("Pendulum", (0, -0.34, 0.72), (0.18, 0.07, 0.24), "gold", 0.75).parent = root


def build_rope_barrier():
    root = bpy.data.objects.new("RopeBarrier", None)
    bpy.context.collection.objects.link(root)
    for x in (-1.05, 1.05):
        cylinder("Post", (x, 0, 0.62), 0.09, 1.24, "gold", 10, 0.8).parent = root
        sphere("Cap", (x, 0, 1.28), (0.16, 0.16, 0.16), "gold", 0.8).parent = root
        cylinder("Foot", (x, 0, 0.08), 0.3, 0.16, "gold", 12, 0.8).parent = root
    rope = torus("Rope", (0, 0, 1.0), 1.05, 0.07, "coral", (math.pi * 0.5, 0.0, 0.0))
    rope.scale.z = 0.42
    rope.parent = root


def build_crystal():
    root = bpy.data.objects.new("VoidCrystal", None)
    bpy.context.collection.objects.link(root)
    cube("Base", (0, 0, 0.16), (1.25, 1.0, 0.32), "stone", 0.1).parent = root
    for index, offset in enumerate(((-0.3, 0.12), (0.0, -0.08), (0.32, 0.18), (0.12, 0.3))):
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.22 if index else 0.3, radius2=0.04, depth=1.0 + index * 0.2, location=(offset[0], offset[1], 0.7 + index * 0.1))
        crystal = bpy.context.object
        crystal.name = "Crystal"
        crystal.data.materials.append(material("CrystalGlow", PALETTE["purple"], 0.28, 0.2, PALETTE["purple"]))
        crystal.parent = root


def build_console():
    root = bpy.data.objects.new("SecurityConsole", None)
    bpy.context.collection.objects.link(root)
    cube("ConsoleBody", (0, 0, 0.65), (2.2, 0.85, 1.3), "stone", 0.14).parent = root
    screen = cube("Screen", (0, -0.48, 1.02), (1.45, 0.08, 0.58), "lime", 0.04)
    screen.data.materials.clear()
    screen.data.materials.append(material("ConsoleGlow", PALETTE["lime"], 0.15, 0.2, PALETTE["lime"]))
    screen.parent = root
    for x in (-0.55, 0.0, 0.55):
        sphere("Button", (x, -0.5, 0.48), (0.09, 0.04, 0.09), "coral").parent = root


BUILDERS = {
    "chest": build_chest,
    "bookshelf": build_bookshelf,
    "statue": build_statue,
    "sarcophagus": build_sarcophagus,
    "urn": build_urn,
    "bench": build_bench,
    "painting": build_painting,
    "chandelier": build_chandelier,
    "crate": build_crate,
    "brazier": build_brazier,
    "reception": build_reception,
    "mask_case": build_mask_case,
    "plant": build_plant,
    "armor": build_armor,
    "clock": build_clock,
    "rope_barrier": build_rope_barrier,
    "crystal": build_crystal,
    "console": build_console,
}


def export_assets():
    os.makedirs(MODEL_DIR, exist_ok=True)
    for name, builder in BUILDERS.items():
        reset_scene()
        builder()
        bpy.ops.export_scene.gltf(filepath=os.path.join(MODEL_DIR, f"{name}.glb"), export_format="GLB")


def point_camera(camera, point):
    camera.rotation_euler = (Vector(point) - camera.location).to_track_quat("-Z", "Y").to_euler()


def build_preview():
    reset_scene()
    spacing = 4.2
    for index, builder in enumerate(BUILDERS.values()):
        before = set(bpy.context.scene.objects)
        builder()
        x = (index % 4 - 1.5) * spacing
        y = (index // 4 - 1.0) * spacing
        for obj in set(bpy.context.scene.objects) - before:
            if obj.parent is None:
                obj.location.x += x
                obj.location.y += y
    cube("PreviewFloor", (0, 0, -0.18), (17.5, 13.5, 0.3), "stone", 0.08)
    bpy.ops.object.camera_add(location=(15.5, -21.5, 17.5))
    camera = bpy.context.object
    point_camera(camera, (0, 0, 1.1))
    camera.data.lens = 54
    bpy.context.scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(-6, -7, 15))
    key = bpy.context.object
    key.data.energy = 1900
    key.data.shape = "DISK"
    key.data.size = 8.0
    point_camera(key, (0, 0, 0))
    bpy.ops.object.light_add(type="AREA", location=(9, 4, 8))
    fill = bpy.context.object
    fill.data.energy = 1300
    fill.data.color = (0.45, 0.16, 1.0)
    fill.data.size = 7.0
    point_camera(fill, (0, 0, 1.0))
    world = bpy.context.scene.world
    world.color = (0.008, 0.004, 0.02)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = PREVIEW_PATH
    scene.render.film_transparent = False
    os.makedirs(os.path.dirname(SOURCE_PATH), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_PATH)
    bpy.ops.render.render(write_still=True)


export_assets()
build_preview()

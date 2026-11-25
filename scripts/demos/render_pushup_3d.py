#!/usr/bin/env python3
"""Original GymMane 3D push-up demo.

Muscular male (MPFB / MakeHuman CC0 assets) in matte graphite, with an
original procedural red-orange-yellow fiber shader on the working
muscles (chest, triceps, front delts). Keyframed plank-to-push-up loop.
Never copies Befit files.

Usage (Blender 4.5+):
  blender -b --python scripts/demos/render_pushup_3d.py -- --preview
  blender -b --python scripts/demos/render_pushup_3d.py -- --anim
"""

from __future__ import annotations

import argparse
import importlib
import math
import os
import shutil
import subprocess
import sys

import bpy
from mathutils import Vector, Euler, Matrix, Color

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.environ.get("PUSHUP_OUT", "/workspace/GymMane-shots")
WORK_DIR = os.path.join(OUT_DIR, "pushup-3d-work")
os.makedirs(WORK_DIR, exist_ok=True)

FPS = 24
DOWN_FRAMES = 48   # 2.0s
UP_FRAMES = 36     # 1.5s
FRAME_END = DOWN_FRAMES + UP_FRAMES  # 84; frame 85 duplicates frame 1
RES_X = 720
RES_Y = 900

# ---------------------------------------------------------------------------
# MPFB dynamic import (required for Blender extensions)
# ---------------------------------------------------------------------------

def dynamic_import(absolute_package_str, key):
    for amod in sys.modules:
        if amod.endswith(absolute_package_str):
            mpfb_mod = importlib.import_module(amod)
            if not hasattr(mpfb_mod, key):
                raise AttributeError(f"Module {amod} does not have attribute {key}")
            return getattr(mpfb_mod, key)
    raise ValueError(f"No module found with name ending in {absolute_package_str}")


def load_mpfb():
    names = [
        "HumanService", "TargetService", "LocationService",
        "AssetService", "ObjectService", "HumanObjectProperties",
    ]
    pkgs = {
        "HumanService": "mpfb.services.humanservice",
        "TargetService": "mpfb.services.targetservice",
        "LocationService": "mpfb.services.locationservice",
        "AssetService": "mpfb.services.assetservice",
        "ObjectService": "mpfb.services.objectservice",
        "HumanObjectProperties": "mpfb.entities.objectproperties",
    }
    out = {}
    for n in names:
        out[n] = dynamic_import(pkgs[n], n)
    return out


# ---------------------------------------------------------------------------
# Scene helpers
# ---------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Factory reset drops add-ons. Re-enable MPFB.
    try:
        bpy.ops.preferences.addon_enable(module="bl_ext.user_default.mpfb")
    except Exception as exc:
        print("WARN could not enable mpfb via ops:", exc)
        # try other module paths
        for mod in list(bpy.context.preferences.addons.keys()):
            if mod.endswith(".mpfb") or mod == "mpfb":
                print("found addon", mod)


def set_cycles():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = "OPENIMAGEDENOISE"
    scene.cycles.denoising_use_gpu = False
    scene.cycles.max_bounces = 6
    scene.cycles.diffuse_bounces = 3
    scene.cycles.glossy_bounces = 3
    scene.cycles.transmission_bounces = 2
    scene.cycles.transparent_max_bounces = 4
    scene.cycles.caustics_reflective = False
    scene.cycles.caustics_refractive = False
    scene.cycles.filter_width = 1.5
    scene.render.resolution_x = RES_X
    scene.render.resolution_y = RES_Y
    scene.render.resolution_percentage = 100
    scene.render.fps = FPS
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.frame_start = 1
    scene.frame_end = FRAME_END
    scene.frame_current = 1
    # True-white product background
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "NONE"
        prefs.get_devices()
        for d in prefs.devices:
            d.use = (d.type == "CPU")
            print("cycles device", d.name, d.type, d.use)
    except Exception as exc:
        print("WARN cycles devices", exc)
    scene.world = bpy.data.worlds.new("StudioWhite")
    scene.world.use_nodes = True
    nt = scene.world.node_tree
    nt.nodes.clear()
    bg = nt.nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (1, 1, 1, 1)
    bg.inputs["Strength"].default_value = 1.0
    out = nt.nodes.new("ShaderNodeOutputWorld")
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])


def add_lights(focus: Vector):
    """Soft even studio light, no floor, no hard shadow plate."""
    def area(name, loc, rot, size, energy, color=(1, 1, 1)):
        bpy.ops.object.light_add(type="AREA", location=loc, rotation=rot)
        obj = bpy.context.active_object
        obj.name = name
        obj.data.energy = energy
        obj.data.size = size
        obj.data.color = color
        obj.data.shape = "RECTANGLE"
        obj.data.size = size
        obj.data.size_y = size * 0.75
        return obj

    # Key, slightly warm, elevated front-right (camera side)
    area("Key", focus + Vector((2.2, -2.6, 2.4)),
         (math.radians(55), 0, math.radians(30)), 2.6, 250)
    # Fill, cooler, front-left, dimmer
    area("Fill", focus + Vector((-2.4, -2.0, 1.8)),
         (math.radians(60), 0, math.radians(-35)), 3.2, 120, (0.95, 0.97, 1.0))
    # Top/rim, even out the back
    area("Top", focus + Vector((0.2, 0.6, 3.4)),
         (math.radians(0), 0, 0), 3.5, 90)
    # Gentle bounce from below-front so the chest isn't a cave
    area("Bounce", focus + Vector((0.0, -1.8, 0.15)),
         (math.radians(-80), 0, 0), 3.0, 40, (1.0, 0.98, 0.96))


def add_camera(focus: Vector, body_len: float):
    # 3/4 elevated, 85mm look. Push-up body lies along -Y after pose.
    dist = max(2.4, body_len * 1.35)
    loc = focus + Vector((dist * 0.62, -dist * 0.85, dist * 0.48))
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.active_object
    cam.name = "DemoCamera"
    cam.data.lens = 70
    cam.data.sensor_width = 36
    cam.data.clip_start = 0.05
    cam.data.clip_end = 40
    # Aim at focus
    direction = focus - loc
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


# ---------------------------------------------------------------------------
# Character
# ---------------------------------------------------------------------------

def create_character(mpfb):
    HumanService = mpfb["HumanService"]
    TargetService = mpfb["TargetService"]
    LocationService = mpfb["LocationService"]
    AssetService = mpfb["AssetService"]
    ObjectService = mpfb["ObjectService"]

    macro = TargetService.get_default_macro_info_dict()
    macro["gender"] = 1.0
    macro["age"] = 0.5
    macro["muscle"] = 0.98
    macro["weight"] = 0.52
    macro["height"] = 0.55
    macro["proportions"] = 0.70
    macro["cupsize"] = 0.0
    macro["firmness"] = 0.5
    macro["race"] = {"asian": 0.15, "caucasian": 0.50, "african": 0.35}

    basemesh = HumanService.create_human(
        mask_helpers=True,
        detailed_helpers=True,
        extra_vertex_groups=True,
        feet_on_ground=True,
        scale=0.1,
        macro_detail_dict=macro,
    )
    print("created basemesh", basemesh.name, "verts", len(basemesh.data.vertices))

    targets = LocationService.get_mpfb_data("targets")
    extras = [
        ("torso/torso-muscle-pectoral-incr.target.gz", 0.90),
        ("torso/torso-muscle-dorsi-incr.target.gz", 0.55),
        ("torso/torso-vshape-incr.target.gz", 0.50),
        ("arms/l-upperarm-muscle-incr.target.gz", 0.85),
        ("arms/r-upperarm-muscle-incr.target.gz", 0.85),
        ("arms/l-upperarm-shoulder-muscle-incr.target.gz", 0.80),
        ("arms/r-upperarm-shoulder-muscle-incr.target.gz", 0.80),
        ("arms/l-lowerarm-muscle-incr.target.gz", 0.45),
        ("arms/r-lowerarm-muscle-incr.target.gz", 0.45),
    ]
    for rel, w in extras:
        path = os.path.join(targets, rel)
        if os.path.exists(path):
            TargetService.load_target(basemesh, path, weight=w)
            print("  target", rel, w)
        else:
            print("  MISSING target", path)

    # Rig first so later assets can bind to it
    rig = HumanService.add_builtin_rig(basemesh, "default")
    print("rig", rig.name, "bones", len(rig.data.bones))

    def add_asset(subdir, filename, atype, material_type="NONE"):
        path = AssetService.find_asset_absolute_path(filename, asset_subdir=subdir)
        if not path:
            print("  skip asset (not found)", subdir, filename)
            return None
        try:
            obj = HumanService.add_mhclo_asset(
                path, basemesh, asset_type=atype,
                subdiv_levels=1, material_type=material_type,
                set_up_rigging=True,
            )
            print("  asset", atype, obj.name if obj else None, path)
            return obj
        except Exception as exc:
            print("  FAIL asset", filename, exc)
            return None

    proxy = add_asset("proxymeshes", "male_muscle_13290.proxy", "Proxymeshes", "NONE")
    if proxy is not None:
        # Hide the base body so the muscle proxy is the visible skin
        if "Hide base mesh" not in basemesh.modifiers:
            mod = basemesh.modifiers.new("Hide base mesh", "MASK")
            if "body" in basemesh.vertex_groups:
                mod.vertex_group = "body"
                mod.invert_vertex_group = True
        print("using muscle proxy", proxy.name, "verts", len(proxy.data.vertices))

    eyes = add_asset("eyes", "low-poly.mhclo", "Eyes", "MAKESKIN")
    add_asset("eyebrows", "eyebrow001.mhclo", "Eyebrows", "MAKESKIN")
    add_asset("eyelashes", "eyelashes01.mhclo", "Eyelashes", "MAKESKIN")

    body = proxy if proxy is not None else basemesh
    return basemesh, rig, body, eyes


# ---------------------------------------------------------------------------
# Materials (original, not copied from Befit)
# ---------------------------------------------------------------------------

def _princ(nt, name="Principled BSDF"):
    n = nt.nodes.new("ShaderNodeBsdfPrincipled")
    n.name = name
    return n


def make_graphite_material():
    mat = bpy.data.materials.new("GraphiteSkin")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (600, 0)
    p = _princ(nt)
    p.location = (200, 0)
    # Matte dark grey, slightly warm so it doesn't look like a plastic toy
    p.inputs["Base Color"].default_value = (0.078, 0.079, 0.082, 1)
    p.inputs["Roughness"].default_value = 0.52
    p.inputs["Metallic"].default_value = 0.0
    p.inputs["Specular IOR Level"].default_value = 0.35
    if "Subsurface Weight" in p.inputs:
        p.inputs["Subsurface Weight"].default_value = 0.06
        if "Subsurface Radius" in p.inputs:
            p.inputs["Subsurface Radius"].default_value = (0.4, 0.2, 0.15)
        if "Subsurface Scale" in p.inputs:
            p.inputs["Subsurface Scale"].default_value = 0.04
    # Very soft micro-pore bump so the graphite isn't a featureless balloon
    tex = nt.nodes.new("ShaderNodeTexNoise")
    tex.inputs["Scale"].default_value = 180
    tex.inputs["Detail"].default_value = 6
    tex.inputs["Roughness"].default_value = 0.55
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.002
    nt.links.new(tex.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], p.inputs["Normal"])
    nt.links.new(p.outputs["BSDF"], out.inputs["Surface"])
    return mat


def make_fiber_material():
    """Original procedural red-orange-yellow muscle-fiber shader."""
    mat = bpy.data.materials.new("MuscleFiber")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (1400, 0)

    texcoord = nt.nodes.new("ShaderNodeTexCoord")
    texcoord.location = (-800, 0)

    # Chest fibers run roughly sternum -> shoulder (X), with a mild tilt
    map_chest = nt.nodes.new("ShaderNodeMapping")
    map_chest.location = (-560, 200)
    map_chest.inputs["Scale"].default_value = (12, 140, 12)
    map_chest.inputs["Rotation"].default_value = (0.0, 0.05, 0.12)

    map_tri = nt.nodes.new("ShaderNodeMapping")
    map_tri.location = (-560, 0)
    map_tri.inputs["Scale"].default_value = (140, 10, 10)
    map_tri.inputs["Rotation"].default_value = (0.15, 0.0, 1.35)

    map_delt = nt.nodes.new("ShaderNodeMapping")
    map_delt.location = (-560, -200)
    map_delt.inputs["Scale"].default_value = (16, 110, 16)
    map_delt.inputs["Rotation"].default_value = (0.35, 0.1, -0.25)

    def wave(name, loc, scale, dist, detail):
        w = nt.nodes.new("ShaderNodeTexWave")
        w.name = name
        w.location = loc
        w.wave_type = "BANDS"
        w.bands_direction = "X"
        w.wave_profile = "SIN"
        w.inputs["Scale"].default_value = scale
        w.inputs["Distortion"].default_value = dist
        w.inputs["Detail"].default_value = detail
        w.inputs["Detail Scale"].default_value = 4.0
        w.inputs["Detail Roughness"].default_value = 0.45
        return w

    w_c = wave("WaveChest", (-280, 200), 36.0, 0.22, 1)
    w_t = wave("WaveTri", (-280, 0), 38.0, 0.20, 1)
    w_d = wave("WaveDelt", (-280, -200), 34.0, 0.22, 1)

    # UV is stable under posing; fall back to object coords if a mesh has no UVs
    src = texcoord.outputs["UV"] if "UV" in texcoord.outputs else texcoord.outputs["Object"]
    nt.links.new(src, map_chest.inputs["Vector"])
    nt.links.new(src, map_tri.inputs["Vector"])
    nt.links.new(src, map_delt.inputs["Vector"])
    nt.links.new(map_chest.outputs["Vector"], w_c.inputs["Vector"])
    nt.links.new(map_tri.outputs["Vector"], w_t.inputs["Vector"])
    nt.links.new(map_delt.outputs["Vector"], w_d.inputs["Vector"])

    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "mregion"
    attr.location = (-280, 420)

    # Blend the three fiber fields by region color (R chest, G tri, B delt)
    mix1 = nt.nodes.new("ShaderNodeMix")
    mix1.data_type = "FLOAT"
    mix1.location = (0, 160)
    mix2 = nt.nodes.new("ShaderNodeMix")
    mix2.data_type = "FLOAT"
    mix2.location = (200, 80)
    # Start with chest, mix toward triceps by G, then delts by B
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    sep.location = (0, 420)
    nt.links.new(attr.outputs["Color"], sep.inputs["Color"])
    nt.links.new(w_c.outputs["Fac"], mix1.inputs["A"])
    nt.links.new(w_t.outputs["Fac"], mix1.inputs["B"])
    nt.links.new(sep.outputs["Green"], mix1.inputs["Factor"])
    nt.links.new(mix1.outputs["Result"], mix2.inputs["A"])
    nt.links.new(w_d.outputs["Fac"], mix2.inputs["B"])
    nt.links.new(sep.outputs["Blue"], mix2.inputs["Factor"])

    # Bundle variation
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.location = (0, -200)
    vor.feature = "F1"
    vor.voronoi_dimensions = "3D"
    vor.inputs["Scale"].default_value = 9
    vor.inputs["Randomness"].default_value = 0.45
    nt.links.new(texcoord.outputs["Object"], vor.inputs["Vector"])

    comb = nt.nodes.new("ShaderNodeMath")
    comb.operation = "MULTIPLY_ADD"
    comb.location = (400, 40)
    comb.inputs[1].default_value = 0.94  # mul
    # add a little voronoi
    scale_v = nt.nodes.new("ShaderNodeMath")
    scale_v.operation = "MULTIPLY"
    scale_v.location = (200, -160)
    scale_v.inputs[1].default_value = 0.06
    nt.links.new(vor.outputs["Distance"], scale_v.inputs[0])
    nt.links.new(mix2.outputs["Result"], comb.inputs[0])
    nt.links.new(scale_v.outputs["Value"], comb.inputs[2])

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (600, 80)
    ramp.color_ramp.interpolation = "B_SPLINE"
    el = ramp.color_ramp.elements
    el[0].position = 0.0
    el[0].color = (0.16, 0.018, 0.015, 1)      # deep crimson
    el[1].position = 1.0
    el[1].color = (0.92, 0.68, 0.14, 1)        # thin yellow-gold
    mid = ramp.color_ramp.elements.new(0.28)
    mid.color = (0.42, 0.05, 0.025, 1)         # dark red
    mid2 = ramp.color_ramp.elements.new(0.62)
    mid2.color = (0.72, 0.18, 0.04, 1)         # orange-red
    mid3 = ramp.color_ramp.elements.new(0.86)
    mid3.color = (0.86, 0.42, 0.08, 1)         # orange
    nt.links.new(comb.outputs["Value"], ramp.inputs["Fac"])

    p = _princ(nt, "FiberBSDF")
    p.location = (960, 40)
    p.inputs["Roughness"].default_value = 0.38
    p.inputs["Specular IOR Level"].default_value = 0.45
    p.inputs["Metallic"].default_value = 0.0
    if "Coat Weight" in p.inputs:
        p.inputs["Coat Weight"].default_value = 0.08
        p.inputs["Coat Roughness"].default_value = 0.25
    nt.links.new(ramp.outputs["Color"], p.inputs["Base Color"])

    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (800, -200)
    bump.inputs["Strength"].default_value = 0.65
    bump.inputs["Distance"].default_value = 0.0028
    nt.links.new(comb.outputs["Value"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], p.inputs["Normal"])

    # Mix graphite at the soft edge of the mask (attribute alpha / value)
    # mregion is stored as color; mask = max(R,G,B)
    max1 = nt.nodes.new("ShaderNodeMath")
    max1.operation = "MAXIMUM"
    max1.location = (400, 360)
    max2 = nt.nodes.new("ShaderNodeMath")
    max2.operation = "MAXIMUM"
    max2.location = (560, 360)
    nt.links.new(sep.outputs["Red"], max1.inputs[0])
    nt.links.new(sep.outputs["Green"], max1.inputs[1])
    nt.links.new(max1.outputs["Value"], max2.inputs[0])
    nt.links.new(sep.outputs["Blue"], max2.inputs[1])

    # Tighten the edge slightly
    cr = nt.nodes.new("ShaderNodeValToRGB")
    cr.location = (740, 360)
    cr.color_ramp.elements[0].position = 0.15
    cr.color_ramp.elements[1].position = 0.55
    nt.links.new(max2.outputs["Value"], cr.inputs["Fac"])

    graph = _princ(nt, "GraphiteMix")
    graph.location = (960, 360)
    graph.inputs["Base Color"].default_value = (0.078, 0.079, 0.082, 1)
    graph.inputs["Roughness"].default_value = 0.52
    graph.inputs["Specular IOR Level"].default_value = 0.35

    mixs = nt.nodes.new("ShaderNodeMixShader")
    mixs.location = (1200, 160)
    nt.links.new(cr.outputs["Color"], mixs.inputs["Fac"])
    nt.links.new(graph.outputs["BSDF"], mixs.inputs[1])
    nt.links.new(p.outputs["BSDF"], mixs.inputs[2])
    nt.links.new(mixs.outputs["Shader"], out.inputs["Surface"])
    return mat


def make_shorts_material():
    mat = bpy.data.materials.new("ShortsFabric")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    p = _princ(nt)
    p.inputs["Base Color"].default_value = (0.04, 0.04, 0.045, 1)
    p.inputs["Roughness"].default_value = 0.72
    p.inputs["Specular IOR Level"].default_value = 0.2
    nt.links.new(p.outputs["BSDF"], out.inputs["Surface"])
    return mat


def make_eye_material():
    mat = bpy.data.materials.new("SimpleEye")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    p = _princ(nt)
    # Dark iris on a muted sclera, stays quiet against graphite
    p.inputs["Base Color"].default_value = (0.12, 0.12, 0.125, 1)
    p.inputs["Roughness"].default_value = 0.15
    p.inputs["Specular IOR Level"].default_value = 0.6
    nt.links.new(p.outputs["BSDF"], out.inputs["Surface"])
    return mat


def apply_materials(body, eyes=None):
    graphite = make_graphite_material()
    fiber = make_fiber_material()
    body.data.materials.clear()
    body.data.materials.append(fiber)  # single mat: mixes graphite/fiber by attr
    # Also keep graphite around if mask is zero everywhere
    paint_muscle_attribute(body)
    # Slight inflate on muscle regions
    if "muscle_mask" in body.vertex_groups:
        disp = body.modifiers.new("MuscleInflate", "DISPLACE")
        disp.mid_level = 0.0
        disp.strength = 0.012
        disp.vertex_group = "muscle_mask"
        disp.direction = "NORMAL"
    # Smooth + subdiv
    if not any(m.type == "SUBSURF" for m in body.modifiers):
        sub = body.modifiers.new("Subdiv", "SUBSURF")
        sub.levels = 1
        sub.render_levels = 2
        sub.quality = 3
    try:
        if hasattr(body.data, "shade_smooth"):
            body.data.shade_smooth()
        else:
            bpy.ops.object.shade_smooth()
    except Exception:
        for poly in body.data.polygons:
            poly.use_smooth = True
    if eyes is not None:
        eye_mat = make_eye_material()
        eyes.data.materials.clear()
        eyes.data.materials.append(eye_mat)
    return fiber


def _world_bounds(obj):
    mat = obj.matrix_world
    # Use evaluated mesh so shape keys count
    deps = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(deps)
    mesh = ev.to_mesh()
    try:
        pts = [mat @ v.co for v in mesh.vertices]
    finally:
        ev.to_mesh_clear()
    xs = [p.x for p in pts]
    ys = [p.y for p in pts]
    zs = [p.z for p in pts]
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs), pts)


def paint_muscle_attribute(body):
    """Build soft chest / triceps / front-delt weights from rest-pose geometry."""
    deps = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(deps)
    mesh = ev.to_mesh()
    mat = body.matrix_world
    try:
        pts = [mat @ v.co for v in mesh.vertices]
        normals = [(mat.to_3x3() @ v.normal).normalized() for v in mesh.vertices]
        nverts = len(mesh.vertices)
    finally:
        ev.to_mesh_clear()

    xs = [p.x for p in pts]
    ys = [p.y for p in pts]
    zs = [p.z for p in pts]
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    zmin, zmax = min(zs), max(zs)
    height = zmax - zmin
    width = xmax - xmin
    depth = ymax - ymin
    print(f"body bounds x={xmin:.3f}:{xmax:.3f} y={ymin:.3f}:{ymax:.3f} z={zmin:.3f}:{zmax:.3f}")

    # MakeHuman in MPFB typically faces -Y, Z up, X right.
    front_sign = -1.0  # -Y is front

    z0 = zmin
    def nz(z):  # 0 at feet, 1 at head
        return (z - z0) / max(height, 1e-6)

    # Arm span makes `width` huge. Estimate torso half-width from FRONT mid-trunk verts.
    trunk_xs = [
        abs(p.x) for p, n, zv in zip(pts, normals, zs)
        if 0.66 <= nz(zv) <= 0.74 and (n.y * front_sign) > 0.55 and abs(n.x) < 0.45
    ]
    trunk_xs.sort()
    raw = trunk_xs[int(len(trunk_xs) * 0.55)] if trunk_xs else 0.20
    torso_half = min(0.22, max(0.16, raw))
    print(f"torso_half={torso_half:.3f} raw={raw:.3f} arm_span={width:.3f} trunk_n={len(trunk_xs)}")

    def smoothstep(t, a, b):
        if t <= a:
            return 0.0
        if t >= b:
            return 1.0
        x = (t - a) / (b - a)
        return x * x * (3 - 2 * x)

    def gauss(x, c, s):
        return math.exp(-0.5 * ((x - c) / s) ** 2)

    chest = [0.0] * nverts
    tri = [0.0] * nverts
    delt = [0.0] * nverts

    # Shoulder height ~ 0.80-0.84, hips ~ 0.52, nipples ~ 0.72
    for i, (p, n) in enumerate(zip(pts, normals)):
        h = nz(p.z)
        # frontness: 1 at the front surface
        front = n.y * front_sign  # 1 if normal points forward
        # also use y position
        y_norm = (p.y - ymin) / max(depth, 1e-6)  # 0 back? ymin is more -Y = front, so 0 is front
        # ymin is front (more negative Y). y_norm 0 = front, 1 = back.

        ax = abs(p.x)
        # --- Chest / pecs only (stop before the abs)
        if 0.69 <= h <= 0.83 and ax < torso_half * 0.95:
            ch = smoothstep(h, 0.69, 0.72) * (1.0 - smoothstep(h, 0.81, 0.84))
            ch *= smoothstep(front, -0.05, 0.35)
            ch *= 1.0 - smoothstep(y_norm, 0.42, 0.65)
            ch *= 1.0 - smoothstep(ax / max(torso_half, 1e-6), 0.82, 1.02)
            chest[i] = max(0.0, min(1.0, ch))

        # Upper arm: just outside the torso, from deltoid down to above the elbow
        is_upper_arm = torso_half * 0.95 <= ax <= torso_half * 1.75 and 0.62 <= h <= 0.84

        # --- Triceps: posterior upper arm (not the forearm)
        if is_upper_arm and 0.62 <= h <= 0.80:
            backness = -front
            tv = smoothstep(h, 0.62, 0.66) * (1.0 - smoothstep(h, 0.78, 0.82))
            tv *= smoothstep(backness, 0.05, 0.40)
            tv *= smoothstep(ax / max(torso_half, 1e-6), 1.00, 1.20)
            tv *= 1.0 - smoothstep(ax / max(torso_half, 1e-6), 1.55, 1.80)
            tri[i] = max(0.0, min(1.0, tv))

        # --- Front delts: front of the shoulder cap
        if 0.75 <= h <= 0.88 and torso_half * 0.70 <= ax <= torso_half * 1.55:
            d = smoothstep(h, 0.75, 0.77) * (1.0 - smoothstep(h, 0.86, 0.89))
            d *= smoothstep(front, -0.10, 0.30)
            d *= 1.0 - smoothstep(y_norm, 0.50, 0.80)
            delt[i] = max(0.0, min(1.0, d))

    # Store color attribute + vertex groups
    mesh_data = body.data
    attr = mesh_data.color_attributes.get("mregion")
    if attr is None:
        attr = mesh_data.color_attributes.new(
            name="mregion", type="FLOAT_COLOR", domain="POINT"
        )
    mask_grp = body.vertex_groups.get("muscle_mask") or body.vertex_groups.new(name="muscle_mask")
    for gname in ("vg_chest", "vg_triceps", "vg_delts"):
        if gname not in body.vertex_groups:
            body.vertex_groups.new(name=gname)

    g_chest = body.vertex_groups["vg_chest"]
    g_tri = body.vertex_groups["vg_triceps"]
    g_delt = body.vertex_groups["vg_delts"]

    n_c = n_t = n_d = 0
    for i in range(nverts):
        r, g, b = chest[i], tri[i], delt[i]
        # If overlap, keep the strongest and slightly suppress others
        mx = max(r, g, b)
        if mx > 0:
            # soft exclusive
            pass
        attr.data[i].color = (r, g, b, max(r, g, b))
        if r > 0.02:
            g_chest.add([i], r, "REPLACE")
            n_c += 1
        if g > 0.02:
            g_tri.add([i], g, "REPLACE")
            n_t += 1
        if b > 0.02:
            g_delt.add([i], b, "REPLACE")
            n_d += 1
        if mx > 0.02:
            mask_grp.add([i], mx, "REPLACE")
    print(f"muscle verts chest={n_c} triceps={n_t} delts={n_d}")


def add_shorts(body):
    """Tight athletic shorts: a hip tube shrink-wrapped to the body (no arm/hand faces)."""
    deps = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(deps)
    src = ev.to_mesh()
    matw = body.matrix_world
    try:
        pts = [matw @ v.co for v in src.vertices]
        nors = [(matw.to_3x3() @ v.normal).normalized() for v in src.vertices]
    finally:
        ev.to_mesh_clear()
    zs = [p.z for p in pts]
    zmin, zmax = min(zs), max(zs)
    height = zmax - zmin
    hip_z = zmin + height * 0.545
    band = height * 0.035
    # Radius from side verts around the hip (exclude a deep crotch dip and the arms)
    front_sign = -1.0
    hip_rs = []
    hip_ys = []
    hip_xs = []
    for p, n in zip(pts, nors):
        if abs(p.z - hip_z) < band and abs(p.x) > 0.04:
            # prefer side / slightly front torso, not arms (arms have more outward x and higher)
            if abs(p.x) < 0.28:
                hip_rs.append((p.x ** 2 + (p.y - 0.0) ** 2) ** 0.5)
                hip_ys.append(p.y)
                hip_xs.append(p.x)
    if not hip_rs:
        print("shorts: no hip verts")
        return None
    hip_rs.sort()
    radius = hip_rs[int(len(hip_rs) * 0.85)] * 1.04
    cy = sum(hip_ys) / len(hip_ys)
    cx = 0.0
    depth = height * 0.125
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=48,
        radius=radius * 1.12,
        depth=depth,
        end_fill_type="NOTHING",
        location=(cx, cy, hip_z),
        rotation=(0, 0, 0),
    )
    obj = bpy.context.active_object
    obj.name = "Shorts"
    # Open tube: delete any remaining cap faces just in case
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    caps = [f for f in bm.faces if abs(f.normal.z) > 0.9]
    bmesh.ops.delete(bm, geom=caps, context="FACES")
    # Flatten slightly in Y so the tube follows a torso more than a circle
    for v in bm.verts:
        v.co.y *= 0.88
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    sw = obj.modifiers.new("Wrap", "SHRINKWRAP")
    sw.target = body
    sw.wrap_method = "NEAREST_SURFACEPOINT"
    sw.wrap_mode = "ABOVE_SURFACE"
    sw.offset = 0.004
    bpy.context.view_layer.update()
    set_active(obj)
    try:
        bpy.ops.object.modifier_apply(modifier="Wrap")
    except Exception as exc:
        print("shorts apply wrap", exc)
    solid = obj.modifiers.new("Solidify", "SOLIDIFY")
    solid.thickness = 0.007
    solid.offset = 1.0
    sub = obj.modifiers.new("Subdiv", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 2
    sm = obj.modifiers.new("Smooth", "SMOOTH")
    sm.factor = 0.6
    sm.iterations = 8
    arm_mod = next((m for m in body.modifiers if m.type == "ARMATURE"), None)
    if arm_mod and arm_mod.object:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        body.select_set(True)
        try:
            bpy.ops.object.data_transfer(
                data_type="VGROUP_WEIGHTS",
                use_create=True,
                vert_mapping="NEAREST",
                layers_select_src="ALL",
                layers_select_dst="NAME",
                mix_mode="REPLACE",
            )
        except Exception as exc:
            print("shorts weight transfer", exc)
        body.select_set(False)
        bind = obj.modifiers.new("Armature", "ARMATURE")
        bind.object = arm_mod.object
        # Armature should be after shrinkwrap so posed shorts follow the body
        while obj.modifiers.find("Armature") < obj.modifiers.find("Wrap"):
            bpy.ops.object.modifier_move_up(modifier="Armature")
    obj.data.materials.clear()
    obj.data.materials.append(make_shorts_material())
    try:
        if hasattr(obj.data, "shade_smooth"):
            obj.data.shade_smooth()
        else:
            bpy.ops.object.shade_smooth()
    except Exception:
        pass
    if body.parent:
        obj.parent = body.parent
        obj.matrix_parent_inverse = body.parent.matrix_world.inverted()
    print("shorts tube r=%.3f z=%.3f d=%.3f" % (radius, hip_z, depth))
    return obj



# ---------------------------------------------------------------------------
# Pose / animation
# ---------------------------------------------------------------------------

def bone(rig, name):
    return rig.pose.bones.get(name)


def set_active(obj):
    if bpy.context.mode != "OBJECT":
        try:
            bpy.ops.object.mode_set(mode="OBJECT")
        except Exception:
            pass
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def ensure_pose_mode(rig):
    set_active(rig)
    if bpy.context.mode != "POSE":
        bpy.ops.object.mode_set(mode="POSE")


def world_bone_head(rig, name):
    pb = bone(rig, name)
    return rig.matrix_world @ pb.head


def world_bone_tail(rig, name):
    pb = bone(rig, name)
    return rig.matrix_world @ pb.tail


def make_empty(name, loc, size=0.05):
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = "SPHERE"
    e.empty_display_size = size
    e.location = loc
    bpy.context.collection.objects.link(e)
    return e


def add_ik(rig, bone_name, target, chain_len, pole=None, pole_angle=0.0):
    ensure_pose_mode(rig)
    pb = bone(rig, bone_name)
    if pb is None:
        print("missing bone", bone_name)
        return None
    # clear old
    for c in list(pb.constraints):
        if c.type == "IK":
            pb.constraints.remove(c)
    ik = pb.constraints.new("IK")
    ik.target = target
    ik.chain_count = chain_len
    ik.use_tail = True
    ik.iterations = 200
    if pole is not None:
        ik.pole_target = pole
        ik.pole_angle = pole_angle
    return ik


def flatten_hands(rig):
    """Slight palmar flexion so palms can meet the floor."""
    ensure_pose_mode(rig)
    # Finger curl: a little flexion on finger*-2/3
    for side in ("L", "R"):
        for f in range(1, 6):
            for seg in (2, 3):
                name = f"finger{f}-{seg}.{side}"
                pb = bone(rig, name)
                if not pb:
                    continue
                pb.rotation_mode = "XYZ"
                # mild curl
                pb.rotation_euler.x = math.radians(18 if seg == 2 else 10)
        # thumb a bit inward
        for seg in (2, 3):
            pb = bone(rig, f"finger1-{seg}.{side}")
            if pb:
                pb.rotation_mode = "XYZ"
                pb.rotation_euler.x = math.radians(12)


def setup_prone_ik(rig):
    """Lay the figure into a straight-bodied plank and plant the hands with IK.

    A ~75 degree pitch from standing keeps the feet on the floor and the
    legs straight (rest pose), with the shoulders already near plank height.
    Hand IK then parks the palms under the shoulders.
    """
    root = make_empty("CharacterRoot", Vector((0, 0, 0)), 0.1)
    set_active(rig)
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    rig.parent = root
    rig.matrix_parent_inverse = root.matrix_world.inverted()

    # ~75° from standing: body slants in a natural high plank, feet stay down.
    angle_top = 82.0
    root.rotation_euler = Euler((math.radians(angle_top), 0.0, 0.0), "XYZ")
    bpy.context.view_layer.update()

    head_w = world_bone_head(rig, "head")
    foot_w = (world_bone_head(rig, "foot.L") + world_bone_head(rig, "foot.R")) / 2
    print("plank head", head_w, "foot", foot_w)

    # Nudge so the lowest toe is exactly on z=0
    zs = []
    for n in ("toe1-1.L", "toe1-1.R", "toe1-2.L", "toe1-2.R", "foot.L", "foot.R"):
        if bone(rig, n):
            zs.append(world_bone_head(rig, n).z)
            zs.append(world_bone_tail(rig, n).z)
    if zs:
        root.location.z -= min(zs)
        bpy.context.view_layer.update()
        print("root z after toe plant", root.location.z, "minz", min(zs))

    sh_l = world_bone_tail(rig, "shoulder01.L") if bone(rig, "shoulder01.L") else world_bone_head(rig, "upperarm01.L")
    sh_r = world_bone_tail(rig, "shoulder01.R") if bone(rig, "shoulder01.R") else world_bone_head(rig, "upperarm01.R")
    print("shoulders", sh_l, sh_r)

    # Palms under the shoulders, slightly wide, on the floor
    ht_l = make_empty("IK_Hand.L", Vector((sh_l.x * 1.15, sh_l.y + 0.02, 0.0)), 0.04)
    ht_r = make_empty("IK_Hand.R", Vector((sh_r.x * 1.15, sh_r.y + 0.02, 0.0)), 0.04)

    # Elbow poles: flare slightly out and back toward the feet (plus Y)
    pole_l = make_empty("Pole_Elbow.L", Vector((sh_l.x + 0.45, sh_l.y + 0.25, 0.28)), 0.04)
    pole_r = make_empty("Pole_Elbow.R", Vector((sh_r.x - 0.45, sh_r.y + 0.25, 0.28)), 0.04)

    hand_bone_l = "wrist.L" if bone(rig, "wrist.L") else "lowerarm02.L"
    hand_bone_r = "wrist.R" if bone(rig, "wrist.R") else "lowerarm02.R"
    add_ik(rig, hand_bone_l, ht_l, chain_len=5, pole=pole_l, pole_angle=math.radians(90))
    add_ik(rig, hand_bone_r, ht_r, chain_len=5, pole=pole_r, pole_angle=math.radians(-90))

    # Plantarflex the feet so the toes take the weight; keep the knees straight (no leg IK).
    ensure_pose_mode(rig)
    for side in ("L", "R"):
        for name, deg in (("foot." + side, 28), ("toe1-1." + side, 12)):
            pb = bone(rig, name)
            if not pb:
                continue
            pb.rotation_mode = "XYZ"
            # Rotation axis can vary; try X first (typical for this rig's foot).
            pb.rotation_euler.x = math.radians(deg)

    flatten_hands(rig)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()
    print("after IK wrist L", world_bone_head(rig, "wrist.L"),
          "head", world_bone_head(rig, "head"),
          "foot L", world_bone_head(rig, "foot.L"))

    return {
        "root": root,
        "hand_l": ht_l,
        "hand_r": ht_r,
        "pole_l": pole_l,
        "pole_r": pole_r,
        "angle_top": angle_top,
        "sh_l": sh_l.copy(),
        "sh_r": sh_r.copy(),
    }


def key_pushup(rig, ctrls):
    """2s down, 1.5s up, eased, looping. Pitch the body a little lower at the bottom."""
    root = ctrls["root"]
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = FRAME_END

    angle_top = ctrls["angle_top"]
    angle_bot = min(88.0, angle_top + 5.0)  # closer to the floor, still a straight body

    f_top1 = 1
    f_bot = 1 + DOWN_FRAMES
    f_top2 = 1 + DOWN_FRAMES + UP_FRAMES  # 85

    def key_angle(frame, deg):
        root.rotation_euler = Euler((math.radians(deg), 0.0, 0.0), "XYZ")
        root.keyframe_insert(data_path="rotation_euler", index=0, frame=frame)

    key_angle(f_top1, angle_top)
    key_angle(f_bot, angle_bot)
    key_angle(f_top2, angle_top)

    ad = root.animation_data
    if ad and ad.action:
        for fc in ad.action.fcurves:
            if fc.data_path == "rotation_euler" and fc.array_index == 0:
                for kp in fc.keyframe_points:
                    kp.interpolation = "BEZIER"
                    kp.handle_left_type = "AUTO_CLAMPED"
                    kp.handle_right_type = "AUTO_CLAMPED"
                    kp.easing = "EASE_IN_OUT"

    # Neck slightly extended so the face looks ahead, not into the floor
    ensure_pose_mode(rig)
    for name in ("neck01", "neck02", "neck03"):
        pb = bone(rig, name)
        if not pb:
            continue
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = Euler((math.radians(6), 0, 0), "XYZ")
        pb.keyframe_insert("rotation_euler", frame=f_top1)
        pb.keyframe_insert("rotation_euler", frame=f_bot)
        pb.keyframe_insert("rotation_euler", frame=f_top2)

    bpy.ops.object.mode_set(mode="OBJECT")
    scene.frame_set(1)
    print("angles top/bot", angle_top, angle_bot)
    return angle_top, angle_bot


def focus_point(rig):
    bpy.context.view_layer.update()
    names = ["spine03", "spine04", "spine02", "spine05"]
    pts = [world_bone_head(rig, n) for n in names if bone(rig, n)]
    if not pts:
        pts = [world_bone_head(rig, "root")]
    return sum(pts, Vector((0, 0, 0))) / len(pts)


def add_camera_framed(rig, body):
    """3/4 elevated camera that frames the full planked figure."""
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    xs, ys, zs = [], [], []
    for obj in (body, bpy.data.objects.get("Shorts")):
        if obj is None or obj.type != "MESH":
            continue
        ev = obj.evaluated_get(deps)
        try:
            mesh = ev.to_mesh()
        except Exception:
            continue
        try:
            mat = ev.matrix_world
            for v in mesh.vertices:
                p = mat @ v.co
                xs.append(p.x); ys.append(p.y); zs.append(p.z)
        finally:
            ev.to_mesh_clear()
    if not xs:
        focus = focus_point(rig)
        add_camera(focus, body_length(rig))
        return bpy.context.scene.camera
    minv = Vector((min(xs), min(ys), min(zs)))
    maxv = Vector((max(xs), max(ys), max(zs)))
    center = (minv + maxv) / 2.0
    # Bias the look-at slightly toward the chest / camera
    # Bias the aim toward the head so it isn't cropped in a 3/4 view.
    center.y = minv.y * 0.62 + maxv.y * 0.38
    center.z += 0.04
    size = max((maxv - minv).x, (maxv - minv).y, (maxv - minv).z)
    dist = max(2.05, size * 1.34)
    loc = center + Vector((dist * 0.58, -dist * 0.92, dist * 0.42))
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.active_object
    cam.name = "DemoCamera"
    cam.data.lens = 62
    cam.data.sensor_width = 36
    cam.data.clip_start = 0.05
    cam.data.clip_end = 40
    direction = center - loc
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    print("camera loc", loc, "center", center, "size", size)
    return cam


def body_length(rig):
    head = world_bone_head(rig, "head")
    foot = world_bone_head(rig, "foot.L")
    return (head - foot).length


# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------

def render_still(path, frame=1, samples=None):
    scene = bpy.context.scene
    scene.frame_set(frame)
    if samples:
        scene.cycles.samples = samples
    scene.render.filepath = path
    print("RENDER still", path, "frame", frame, "samples", scene.cycles.samples)
    bpy.ops.render.render(write_still=True)
    print("  wrote", path, "exists", os.path.exists(path),
          "size", os.path.getsize(path) if os.path.exists(path) else 0)


def render_anim(frame_dir):
    if os.path.isdir(frame_dir):
        shutil.rmtree(frame_dir)
    os.makedirs(frame_dir, exist_ok=True)
    scene = bpy.context.scene
    scene.cycles.samples = 28
    scene.render.filepath = os.path.join(frame_dir, "f")
    scene.render.use_file_extension = True
    print("RENDER anim frames 1-%d to %s" % (FRAME_END, frame_dir))
    bpy.ops.render.render(animation=True)
    print("  done anim")


def encode_mp4(frame_dir, mp4_path, poster_path, poster_frame=20):
    pattern = os.path.join(frame_dir, "f%04d.png")
    # Blender default is f0001.png if filepath is .../f
    # Confirm naming
    files = sorted(f for f in os.listdir(frame_dir) if f.endswith(".png"))
    print("frame files", len(files), files[:3], files[-3:] if files else "")
    if not files:
        raise RuntimeError("no frames to encode")
    # Discover pattern
    first = files[0]
    # e.g. f0001.png
    import re
    m = re.match(r"(.*?)(\d+)\.png$", first)
    if not m:
        raise RuntimeError("unexpected frame name " + first)
    prefix, digits = m.group(1), len(m.group(2))
    start = int(m.group(2))
    pat = os.path.join(frame_dir, f"{prefix}%0{digits}d.png")
    tmp = mp4_path + ".tmp.mp4"
    cmd = [
        "ffmpeg", "-y",
        "-framerate", str(FPS),
        "-start_number", str(start),
        "-i", pat,
        "-frames:v", str(FRAME_END),
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-crf", "26",
        "-preset", "slow",
        "-movflags", "+faststart",
        "-an",
        tmp,
    ]
    print("ffmpeg", " ".join(cmd))
    subprocess.check_call(cmd)
    size = os.path.getsize(tmp)
    print("mp4 size", size)
    crf = 26
    while size > 600_000 and crf < 34:
        crf += 2
        cmd[cmd.index("-crf") + 1] = str(crf)
        subprocess.check_call(cmd)
        size = os.path.getsize(tmp)
        print("mp4 size after crf", crf, size)
    shutil.move(tmp, mp4_path)
    # Poster: a clear mid-descent frame
    src = os.path.join(frame_dir, f"{prefix}{poster_frame:0{digits}d}.png")
    if not os.path.exists(src):
        src = os.path.join(frame_dir, files[min(len(files)//4, len(files)-1)])
    # Copy as PNG poster
    shutil.copyfile(src, poster_path)
    print("poster", poster_path, os.path.getsize(poster_path))
    return mp4_path, poster_path


def save_blend(path):
    bpy.ops.wm.save_as_mainfile(filepath=path)
    print("saved blend", path)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def parse_args():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    p = argparse.ArgumentParser()
    p.add_argument("--preview", action="store_true")
    p.add_argument("--anim", action="store_true")
    p.add_argument("--standing-only", action="store_true")
    p.add_argument("--samples", type=int, default=0)
    return p.parse_args(argv)


def main():
    args = parse_args()
    print("=== GymMane push-up 3D ===")
    reset_scene()
    set_cycles()
    if args.samples:
        bpy.context.scene.cycles.samples = args.samples

    mpfb = load_mpfb()
    basemesh, rig, body, eyes = create_character(mpfb)
    apply_materials(body, eyes)
    shorts = add_shorts(body)

    blend_path = os.path.join(WORK_DIR, "pushup-3d.blend")

    if args.standing_only:
        # Camera on the standing figure
        bbox = _world_bounds(body)
        focus = Vector(((bbox[0]+bbox[1])/2, (bbox[2]+bbox[3])/2, (bbox[4]+bbox[5])*0.55))
        add_lights(focus)
        add_camera(focus, bbox[5] - bbox[4])
        save_blend(blend_path)
        render_still(os.path.join(WORK_DIR, "standing.png"), frame=1, samples=args.samples or 48)
        return

    ctrls = setup_prone_ik(rig)
    z_top, z_bot = key_pushup(rig, ctrls)
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()

    focus = focus_point(rig)
    print("focus", focus, "length", body_length(rig))
    add_lights(focus)
    add_camera_framed(rig, body)
    save_blend(blend_path)

    do_stills = args.preview or not args.anim
    if do_stills:
        # Review stills: top, mid-descent, bottom
        render_still(os.path.join(WORK_DIR, "preview-top.png"), frame=1, samples=args.samples or 48)
        mid = 1 + DOWN_FRAMES // 2
        render_still(os.path.join(WORK_DIR, "preview-mid.png"), frame=mid, samples=args.samples or 48)
        render_still(os.path.join(WORK_DIR, "preview-bot.png"), frame=1 + DOWN_FRAMES, samples=args.samples or 48)

    if args.anim:
        frame_dir = os.path.join(WORK_DIR, "frames")
        render_anim(frame_dir)
        encode_mp4(
            frame_dir,
            os.path.join(OUT_DIR, "pushup-3d.mp4"),
            os.path.join(OUT_DIR, "pushup-3d-poster.png"),
            poster_frame=20,
        )


if __name__ == "__main__":
    main()

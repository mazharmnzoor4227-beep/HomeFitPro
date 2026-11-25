#!/usr/bin/env python3
"""Flat-shaded 3D mannequin rasterizer (original work)."""
from __future__ import annotations
import math
import numpy as np
from PIL import Image

SIZE = 512
SS = 2
FRAMES = 24
FPS_MS = 70

BG0 = np.array([8, 14, 12], np.float32)
SPOT = np.array([36, 52, 42], np.float32)
BODY = np.array([0.91, 0.88, 0.84], np.float32)
BODY_D = np.array([0.72, 0.68, 0.64], np.float32)
ACCENT = np.array([0.784, 0.941, 0.302], np.float32)  # #C8F04D
ACCENT_D = np.array([0.45, 0.62, 0.12], np.float32)
PROP = np.array([0.20, 0.19, 0.18], np.float32)
PROP_EDGE = np.array([0.38, 0.36, 0.34], np.float32)
METAL = np.array([0.55, 0.53, 0.50], np.float32)
LIGHT = np.array([-0.35, 0.75, 0.55], np.float32)
LIGHT /= np.linalg.norm(LIGHT)
RIM = np.array([0.55, 0.15, -0.82], np.float32)
RIM /= np.linalg.norm(RIM)

RAD = dict(head=0.115, chest=0.16, pelvis=0.13,
           ls=0.07, rs=0.07, le=0.055, re=0.055, lw=0.042, rw=0.042,
           lh=0.09, rh=0.09, lk=0.07, rk=0.07, la=0.055, ra=0.055, lt=0.04, rt=0.04)
MUSCLE_BONES = {
    "chest": ["chest"], "triceps": ["le", "re"], "biceps": ["le", "re"],
    "shoulders": ["ls", "rs"], "back": ["chest"], "lowerback": ["pelvis", "chest"],
    "abdomen": ["pelvis", "chest"], "obliques": ["pelvis", "chest"],
    "quads": ["lk", "rk", "lh", "rh"], "glutes": ["lh", "rh", "pelvis"],
    "hamstrings": ["lk", "rk"], "calves": ["la", "ra"],
}
PARENT = dict(chest="pelvis", head="chest",
              ls="chest", le="ls", lw="le", rs="chest", re="rs", rw="re",
              lh="pelvis", lk="lh", la="lk", lt="la",
              rh="pelvis", rk="rh", ra="rk", rt="ra")
BIND_LEN = dict(chest=0.28, head=0.26,
                ls=0.18, le=0.27, lw=0.25, rs=0.18, re=0.27, rw=0.25,
                lh=0.12, lk=0.42, la=0.40, lt=0.08,
                rh=0.12, rk=0.42, ra=0.40, rt=0.08)
ORDER = ["pelvis","chest","head","ls","le","lw","rs","re","rw",
         "lh","lk","la","lt","rh","rk","ra","rt"]


def _ease(t: float) -> float:
    return t * t * (3 - 2 * t)

def pingpong_times(n: int, hold: float = 0.12) -> list[float]:
    if n == 1:
        return [0.0]
    h = hold
    mid = (1 - 2 * h) / 2
    out = []
    for i in range(n):
        u = i / (n - 1)
        if u < h:
            out.append(0.0)
        elif u < h + mid:
            out.append(_ease((u - h) / mid))
        elif u < h + mid + h:
            out.append(1.0)
        else:
            out.append(_ease(1 - (u - h - mid - h) / mid))
    return out

def loop_times(n: int) -> list[float]:
    return [i / n for i in range(n)]

def constrain(pose: dict) -> dict:
    p = {k: np.asarray(v, float).copy() for k, v in pose.items()}
    for j in ORDER:
        if j not in p or j not in PARENT or PARENT[j] not in p:
            continue
        par = PARENT[j]
        d = p[j] - p[par]
        L = np.linalg.norm(d)
        target = BIND_LEN.get(j, L)
        if L < 1e-6:
            d, L = np.array([0.0, 1.0, 0.0]), 1.0
        p[j] = p[par] + d / L * target
    return p

def plant(pose: dict, ground: float = 0.0) -> dict:
    p = {k: np.asarray(v, float).copy() for k, v in pose.items()}
    low = min(p[j][1] - RAD.get(j, 0.04) for j in p)
    dy = ground - low
    for k in p:
        p[k][1] += dy
    return p

def sample_motion(keys: list[dict], t: float, mode: str = "pingpong") -> dict:
    if mode == "loop":
        return blend_keys(keys, t)
    n = len(keys)
    if n == 1:
        return {k: np.asarray(v, float).copy() for k, v in keys[0].items()}
    if n == 2:
        return lerp_pose(keys[0], keys[1], float(np.clip(t, 0, 1)))
    x = float(np.clip(t, 0, 1)) * (n - 1)
    i = min(int(math.floor(x)), n - 2)
    return lerp_pose(keys[i], keys[i + 1], _ease(x - i))

def lerp_pose(a: dict, b: dict, t: float) -> dict:

    out = {}
    for k in set(a) & set(b):
        out[k] = (1 - t) * np.asarray(a[k], float) + t * np.asarray(b[k], float)
    return constrain(out)

def blend_keys(keys: list[dict], t: float) -> dict:
    n = len(keys)
    if n == 1:
        return {k: np.asarray(v, float) for k, v in keys[0].items()}
    x = t * n
    i = int(math.floor(x)) % n
    f = _ease(x - math.floor(x))
    return lerp_pose(keys[i], keys[(i + 1) % n], f)

def to_cam(p: np.ndarray, cam: str) -> np.ndarray:
    x, y, z = p
    if cam == "side":
        return np.array([-z, y, -x], float)
    if cam == "qtr":
        a = math.radians(32)
        c, s = math.cos(a), math.sin(a)
        # view from +Z, yawed; depth is toward camera (front of body closer)
        return np.array([c * x + s * z, y, s * x - c * z], float)
    return np.array([x, y, -z], float)

def project(p, scale, origin):
    return origin[0] + p[0] * scale, origin[1] - p[1] * scale


class Buffer:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.rgb = np.zeros((h, w, 3), np.float32)
        self.z = np.full((h, w), 1e9, np.float32)

    def shade(self, normal, color):
        ndl = np.clip(normal @ LIGHT, 0, 1)
        ndr = np.clip(normal @ RIM, 0, 1) ** 2
        wrap = 0.28 + 0.72 * ndl
        col = np.asarray(color, np.float32).reshape(1, 3)
        ndl = ndl.reshape(-1, 1)
        ndr = ndr.reshape(-1, 1)
        wrap = wrap.reshape(-1, 1)
        return np.clip(col * wrap + 0.10 * ndl * col + 0.16 * ndr * np.array([0.95, 0.93, 0.90], np.float32), 0, 1)

    def _splat(self, xs, ys, depth, normal, color):
        m = (xs >= 0) & (xs < self.w) & (ys >= 0) & (ys < self.h)
        if not np.any(m):
            return
        xs, ys, depth, normal = xs[m], ys[m], depth[m], normal[m]
        vis = depth < self.z[ys, xs] - 1e-4
        if not np.any(vis):
            return
        xs, ys, depth, normal = xs[vis], ys[vis], depth[vis], normal[vis]
        self.rgb[ys, xs] = self.shade(normal, color)
        self.z[ys, xs] = depth

    def sphere(self, c, r, color, scale, origin):
        cx, cy = project(c, scale, origin)
        rad = r * scale
        x0, x1 = max(0, int(cx - rad - 2)), min(self.w - 1, int(cx + rad + 2))
        y0, y1 = max(0, int(cy - rad - 2)), min(self.h - 1, int(cy + rad + 2))
        if x1 <= x0 or y1 <= y0:
            return
        yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        dx = (xx - cx) / scale
        dy = -(yy - cy) / scale
        rr = dx * dx + dy * dy
        m = rr <= (r * r)
        if not np.any(m):
            return
        zloc = np.sqrt(np.maximum(r * r - rr[m], 0))
        n = np.stack([dx[m], dy[m], zloc], axis=1) / r
        self._splat(xx[m], yy[m], c[2] - zloc, n, color)

    def capsule(self, a, b, ra, rb, color, scale, origin):
        pts = []
        for p, r in ((a, ra), (b, rb)):
            cx, cy = project(p, scale, origin)
            rad = r * scale + 3
            pts.append((cx - rad, cy - rad, cx + rad, cy + rad))
        x0, y0 = max(0, int(min(p[0] for p in pts))), max(0, int(min(p[1] for p in pts)))
        x1, y1 = min(self.w - 1, int(max(p[2] for p in pts))), min(self.h - 1, int(max(p[3] for p in pts)))
        if x1 <= x0 or y1 <= y0:
            return
        yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        px = (xx - origin[0]) / scale
        py = -(yy - origin[1]) / scale
        ab, abz = b[:2] - a[:2], b[2] - a[2]
        denom = float(ab @ ab) + 1e-12
        if denom < 1e-10:
            self.sphere(a, max(ra, rb), color, scale, origin)
            return
        t = np.clip(((px - a[0]) * ab[0] + (py - a[1]) * ab[1]) / denom, 0.0, 1.0)
        qx, qy, qz = a[0] + t * ab[0], a[1] + t * ab[1], a[2] + t * abz
        r = ra + t * (rb - ra)
        dx, dy = px - qx, py - qy
        d2 = dx * dx + dy * dy
        m = d2 <= (r * r)
        if not np.any(m):
            return
        zloc = np.sqrt(np.maximum(r[m] * r[m] - d2[m], 0))
        n = np.stack([dx[m], dy[m], zloc], axis=1) / (r[m][:, None] + 1e-8)
        self._splat(xx[m], yy[m], qz[m] - zloc, n, color)

    def ellipsoid(self, c, rx, ry, rz, color, scale, origin):
        cx, cy = project(c, scale, origin)
        x0, x1 = max(0, int(cx - rx * scale - 3)), min(self.w - 1, int(cx + rx * scale + 3))
        y0, y1 = max(0, int(cy - ry * scale - 3)), min(self.h - 1, int(cy + ry * scale + 3))
        if x1 <= x0 or y1 <= y0:
            return
        yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        dx = (xx - cx) / scale
        dy = -(yy - cy) / scale
        e = (dx * dx) / (rx * rx + 1e-12) + (dy * dy) / (ry * ry + 1e-12)
        m = e <= 1.0
        if not np.any(m):
            return
        zloc = rz * np.sqrt(np.maximum(1.0 - e[m], 0))
        n = np.stack([dx[m] / (rx * rx), dy[m] / (ry * ry), zloc / (rz * rz)], axis=1)
        n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-8
        self._splat(xx[m], yy[m], c[2] - zloc, n, color)


def paint_stage(h, w):
    yy, xx = np.mgrid[0:h, 0:w]
    nx = (xx / (w - 1)) * 2 - 1
    ny = (yy / (h - 1)) * 2 - 1
    d = np.sqrt(nx * nx + (ny + 0.18) ** 2)
    t = np.clip(d / 1.35, 0, 1)
    t = t * t
    bg = (1 - t)[..., None] * SPOT + t[..., None] * BG0
    v = np.clip((d - 0.2) / 1.4, 0, 1) ** 1.2
    return bg * (1 - 0.25 * v[..., None]) / 255.0

def floor_shadow(buf, pose, cam, scale, origin):
    pts = [to_cam(np.asarray(p, float), cam) for p in pose.values()]
    xs = [origin[0] + p[0] * scale for p in pts]
    cy = max(project(p, scale, origin)[1] for p in pts) + 6
    cx = float(np.mean(xs))
    rx, ry = 0.34 * scale, 0.07 * scale
    x0, x1 = max(0, int(cx - rx)), min(buf.w - 1, int(cx + rx))
    y0, y1 = max(0, int(cy - ry)), min(buf.h - 1, int(cy + ry))
    if x1 <= x0 or y1 <= y0:
        return
    yy, xx = np.mgrid[y0:y1 + 1, x0:x1 + 1]
    e = ((xx - cx) / (rx + 1e-6)) ** 2 + ((yy - cy) / (ry + 1e-6)) ** 2
    a = np.clip(1 - e, 0, 1) ** 1.6 * 0.45
    buf.rgb[y0:y1 + 1, x0:x1 + 1] *= (1 - a)[..., None]

def color_for(joint, highlights):
    for mus, bones in MUSCLE_BONES.items():
        if mus in highlights and joint in bones:
            return ACCENT
    return BODY

def draw_figure(buf, pose, cam, highlights, scale, origin):
    hl = set(highlights)
    cam_p = {k: to_cam(np.asarray(v, float), cam) for k, v in pose.items()}
    def col(j):
        return color_for(j, hl)
    bones = [("pelvis","chest"),("chest","head"),
             ("chest","ls"),("ls","le"),("le","lw"),
             ("chest","rs"),("rs","re"),("re","rw"),
             ("pelvis","lh"),("lh","lk"),("lk","la"),("la","lt"),
             ("pelvis","rh"),("rh","rk"),("rk","ra"),("ra","rt")]
    def dep(a,b):
        return 0.5 * (cam_p[a][2] + cam_p[b][2])
    for a, b in sorted(bones, key=lambda e: -dep(*e)):
        ra, rb = RAD.get(a, 0.05), RAD.get(b, 0.04)
        if b in ("lk","rk"): ra, rb = 0.095, 0.072
        if b in ("la","ra"): ra, rb = 0.062, 0.048
        if b in ("le","re"): ra, rb = 0.062, 0.05
        if b in ("lw","rw"): ra, rb = 0.048, 0.04
        if b == "chest": ra, rb = 0.125, 0.155
        if b == "head": ra, rb = 0.05, 0.08
        buf.capsule(cam_p[a], cam_p[b], ra, rb, col(b), scale, origin)
    def mid(a, b, t=0.5):
        return cam_p[a] * (1 - t) + cam_p[b] * t
    buf.ellipsoid(mid("pelvis","chest",0.70), 0.16, 0.17, 0.13, col("chest"), scale, origin)
    buf.ellipsoid(mid("pelvis","chest",0.42), 0.14, 0.13, 0.115, col("pelvis") if "abdomen" not in hl and "obliques" not in hl else ACCENT, scale, origin)
    buf.ellipsoid(mid("pelvis","chest",0.16), 0.135, 0.115, 0.12, col("pelvis"), scale, origin)
    buf.ellipsoid(cam_p["pelvis"] + np.array([0.0, -0.02, 0.0]), 0.11, 0.09, 0.10, col("pelvis"), scale, origin)
    for j in ("ls","rs"):
        buf.sphere(cam_p[j], 0.072, col(j), scale, origin)
    buf.sphere(cam_p["head"], 0.115, BODY, scale, origin)
    buf.ellipsoid(cam_p["head"] + np.array([0, -0.02, 0.0]), 0.09, 0.10, 0.09, BODY, scale, origin)
    # subtle face cue so front/back reads clearly
    face = to_cam(np.asarray(pose["head"], float) + np.array([0.0, -0.015, 0.10]), cam)
    buf.ellipsoid(face, 0.028, 0.022, 0.03, BODY_D, scale, origin)
    for j, r in (("lw",0.042),("rw",0.042)):
        buf.sphere(cam_p[j], r, col(j), scale, origin)
    for j in ("lt","rt"):
        buf.ellipsoid(cam_p[j], 0.04, 0.025, 0.06, col(j), scale, origin)
    for j, r in (("le",0.05),("re",0.05),("lk",0.058),("rk",0.058),("la",0.048),("ra",0.048)):
        buf.sphere(cam_p[j], r, col(j), scale, origin)

def _C(p, cam):
    return to_cam(np.asarray(p, float), cam)

def draw_prop(buf, kind, params, cam, scale, origin):
    if kind == "bar":
        y, w, z, x = params.get("y", 2.05), params.get("w", 0.55), params.get("z", 0.0), params.get("x", 0.0)
        buf.capsule(_C((x-w,y,z),cam), _C((x+w,y,z),cam), 0.025, 0.025, METAL, scale, origin)
        if params.get("uprights", True):
            for sx in (-w, w):
                buf.capsule(_C((x+sx,0,z),cam), _C((x+sx,y+0.02,z),cam), 0.03, 0.03, PROP, scale, origin)
    elif kind == "chair":
        x,y,z = params.get("pos", (0.35, 0.45, 0.0))
        buf.ellipsoid(_C((x,y,z),cam), 0.22, 0.03, 0.18, PROP_EDGE, scale, origin)
        buf.ellipsoid(_C((x,y+0.28,z-0.16),cam), 0.20, 0.22, 0.03, PROP, scale, origin)
        for dx,dz in ((-0.16,0.12),(0.16,0.12),(-0.16,-0.12),(0.16,-0.12)):
            buf.capsule(_C((x+dx,0,z+dz),cam), _C((x+dx,y,z+dz),cam), 0.025, 0.025, PROP, scale, origin)
    elif kind == "wall":
        # vertical plane at +Z (side view: a line) or at given z
        z = params.get("z", 0.65)
        h = params.get("h", 2.2)
        x0, x1 = params.get("x0", -0.4), params.get("x1", 0.4)
        for dz in (-0.05, 0.0, 0.05, 0.10):
            for i, xx in enumerate(np.linspace(x0, x1, 7)):
                buf.capsule(_C((xx,0,z+dz),cam), _C((xx,h,z+dz),cam), 0.04, 0.04, PROP*(0.88+0.12*(i%2)), scale, origin)
        buf.capsule(_C((x0,0.02,z),cam), _C((x1,0.02,z),cam), 0.04, 0.04, PROP_EDGE, scale, origin)
    elif kind == "wall_side":
        # plane at x (for side? rarely)
        x = params.get("x", -0.35)
        z0,z1,h = params.get("z0",-0.5), params.get("z1",0.5), params.get("h",2.2)
        for i,zz in enumerate(np.linspace(z0,z1,6)):
            buf.capsule(_C((x,0,zz),cam), _C((x,h,zz),cam), 0.04, 0.04, PROP, scale, origin)
    elif kind == "bench":
        x,y,z = params.get("pos", (0.0, 0.35, 0.15))
        buf.ellipsoid(_C((x,y,z),cam), 0.28, 0.04, 0.16, PROP_EDGE, scale, origin)
        for dx,dz in ((-0.22,0.12),(0.22,0.12),(-0.22,-0.12),(0.22,-0.12)):
            buf.capsule(_C((x+dx,0,z+dz),cam), _C((x+dx,y,z+dz),cam), 0.025, 0.025, PROP, scale, origin)
    elif kind == "block":
        x,y,z = params.get("pos", (0.0, 0.22, 0.35))
        buf.ellipsoid(_C((x,y,z),cam), 0.18, 0.04, 0.12, PROP_EDGE, scale, origin)
        buf.capsule(_C((x,0,z),cam), _C((x,y,z),cam), 0.06, 0.06, PROP, scale, origin)

def prop_points(props):
    pts = []
    for item in props or []:
        kind, params = item[0], (item[1] if len(item) > 1 else {}) or {}
        if kind == "bar":
            y, w, z, x = params.get("y", 2.05), params.get("w", 0.55), params.get("z", 0.0), params.get("x", 0.0)
            pts += [(x-w, y, z), (x+w, y, z), (x-w, 0, z), (x+w, 0, z)]
        elif kind == "chair":
            x, y, z = params.get("pos", (0.35, 0.45, 0.0))
            pts += [(x, y, z), (x, y+0.28, z-0.16), (x, 0, z)]
        elif kind == "wall":
            z, h = params.get("z", 0.65), params.get("h", 2.2)
            pts += [(0, 0, z), (0, h, z), (-0.3, h, z), (0.3, 0, z)]
        elif kind == "wall_side":
            x, z0, z1, h = params.get("x", -0.35), params.get("z0", -0.5), params.get("z1", 0.5), params.get("h", 2.2)
            pts += [(x, 0, z0), (x, h, z1)]
        elif kind == "bench":
            x, y, z = params.get("pos", (0.0, 0.35, 0.15))
            pts += [(x, y, z), (x, 0, z)]
        elif kind == "block":
            x, y, z = params.get("pos", (0.0, 0.22, 0.35))
            pts += [(x, y, z)]
    return pts

def frame_params(pose, cam, size, extras=None):
    world = list(pose.values()) + list(extras or [])
    cam_p = [to_cam(np.asarray(v, float), cam) for v in world]
    xs, ys = [p[0] for p in cam_p], [p[1] for p in cam_p]
    pad = 0.28
    minx, maxx = min(xs) - pad, max(xs) + pad
    miny, maxy = min(ys) - 0.16, max(ys) + 0.22
    # include a sliver of ground when the figure is standing
    if min(ys) < 0.25:
        miny = min(miny, -0.08)
    w, h = max(maxx - minx, 0.4), max(maxy - miny, 0.4)
    scale = size * 0.86 / max(w, h)
    origin_x = size / 2 - 0.5 * (minx + maxx) * scale
    origin_y = size / 2 + 0.5 * (miny + maxy) * scale
    return scale, (origin_x, origin_y)

def render_frame(pose, cam, highlights, props, size=SIZE, ss=SS) -> Image.Image:
    pose = plant(constrain(pose))
    W = size * ss
    buf = Buffer(W, W)
    buf.rgb[:] = paint_stage(W, W)
    scale, origin = frame_params(pose, cam, W, extras=prop_points(props))
    floor_shadow(buf, pose, cam, scale, origin)
    for prop in props or []:
        kind, params = prop[0], (prop[1] if len(prop) > 1 else {})
        draw_prop(buf, kind, params or {}, cam, scale, origin)
    draw_figure(buf, pose, cam, highlights, scale, origin)
    im = Image.fromarray(np.clip(buf.rgb * 255.0, 0, 255).astype(np.uint8), "RGB")
    if ss > 1:
        im = im.resize((size, size), Image.Resampling.LANCZOS)
    return im

def standing(arm_abduct=0.0, stance=0.10) -> dict:
    pel = np.array([0.0, 0.92, 0.0])
    chest = pel + (0.0, 0.28, 0.02)
    head = chest + (0.0, 0.26, 0.01)
    ls, rs = chest + (-0.18, 0.02, 0.00), chest + (0.18, 0.02, 0.00)
    le, re = ls + (-0.03-arm_abduct, -0.27, 0.0), rs + (0.03+arm_abduct, -0.27, 0.0)
    lw, rw = le + (0.0, -0.25, 0.0), re + (0.0, -0.25, 0.0)
    lh, rh = pel + (-stance, -0.02, 0.0), pel + (stance, -0.02, 0.0)
    lk, rk = lh + (0.0, -0.42, 0.02), rh + (0.0, -0.42, 0.02)
    la, ra = lk + (0.0, -0.40, 0.0), rk + (0.0, -0.40, 0.0)
    lt, rt = la + (0.0, -0.02, 0.08), ra + (0.0, -0.02, 0.08)
    return dict(pelvis=pel, chest=chest, head=head, ls=ls, le=le, lw=lw, rs=rs, re=re, rw=rw,
                lh=lh, lk=lk, la=la, lt=lt, rh=rh, rk=rk, ra=ra, rt=rt)

def side_plank_base(hip_y=0.28) -> dict:
    pel = np.array([0.0, hip_y, 0.0])
    chest = np.array([0.0, hip_y+0.02, 0.30])
    head = np.array([0.0, hip_y+0.04, 0.55])
    ls, rs = np.array([-0.16, hip_y+0.02, 0.34]), np.array([0.16, hip_y+0.02, 0.34])
    le, re = np.array([-0.16, hip_y*0.45, 0.34]), np.array([0.16, hip_y*0.45, 0.34])
    lw, rw = np.array([-0.16, 0.04, 0.36]), np.array([0.16, 0.04, 0.36])
    lh, rh = np.array([-0.10, hip_y-0.01, -0.02]), np.array([0.10, hip_y-0.01, -0.02])
    lk, rk = np.array([-0.10, hip_y-0.01, -0.44]), np.array([0.10, hip_y-0.01, -0.44])
    la, ra = np.array([-0.10, 0.06, -0.82]), np.array([0.10, 0.06, -0.82])
    lt, rt = np.array([-0.10, 0.04, -0.92]), np.array([0.10, 0.04, -0.92])
    return dict(pelvis=pel, chest=chest, head=head, ls=ls, le=le, lw=lw, rs=rs, re=re, rw=rw,
                lh=lh, lk=lk, la=la, lt=lt, rh=rh, rk=rk, ra=ra, rt=rt)

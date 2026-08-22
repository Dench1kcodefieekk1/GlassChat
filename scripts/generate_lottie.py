#!/usr/bin/env python3
"""Generates proprietary loopable Lottie JSON animations for GlassChat gifts.

Emits valid Lottie shape-layer documents (200x200, 60fps, 3s seamless loops)
into GlassChat/Resources/Lottie/.
"""
import json
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "GlassChat", "Resources", "Lottie")
W = H = 200
FPS = 60
OP = 180  # 3 seconds


# ---------- property helpers ----------

def static(v):
    return {"a": 0, "k": v}

LINEAR = ({"x": [0.333], "y": [0.333]}, {"x": [0.667], "y": [0.667]})
EASE = ({"x": [0.58], "y": [1]}, {"x": [0.42], "y": [0]})


def animated(frames_values, ease=EASE):
    i, o = ease
    kfs = []
    for idx, (t, val) in enumerate(frames_values):
        kf = {"t": t, "s": val if isinstance(val, list) else [val]}
        if idx < len(frames_values) - 1:
            kf["i"], kf["o"] = i, o
        kfs.append(kf)
    return {"a": 1, "k": kfs}


def fill(rgb, opacity=100):
    return {"ty": "fl", "c": static([rgb[0], rgb[1], rgb[2], 1]), "o": static(opacity)}


def stroke(rgb, width, opacity=100):
    return {"ty": "st", "c": static([rgb[0], rgb[1], rgb[2], 1]), "o": static(opacity),
            "w": static(width), "lc": 2, "lj": 2}


def transform(p=(0, 0), s=(100, 100), r=0, o=100, animated_s=None):
    tr = {"ty": "tr", "p": static([p[0], p[1]]), "a": static([0, 0]),
          "s": animated_s if animated_s else static([s[0], s[1]]),
          "r": static(r), "o": static(o)}
    return tr


def group(items, name, tr=None):
    return {"ty": "gr", "nm": name, "it": items + [(tr or transform())]}


def ellipse(name, pos, size):
    return {"ty": "el", "nm": name, "p": static([pos[0], pos[1]]), "s": static([size[0], size[1]])}


def rect(name, pos, size, radius=0):
    return {"ty": "rc", "nm": name, "p": static([pos[0], pos[1]]), "s": static([size[0], size[1]]),
            "r": static(radius)}


def polystar(name, pos, points, outer, inner, star=True, rotation=0):
    return {"ty": "sr", "nm": name, "sy": 1 if star else 2, "pt": static(points),
            "p": static([pos[0], pos[1]]), "or": static(outer), "ir": static(inner),
            "os": static(0), "is": static(0), "r": static(rotation)}


def path_shape(name, verts, closed=True):
    n = len(verts)
    zeros = [[0, 0]] * n
    return {"ty": "sh", "nm": name,
            "ks": static({"i": zeros, "o": zeros, "v": [list(v) for v in verts], "c": closed})}


_ind = [0]


def layer(name, shapes, o=100, r=None, p=None, s=None):
    _ind[0] += 1
    return {
        "ddd": 0, "ind": _ind[0], "ty": 4, "nm": name, "sr": 1,
        "ks": {
            "o": o if isinstance(o, dict) else static(o),
            "r": r or static(0),
            "p": p or static([0, 0, 0]),
            "a": static([0, 0, 0]),
            "s": s or static([100, 100, 100]),
        },
        "ao": 0, "shapes": shapes, "ip": 0, "op": OP, "st": 0,
    }


def doc(name, layers):
    return {"v": "5.7.4", "fr": FPS, "ip": 0, "op": OP, "w": W, "h": H,
            "nm": name, "ddd": 0, "assets": [], "layers": layers}


# ---------- 1. Diamond Ring: spinning gem, glow, sparkles ----------

def diamond_ring():
    layers = []
    # sparkles (top)
    for i, (x, y, phase) in enumerate([(62, 40, 0), (138, 46, 60), (100, 26, 120)]):
        layers.append(layer(f"sparkle{i+1}", [
            group([polystar("sp", (0, 0), 4, 9, 3.5), fill((1, 1, 1))], "g",
                  transform(animated_s=animated([(0 + phase, [40, 40]),
                                                 (45 + phase, [110, 110]),
                                                 (90 + phase, [40, 40]),
                                                 (180, [40, 40])], EASE)))
        ], p=static([x, y, 0])))
    # gem glow (pulsing)
    layers.append(layer("glow", [
        group([ellipse("glow", (0, 0), (78, 78)), fill((0.45, 0.85, 1), 30)], "g",
              transform(animated_s=animated([(0, [80, 80]), (90, [105, 105]), (180, [80, 80])])))
    ], p=static([100, 66, 0])))
    # gem (rotating polygon)
    layers.append(layer("gem", [
        group([path_shape("gem", [(-30, 0), (0, -26), (30, 0), (0, 30)]),
               fill((0.55, 0.85, 1)), stroke((1, 1, 1), 3)], "g"),
        group([path_shape("facet", [(0, -26), (14, 0), (0, 30), (-14, 0)]),
               fill((1, 1, 1), 55)], "facet"),
    ], r=animated([(0, 0), (180, 360)], LINEAR), p=static([100, 66, 0])))
    # gold band
    layers.append(layer("band", [
        group([ellipse("band", (0, 0), (104, 104)),
               stroke((0.86, 0.64, 0.22), 11)], "g"),
        group([ellipse("bandInner", (0, 0), (88, 88)),
               stroke((1.0, 0.82, 0.4), 3, 70)], "shine"),
    ], p=static([100, 128, 0])))
    return doc("Diamond Ring", layers)


# ---------- 2. Cyber Cat: blinking neon cat, scanline ----------

def cyber_cat():
    layers = []
    # scanline
    layers.append(layer("scan", [
        group([rect("line", (0, 0), (86, 3), 2), fill((0.5, 1, 0.9), 55)], "g")
    ], p=animated([(0, [100, 70, 0]), (90, [100, 140, 0]), (180, [100, 70, 0])], LINEAR)))
    # eyes (blink)
    blink = animated([(0, [100, 100, 100]), (72, [100, 100, 100]), (80, [100, 8, 100]),
                      (88, [100, 100, 100]), (180, [100, 100, 100])])
    for i, x in enumerate([80, 120]):
        layers.append(layer(f"eye{i+1}", [
            group([ellipse("eye", (0, 0), (11, 17)), fill((0.55, 1, 0.85))], "g")
        ], p=static([x, 102, 0]), s=blink))
    # head
    layers.append(layer("head", [
        group([ellipse("head", (0, 0), (92, 86)), fill((0.06, 0.46, 0.52)),
               stroke((0.3, 0.9, 0.85), 3)], "g"),
        group([ellipse("nose", (0, 8), (7, 5)), fill((1, 0.9, 0.95))], "nose"),
    ], s=animated([(0, [100, 100, 100]), (90, [104, 104, 100]), (180, [100, 100, 100])]),
        p=static([100, 105, 0])))
    # ears
    for i, (x, rot) in enumerate([(68, -14), (132, 14)]):
        layers.append(layer(f"ear{i+1}", [
            group([path_shape("ear", [(-12, 12), (0, -14), (12, 12)]),
                   fill((0.06, 0.46, 0.52)), stroke((0.3, 0.9, 0.85), 3)], "g",
                  transform(r=rot))
        ], p=static([x, 62, 0])))
    return doc("Cyber Cat", layers)


# ---------- 3. Gold Star: pulsing glossy star, aura ----------

def gold_star():
    layers = []
    # aura
    layers.append(layer("aura", [
        group([ellipse("aura", (0, 0), (150, 150)), fill((1, 0.85, 0.3), 30)], "g",
              transform(animated_s=animated([(0, [85, 85]), (90, [110, 110]), (180, [85, 85])])))
    ], p=static([100, 100, 0])))
    # gloss overlay star
    layers.append(layer("gloss", [
        group([polystar("gloss", (0, 0), 5, 44, 19), fill((1, 0.97, 0.8), 45)], "g")
    ], p=static([100, 98, 0])))
    # main star
    layers.append(layer("star", [
        group([polystar("star", (0, 0), 5, 54, 24), fill((1, 0.82, 0.25)),
               stroke((1, 0.95, 0.7), 3)], "g")
    ], s=animated([(0, [92, 92, 100]), (90, [110, 110, 100]), (180, [92, 92, 100])]),
        p=static([100, 100, 0])))
    return doc("Gold Star", layers)


# ---------- 4. Rainbow Cat NFT: rainbow trail, bobbing pixel cat ----------

RAINBOW = [(0.95, 0.25, 0.25), (0.98, 0.55, 0.15), (0.98, 0.85, 0.2),
           (0.3, 0.8, 0.35), (0.3, 0.5, 0.95), (0.65, 0.35, 0.9)]


def rainbow_cat():
    layers = []
    # sparkles
    for i, (x, y, phase) in enumerate([(30, 40, 0), (168, 150, 90)]):
        layers.append(layer(f"spk{i+1}", [
            group([polystar("sp", (0, 0), 4, 8, 3), fill((1, 1, 1))], "g",
                  transform(animated_s=animated([(0 + phase, [40, 40]), (45 + phase, [110, 110]),
                                                 (90 + phase, [40, 40]), (180, [40, 40])])))
        ], p=static([x, y, 0])))
    # cat (head + body + face)
    layers.append(layer("cat", [
        group([rect("body", (28, 26), (74, 50), 12), fill((0.95, 0.45, 0.7)),
               stroke((1, 1, 1), 2)], "g"),
        group([ellipse("head", (52, -8), (48, 48)), fill((0.98, 0.62, 0.78)),
               stroke((1, 1, 1), 2)], "gh"),
        group([ellipse("eyeL", (-6, -10), (5, 6)), fill((0.1, 0.1, 0.15))], "e1"),
        group([ellipse("eyeR", (6, -10), (5, 6)), fill((0.1, 0.1, 0.15))], "e2"),
        group([ellipse("blush", (-14, -2), (8, 4)), fill((1, 0.85, 0.9))], "b1"),
        group([ellipse("blush", (14, -2), (8, 4)), fill((1, 0.85, 0.9))], "b2"),
    ], p=animated([(0, [96, 118, 0]), (90, [96, 106, 0]), (180, [96, 118, 0])], EASE)))
    # rainbow trail
    trail_items = []
    for i, rgb in enumerate(RAINBOW):
        trail_items.append(group([rect(f"band{i+1}", (i * 18 - 45, 0), (14, 84), 6), fill(rgb)], f"t{i+1}"))
    layers.append(layer("trail", trail_items,
                        p=animated([(0, [44, 128, 0]), (90, [50, 128, 0]), (180, [44, 128, 0])], EASE)))
    return doc("Rainbow Nyan Cat", layers)


# ---------- 5. Vice Cream: steaming vice-palette dessert ----------

def vice_cream():
    layers = []
    # steam (three staggered rising puffs)
    for i, x in enumerate([88, 104, 116]):
        start = i * 24
        layers.append(layer(f"steam{i+1}", [
            group([ellipse("puff", (0, 0), (10 - i, 10 - i)), fill((1, 1, 1))], "g")
        ], p=animated([(0 + start, [x, 84, 0]), (90 + start, [x + 4, 46, 0]), (180, [x, 84, 0])], LINEAR),
            o=animated([(0, [0]), (30 + start, [55]), (150 + start, [0]), (180, [0])], LINEAR)))
    # cherry
    layers.append(layer("cherry", [
        group([ellipse("cherry", (0, 0), (12, 12)), fill((0.9, 0.2, 0.35))], "g")
    ], p=static([100, 74, 0])))
    # scoops (breathing)
    layers.append(layer("scoops", [
        group([ellipse("top", (0, -14), (46, 44)), fill((1, 0.45, 0.7)),
               stroke((1, 0.85, 0.92), 2)], "g"),
        group([ellipse("bottom", (0, 12), (56, 50)), fill((0.15, 0.78, 0.72)),
               stroke((0.8, 1, 0.98), 2)], "g"),
    ], s=animated([(0, [100, 100, 100]), (90, [105, 103, 100]), (180, [100, 100, 100])]),
        p=static([100, 112, 0])))
    # cone
    layers.append(layer("cone", [
        group([path_shape("cone", [(-30, -14), (30, -14), (0, 46)]), fill((0.92, 0.72, 0.42))], "g",
              transform(r=180)),
    ], p=static([100, 128, 0])))
    return doc("Vice Cream", layers)


# ---------- emit ----------

def reset():
    _ind[0] = 0


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for filename, builder in [
        ("gift_diamond_ring.json", diamond_ring),
        ("gift_cyber_cat.json", cyber_cat),
        ("gift_gold_star.json", gold_star),
        ("gift_rainbow_cat.json", rainbow_cat),
        ("gift_vice_cream.json", vice_cream),
    ]:
        reset()
        doc_json = builder()
        path = os.path.join(OUT_DIR, filename)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(doc_json, f, separators=(",", ":"))
        # validate
        parsed = json.load(open(path, encoding="utf-8"))
        assert parsed["layers"], filename
        for lyr in parsed["layers"]:
            assert "ks" in lyr and "shapes" in lyr, (filename, lyr.get("nm"))
        print(f"{filename}: {len(parsed['layers'])} layers, ok")


if __name__ == "__main__":
    main()

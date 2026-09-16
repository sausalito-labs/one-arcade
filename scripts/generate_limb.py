#!/usr/bin/env python3
"""Regenerate a single limb asset via Gemini 2.5 Flash Image (free tier).

Usage:
  python3 scripts/generate_limb.py <slice_name> [out_png]

Reads GOOGLE_API_KEY from the environment (.env). Sends the existing
slice PNG as a reference and asks the model to redraw it in the target
style, then cleans up the alpha channel (Nano Banana rarely emits true
transparency) and writes the result at the same canvas size.
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image

MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-2.5-flash-image")
ENDPOINT = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

STYLE_PROMPT = (
    "2D game asset of a single sprite slice: a fierce Muay Thai fighter's {part}, "
    "cel-shaded anime fighting game style, bold clean black outline, vibrant flat "
    "comic-book colors, dynamic fight-ready pose facing RIGHT."
)

BG_FILL = (0, 0, 0, 0)


def load_image_paths() -> dict:
    base = Path(__file__).resolve().parent.parent / "player_robot" / "slices"
    return {
        "head": base / "head.png",
        "torso": base / "torso.png",
        "left arm": base / "left arm.png",
        "right arm": base / "right arm.png",
        "left leg": base / "left leg.png",
        "right leg": base / "right leg.png",
    }


def transparentify(img: Image.Image) -> Image.Image:
    """Force a usable alpha channel by flood-filling the border color away."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size

    # Sample border to find the background color (most common edge pixel).
    from collections import Counter
    edge = Counter()
    for x in range(w):
        edge[px[x, 0][:3]] += 1
        edge[px[x, h - 1][:3]] += 1
    for y in range(h):
        edge[px[0, y][:3]] += 1
        edge[px[w - 1, y][:3]] += 1
    bg = edge.most_common(1)[0][0]

    # Flood fill from all border cells that match bg.
    stack = []
    seen = [[False] * w for _ in range(h)]
    for x in range(w):
        for y in (0, h - 1):
            if px[x, y][:3] == bg and not seen[y][x]:
                stack.append((x, y))
                seen[y][x] = True
    for y in range(h):
        for x in (0, w - 1):
            if px[x, y][:3] == bg and not seen[y][x]:
                stack.append((x, y))
                seen[y][x] = True

    tolerance = 30
    while stack:
        x, y = stack.pop()
        px[x, y] = (*px[x, y][:3], 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                r, g, b, a = px[nx, ny]
                if abs(r - bg[0]) <= tolerance and abs(g - bg[1]) <= tolerance and abs(b - bg[2]) <= tolerance:
                    seen[ny][nx] = True
                    stack.append((nx, ny))
    return img


def generate(slice_name: str) -> Image.Image:
    paths = load_image_paths()
    src = paths[slice_name]
    key = os.environ.get("GOOGLE_API_KEY")
    if not key:
        sys.exit("GOOGLE_API_KEY not set")

    ref = base64.b64encode(src.read_bytes()).decode()
    prompt = STYLE_PROMPT.format(part=slice_name)

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": "image/png",
                            "data": ref,
                        }
                    },
                    {
                        "text": f"Keep the exact same silhouette and canvas framing. {prompt} "
                                "Output a single asset with a flat solid background color that I can key out.",
                    },
                ]
            }
        ],
        "generationConfig": {"responseModalities": ["IMAGE"]},
    }

    req = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "x-goog-api-key": key},
    )
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            body = json.load(resp)
    except urllib.error.HTTPError as e:
        sys.exit(f"API error {e.code}: {e.read().decode()[:800]}")

    for cand in body.get("candidates", []):
        for part in cand["content"]["parts"]:
            if "inlineData" in part:
                return Image.open(io_bytes(part["inlineData"]["data"]))
    sys.exit("No image in API response:\n" + json.dumps(body, indent=2)[:1200])


def io_bytes(b64: str):
    import io
    return io.BytesIO(base64.b64decode(b64))


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    slice_name = sys.argv[1]
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(__file__).resolve().parent.parent / "build" / "slice_restyle" / f"{slice_name}.png"

    img = generate(slice_name)
    img = transparentify(img)

    # Preserve the original canvas dimensions (center the result).
    orig = load_image_paths()[slice_name]
    ow, oh = Image.open(orig).size
    img = img.convert("RGBA")
    if img.size != (ow, oh):
        canvas = Image.new("RGBA", (ow, oh), BG_FILL)
        # scale to fit while keeping aspect ratio
        img.thumbnail((ow, oh), Image.LANCZOS)
        canvas.paste(img, ((ow - img.width) // 2, (oh - img.height) // 2), img)
        img = canvas

    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)
    print(f"Saved {out_path} ({img.width}x{img.height})")


if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""Post-process Grok Imagine outputs for game assets: resize, chroma-key, promote."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
DEFAULT_PROJECT_ROOT = SKILL_DIR.parent.parent.parent  # .grok/skills/imagine-asset -> repo


def load_type_config(project_root: Path, asset_type: str) -> dict:
    config_path = SKILL_DIR / "asset-types.json"
    with open(config_path, encoding="utf-8") as f:
        types = json.load(f)
    if asset_type not in types:
        raise SystemExit(f"Unknown type '{asset_type}'. Valid: {', '.join(types)}")
    return types[asset_type]


def parse_chroma(hex_str: str) -> tuple[int, int, int]:
    hex_str = hex_str.strip().lstrip("#")
    if len(hex_str) != 6:
        raise SystemExit(f"Chroma must be RRGGBB, got: {hex_str}")
    return tuple(int(hex_str[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def sample_corner_chroma(img: Image.Image) -> tuple[int, int, int]:
    """Average corner samples — Imagine often uses a flat non-pure chroma plate."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    points = [
        (0, 0),
        (w - 1, 0),
        (0, h - 1),
        (w - 1, h - 1),
        (w // 2, 0),
        (0, h // 2),
        (w - 1, h // 2),
        (w // 2, h - 1),
    ]
    rs, gs, bs = 0, 0, 0
    for p in points:
        r, g, b = rgb.getpixel(p)
        rs += r
        gs += g
        bs += b
    n = len(points)
    return (rs // n, gs // n, bs // n)


def chroma_key(
    img: Image.Image,
    key: tuple[int, int, int],
    tolerance: int = 48,
    soft: int = 24,
) -> Image.Image:
    """Remove near-key colors to alpha. Soft edge over soft range beyond tolerance."""
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    w, h = rgba.size
    kr, kg, kb = key
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            dist = ((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2) ** 0.5
            # Euclidean distance in RGB; max ~441
            if dist <= tolerance:
                pixels[x, y] = (r, g, b, 0)
            elif soft > 0 and dist < tolerance + soft:
                # Fade alpha near edge
                t = (dist - tolerance) / soft
                new_a = int(a * t)
                pixels[x, y] = (r, g, b, new_a)
    return rgba


def next_staging_path(staging_dir: Path, prefix: str, asset_id: str) -> Path:
    staging_dir.mkdir(parents=True, exist_ok=True)
    n = 1
    while True:
        path = staging_dir / f"{prefix}_{asset_id}_{n:03d}.png"
        if not path.exists():
            return path
        n += 1


def load_manifest(manifest_path: Path) -> list:
    if not manifest_path.exists():
        return []
    with open(manifest_path, encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        return []
    return data


def save_manifest(manifest_path: Path, entries: list) -> None:
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2)
        f.write("\n")


def process_source(args: argparse.Namespace, project_root: Path) -> Path:
    type_cfg = load_type_config(project_root, args.type)
    size_cfg = type_cfg.get("size", [256, 256])
    if args.size:
        out_w = out_h = args.size
    elif isinstance(size_cfg, list) and len(size_cfg) >= 2:
        out_w, out_h = int(size_cfg[0]), int(size_cfg[1])
    else:
        out_w = out_h = int(size_cfg[0] if isinstance(size_cfg, list) else size_cfg)

    tolerance = args.tolerance
    skip_chroma = (
        getattr(args, "no_chroma", False)
        or type_cfg.get("no_chroma")
        or type_cfg.get("chroma_key") is None
    )

    source = Path(args.source)
    if not source.is_absolute():
        source = (project_root / source).resolve()
    if not source.exists():
        raise SystemExit(f"Source image not found: {source}")

    img = Image.open(source)
    chroma = None
    flags = ["imagine"]
    if skip_chroma:
        print("Skipping chroma key (opaque asset)")
        img = img.convert("RGB").resize((out_w, out_h), Image.Resampling.LANCZOS)
        img = img.convert("RGBA")
        flags.append("opaque")
    else:
        if args.auto_chroma or args.chroma is None:
            chroma = sample_corner_chroma(img)
            print(f"Auto chroma key RGB: {chroma}")
        else:
            chroma = parse_chroma(args.chroma)
        img = img.resize((out_w, out_h), Image.Resampling.LANCZOS)
        img = chroma_key(img, chroma, tolerance=tolerance)
        flags.append("transparent")

    subdir = type_cfg["output_subdir"]
    prefix = type_cfg.get("filename_prefix", args.type)
    staging_dir = project_root / "assets" / "generated" / subdir
    out_path = next_staging_path(staging_dir, prefix, args.id)
    img.save(out_path, "PNG")

    manifest_path = project_root / "assets" / "generated" / "manifest.json"
    entries = load_manifest(manifest_path)
    entry = {
        "filename": out_path.name,
        "path": str(out_path),
        "type": args.type,
        "id": args.id,
        "description": args.description or "",
        "source_tool": args.source_tool or "unknown",
        "source_image": str(source),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "dimensions": f"{out_w}x{out_h}",
        "chroma_key": ("%02X%02X%02X" % chroma) if chroma else None,
        "flags": flags,
        "file_size_bytes": out_path.stat().st_size,
        "promoted": False,
        "promoted_to": None,
    }
    entries.append(entry)
    save_manifest(manifest_path, entries)

    print("=== PROCESS_RESULT ===")
    print(json.dumps(entry, indent=2))
    print(f"Wrote: {out_path}")
    return out_path


def promote(args: argparse.Namespace, project_root: Path) -> Path:
    type_cfg = load_type_config(project_root, args.type)
    promote_dir = project_root / type_cfg["promote_dir"]
    promote_dir.mkdir(parents=True, exist_ok=True)

    if args.to:
        dest = Path(args.to)
        if not dest.is_absolute():
            dest = (project_root / dest).resolve()
    else:
        dest = promote_dir / f"{args.id}.png"

    if args.from_path:
        src = Path(args.from_path)
        if not src.is_absolute():
            src = (project_root / src).resolve()
    else:
        # Latest staging file for this id — prefer exact prefix_id_NNN.png only
        # (avoids matching older files like monster_goblin_warrior_... when id=goblin)
        staging_dir = project_root / "assets" / "generated" / type_cfg["output_subdir"]
        prefix = type_cfg.get("filename_prefix", args.type)
        pattern = re.compile(rf"^{re.escape(prefix)}_{re.escape(args.id)}_\d{{3}}\.png$")
        candidates = sorted(
            [p for p in staging_dir.glob(f"{prefix}_{args.id}_*.png") if pattern.match(p.name)]
        )
        if not candidates:
            raise SystemExit(
                f"No staged files matching {prefix}_{args.id}_NNN.png in {staging_dir}"
            )
        src = candidates[-1]

    if not src.exists():
        raise SystemExit(f"Promote source not found: {src}")

    shutil.copy2(src, dest)

    manifest_path = project_root / "assets" / "generated" / "manifest.json"
    entries = load_manifest(manifest_path)
    rel_promoted = str(dest.relative_to(project_root)).replace("\\", "/")
    updated = False
    for entry in reversed(entries):
        if entry.get("id") == args.id and entry.get("type") == args.type:
            if Path(entry.get("path", "")).name == src.name or entry.get("filename") == src.name:
                entry["promoted"] = True
                entry["promoted_to"] = rel_promoted
                updated = True
                break
    if not updated:
        # Mark by matching path end
        for entry in reversed(entries):
            if entry.get("id") == args.id and entry.get("type") == args.type:
                entry["promoted"] = True
                entry["promoted_to"] = rel_promoted
                updated = True
                break
    save_manifest(manifest_path, entries)

    print("=== PROMOTE_RESULT ===")
    print(json.dumps({"from": str(src), "to": str(dest), "promoted_to": rel_promoted}, indent=2))
    return dest


def main() -> None:
    parser = argparse.ArgumentParser(description="Process/promote Imagine game assets")
    parser.add_argument("--project-root", default=str(DEFAULT_PROJECT_ROOT))
    parser.add_argument("--type", default="item", help="Asset type from asset-types.json")
    parser.add_argument("--id", required=True, help="Stable asset id (e.g. sword)")
    parser.add_argument("--promote", action="store_true", help="Promote staged asset")
    parser.add_argument("--source", help="Source image from image_gen/image_edit")
    parser.add_argument("--from", dest="from_path", help="Staging file to promote")
    parser.add_argument("--to", help="Promote destination path")
    parser.add_argument("--description", default="")
    parser.add_argument("--source-tool", default="unknown", choices=["image_gen", "image_edit", "unknown"])
    parser.add_argument("--chroma", default=None, help="RRGGBB chroma key override (default: auto-sample corners)")
    parser.add_argument(
        "--auto-chroma",
        action="store_true",
        help="Force corner-sampled chroma key (default when --chroma omitted)",
    )
    parser.add_argument(
        "--no-chroma",
        action="store_true",
        help="Skip chroma key (splash/backgrounds)",
    )
    parser.add_argument("--size", type=int, default=None, help="Force square output size")
    parser.add_argument(
        "--tolerance",
        type=int,
        default=55,
        help="Chroma distance tolerance (default 55 for Imagine plates)",
    )
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()

    if args.promote:
        promote(args, project_root)
    else:
        if not args.source:
            raise SystemExit("--source is required unless --promote")
        process_source(args, project_root)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate game assets using Gemini Nano Banana Pro API."""

import argparse
import base64
import io
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv
from PIL import Image

API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/"
    "models/gemini-3-pro-image-preview:generateContent"
)
MAX_RETRIES = 3
RETRY_DELAY_BASE = 2


def load_env(project_root):
    """Load API key from .env file."""
    env_path = project_root / ".env"
    if not env_path.exists():
        print(f"ERROR: .env file not found at {env_path}", file=sys.stderr)
        print("Create it with: GEMINI_API_KEY=your_key_here", file=sys.stderr)
        sys.exit(1)
    load_dotenv(env_path)
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: GEMINI_API_KEY not found in .env", file=sys.stderr)
        sys.exit(1)
    return api_key


def load_config(skill_dir):
    """Load asset type configurations."""
    config_path = skill_dir / "asset-types.json"
    if not config_path.exists():
        print(f"ERROR: Config not found at {config_path}", file=sys.stderr)
        sys.exit(1)
    with open(config_path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_style_fragments(skill_dir):
    """Extract locked prompt fragments from style-reference.md."""
    style_path = skill_dir / "style-reference.md"
    if not style_path.exists():
        return {"preamble": "", "style_keywords": "", "negative_prompt": ""}

    content = style_path.read_text(encoding="utf-8")
    fragments = {}

    for section in ["PREAMBLE", "STYLE_KEYWORDS", "NEGATIVE_PROMPT"]:
        pattern = rf"### {section}\s*```\s*(.*?)```"
        match = re.search(pattern, content, re.DOTALL)
        key = section.lower()
        fragments[key] = match.group(1).strip() if match else ""

    return fragments


def build_prompt(style, type_config, description, transparent):
    """Assemble the full generation prompt."""
    parts = []

    if style.get("preamble"):
        parts.append(style["preamble"])

    subject = type_config["prompt_template"].format(description=description)
    parts.append(f"\nSubject: {subject}")
    parts.append(f"Framing: {type_config['framing']}")

    tech = type_config["technical_params"]
    if transparent:
        if "transparent" not in tech.lower():
            tech += " Transparent/alpha background, no background elements."
    parts.append(f"Technical: {tech}")

    if style.get("style_keywords"):
        parts.append(f"Art style: {style['style_keywords']}")

    if style.get("negative_prompt"):
        parts.append(f"\n{style['negative_prompt']}")

    return "\n".join(parts)


def call_api(api_key, prompt, aspect_ratio, reference_image_path=None):
    """Call Gemini API and return parsed response."""
    headers = {
        "x-goog-api-key": api_key,
        "Content-Type": "application/json",
    }

    content_parts = []

    if reference_image_path:
        ref_path = Path(reference_image_path)
        if ref_path.exists():
            with open(ref_path, "rb") as f:
                img_b64 = base64.b64encode(f.read()).decode("utf-8")
            content_parts.append(
                {
                    "inline_data": {
                        "mime_type": "image/png",
                        "data": img_b64,
                    }
                }
            )
            content_parts.append(
                {
                    "text": (
                        "Use this image as a style reference. "
                        "Generate a new image matching this art style:"
                    )
                }
            )

    content_parts.append({"text": prompt})

    body = {
        "contents": [{"parts": content_parts}],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
            "imageConfig": {"aspectRatio": aspect_ratio},
        },
    }

    for attempt in range(MAX_RETRIES):
        try:
            response = requests.post(
                API_URL, headers=headers, json=body, timeout=60
            )

            if response.status_code == 429:
                delay = RETRY_DELAY_BASE ** (attempt + 1)
                print(
                    f"Rate limited. Retrying in {delay}s "
                    f"(attempt {attempt + 1}/{MAX_RETRIES})..."
                )
                time.sleep(delay)
                continue

            if response.status_code in (401, 403):
                print(
                    "ERROR: Invalid or unauthorized API key. "
                    "Check GEMINI_API_KEY in your .env file.",
                    file=sys.stderr,
                )
                sys.exit(1)

            if response.status_code == 400:
                error_body = {}
                try:
                    error_body = response.json()
                except ValueError:
                    pass
                print(
                    f"ERROR: Bad request: {json.dumps(error_body, indent=2)}",
                    file=sys.stderr,
                )
                sys.exit(1)

            response.raise_for_status()
            result = response.json()
            print(
                f"  API response keys: {list(result.keys())}",
                file=sys.stderr,
            )
            candidates = result.get("candidates", [])
            if candidates:
                parts = candidates[0].get("content", {}).get("parts", [])
                for idx, part in enumerate(parts):
                    part_keys = list(part.keys())
                    print(
                        f"  Part {idx}: keys={part_keys}",
                        file=sys.stderr,
                    )
                    if "text" in part:
                        print(
                            f"  Part {idx} text: {part['text'][:200]}",
                            file=sys.stderr,
                        )
                    inline_dbg = part.get("inline_data") or part.get("inlineData")
                    if inline_dbg:
                        mime = (
                            inline_dbg.get("mime_type")
                            or inline_dbg.get("mimeType", "?")
                        )
                        data_len = len(inline_dbg.get("data", ""))
                        print(
                            f"  Part {idx} image: mime={mime}, "
                            f"data_len={data_len}",
                            file=sys.stderr,
                        )
                finish = candidates[0].get("finishReason", "unknown")
                print(f"  Finish reason: {finish}", file=sys.stderr)
            else:
                print(
                    f"  No candidates. Full response: "
                    f"{json.dumps(result, indent=2)[:500]}",
                    file=sys.stderr,
                )
            return result

        except requests.exceptions.ConnectionError:
            print(
                "ERROR: Cannot reach Gemini API. Check internet connection.",
                file=sys.stderr,
            )
            sys.exit(1)
        except requests.exceptions.Timeout:
            if attempt < MAX_RETRIES - 1:
                delay = RETRY_DELAY_BASE ** (attempt + 1)
                print(f"Request timed out. Retrying in {delay}s...")
                time.sleep(delay)
                continue
            print("ERROR: Request timed out after all retries.", file=sys.stderr)
            sys.exit(1)

    print("ERROR: Max retries exceeded (rate limited).", file=sys.stderr)
    sys.exit(1)


def extract_image_data(response):
    """Extract base64 image and text from API response."""
    candidates = response.get("candidates", [])
    if not candidates:
        print("ERROR: No candidates in API response.", file=sys.stderr)
        sys.exit(1)

    parts = candidates[0].get("content", {}).get("parts", [])
    image_bytes = None
    model_text = ""

    for part in parts:
        # API may return camelCase (inlineData) or snake_case (inline_data)
        inline = part.get("inline_data") or part.get("inlineData")
        if inline:
            b64_data = inline.get("data", "")
            if b64_data:
                image_bytes = base64.b64decode(b64_data)
        elif "text" in part:
            model_text += part["text"]

    if image_bytes is None:
        print(
            f"ERROR: No image in API response. Model text: {model_text}",
            file=sys.stderr,
        )
        sys.exit(1)

    return image_bytes, model_text


def save_image(image_bytes, output_path, target_size):
    """Process and save the generated image. Returns metadata dict."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    image = Image.open(io.BytesIO(image_bytes))
    original_size = image.size

    if image.size != tuple(target_size):
        image = image.resize(tuple(target_size), Image.LANCZOS)

    image.save(output_path, "PNG", optimize=True)
    file_size = output_path.stat().st_size

    return {
        "original_size": list(original_size),
        "final_size": list(target_size),
        "file_size_bytes": file_size,
    }


def sanitize_filename(description):
    """Convert description to a safe filename component."""
    sanitized = re.sub(r"[^\w\s-]", "", description.lower())
    sanitized = re.sub(r"[\s-]+", "_", sanitized)
    return sanitized[:40]


def update_manifest(manifest_path, entry):
    """Append entry to the generation manifest."""
    manifest = []
    if manifest_path.exists():
        try:
            with open(manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)
        except (json.JSONDecodeError, ValueError):
            manifest = []
    manifest.append(entry)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(
        description="Generate game assets via Gemini Nano Banana Pro API"
    )
    parser.add_argument(
        "--type",
        required=True,
        help="Asset type: monster, character, item, ui, background, splash",
    )
    parser.add_argument(
        "--description",
        required=True,
        help="Description of the asset to generate",
    )
    parser.add_argument(
        "--output-dir",
        required=True,
        help="Output directory for generated assets",
    )
    parser.add_argument(
        "--project-root",
        required=True,
        help="Project root directory (for .env and skill files)",
    )
    parser.add_argument(
        "--variations",
        type=int,
        default=1,
        help="Number of variations to generate (default: 1)",
    )
    parser.add_argument(
        "--transparent",
        action="store_true",
        help="Request transparent background (overrides type default)",
    )
    parser.add_argument(
        "--no-transparent",
        action="store_true",
        help="Force opaque background (overrides type default)",
    )
    parser.add_argument(
        "--reference",
        default=None,
        help="Path to a style reference image",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the prompt without calling the API",
    )
    args = parser.parse_args()

    project_root = Path(args.project_root)
    skill_dir = project_root / ".claude" / "skills" / "generate-asset"
    output_dir = Path(args.output_dir)

    # Load configuration
    config = load_config(skill_dir)
    style = load_style_fragments(skill_dir)

    if args.type not in config:
        valid = ", ".join(config.keys())
        print(
            f"ERROR: Unknown asset type '{args.type}'. Valid types: {valid}",
            file=sys.stderr,
        )
        sys.exit(1)

    type_config = config[args.type]

    # Determine transparency
    if args.no_transparent:
        transparent = False
    elif args.transparent:
        transparent = True
    else:
        transparent = type_config.get("transparent_default", False)

    # Build prompt
    prompt = build_prompt(style, type_config, args.description, transparent)

    if args.dry_run:
        print("=== DRY RUN - Prompt ===")
        print(prompt)
        print(f"\nAsset type: {args.type} ({type_config['display_name']})")
        print(f"Aspect ratio: {type_config['aspect_ratio']}")
        print(f"Target size: {type_config['default_size']}")
        print(f"Transparent: {transparent}")
        if args.reference:
            print(f"Reference image: {args.reference}")
        print(f"Variations: {args.variations}")
        return

    # Need API key for live generation
    api_key = load_env(project_root)

    # Generate
    results = []
    name_base = sanitize_filename(args.description)
    subdir = output_dir / type_config.get("output_subdir", args.type)
    manifest_path = output_dir / "manifest.json"

    for i in range(args.variations):
        seq = f"{i + 1:03d}"
        filename = f"{args.type}_{name_base}_{seq}.png"
        output_path = subdir / filename

        print(f"Generating variation {i + 1}/{args.variations}...")

        response = call_api(
            api_key, prompt, type_config["aspect_ratio"], args.reference
        )
        image_bytes, model_text = extract_image_data(response)
        img_meta = save_image(
            image_bytes, output_path, type_config["default_size"]
        )

        entry = {
            "filename": filename,
            "path": str(output_path),
            "type": args.type,
            "description": args.description,
            "prompt_used": prompt,
            "model": "gemini-3-pro-image-preview",
            "model_text": model_text,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "dimensions": (
                f"{type_config['default_size'][0]}x"
                f"{type_config['default_size'][1]}"
            ),
            "aspect_ratio": type_config["aspect_ratio"],
            "flags": ["transparent"] if transparent else [],
            "original_size": img_meta["original_size"],
            "file_size_bytes": img_meta["file_size_bytes"],
            "promoted": False,
            "promoted_to": None,
        }
        update_manifest(manifest_path, entry)
        results.append(entry)

        print(f"  Saved: {output_path}")
        print(f"  Size: {img_meta['file_size_bytes']} bytes")
        if model_text:
            print(f"  Model notes: {model_text[:200]}")

    # Output summary as JSON for Claude to parse
    print("\n=== GENERATION_RESULT ===")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()

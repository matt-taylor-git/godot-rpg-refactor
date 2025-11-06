#!/usr/bin/env python3
"""Generate heroic character sprites facing right for combat."""

import os
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image
import io
from rembg import remove

# Configure API
client = genai.Client(api_key=os.environ.get("GOOGLE_API_KEY"))

# Hero class definitions with heroic descriptions
HEROES = {
    "warrior": "A heroic, brave warrior hero with sword and shield, noble stance, facing right, dark fantasy RPG game sprite, detailed hand-drawn illustration style, heroic posture, armored, side profile view, determined expression",
    "mage": "A heroic, wise mage hero with magical staff, arcane robes flowing, facing right, dark fantasy RPG game sprite, detailed illustration, mystical and powerful, casting pose, side view, confident expression",
    "rogue": "A heroic, agile rogue hero with dual daggers, leather armor, facing right, dark fantasy RPG game sprite, detailed illustration style, heroic and swift, ready stance, side profile, cunning expression",
}

def generate_hero_sprite(name: str, prompt: str, output_path: Path):
    """Generate a single hero sprite."""
    print(f"\n{'='*60}")
    print(f"Generating: {name}")
    print(f"Prompt: {prompt}")
    print(f"{'='*60}")

    try:
        # Generate image using Imagen 3
        config = types.GenerateImagesConfig(
            number_of_images=1,
            aspect_ratio="1:1",
        )

        result = client.models.generate_images(
            model="imagen-3.0-generate-002",
            prompt=prompt,
            config=config,
        )

        if not result.generated_images:
            print(f"❌ No images generated for {name}")
            return False

        # Get the image
        image_bytes = result.generated_images[0].image.image_bytes
        print(f"✓ Generated image: {len(image_bytes)} bytes")

        # Remove background
        print("  Removing background...")
        image = Image.open(io.BytesIO(image_bytes))
        output_image = remove(image)

        # Save
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_image.save(output_path, "PNG")
        print(f"✓ Saved to: {output_path}")

        return True

    except Exception as e:
        print(f"❌ Failed to generate {name}: {e}")
        return False

def main():
    """Generate all hero sprites."""
    project_root = Path(__file__).parent
    assets_dir = project_root / "assets"

    print("="*60)
    print("Hero Sprite Generation")
    print("Generating heroic sprites facing right")
    print("="*60)

    success_count = 0
    failed = []

    for name, prompt in HEROES.items():
        output_path = assets_dir / f"{name}.png"
        if generate_hero_sprite(name, prompt, output_path):
            success_count += 1
        else:
            failed.append(name)

    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    print(f"✓ Successfully generated: {success_count}/{len(HEROES)}")
    if failed:
        print(f"❌ Failed: {', '.join(failed)}")
    print("="*60)

if __name__ == "__main__":
    main()

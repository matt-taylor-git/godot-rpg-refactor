from PIL import Image, ImageDraw

def create_9_slice_frame(path, size, border_width, color, bg_color):
    """Creates a 9-slice compatible frame."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw background
    draw.rectangle([(border_width, border_width), (size - border_width - 1, size - border_width - 1)], fill=bg_color)

    # Draw border
    draw.rectangle([(0, 0), (size - 1, size - 1)], outline=color, width=border_width)

    img.save(path)
    print(f"Generated {path}")

def create_sword_icon(path, size, color):
    """Creates a simple sword icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Hilt
    draw.line([(size // 2, size - 5), (size // 2, size - 15)], fill=color, width=3)
    draw.line([(size // 2 - 5, size - 15), (size // 2 + 5, size - 15)], fill=color, width=3)

    # Blade
    draw.line([(size // 2, size - 16), (size // 2, 5)], fill=color, width=3)
    draw.point((size // 2, 4), fill=color)


    img.save(path)
    print(f"Generated {path}")

if __name__ == "__main__":
    assets_dir = "assets/"
    main_color = "#C4A87A"  # Gold
    bg_color = "#101919"    # Dark Blue/Green

    # Main Frame
    create_9_slice_frame(f"{assets_dir}frame_main.png", 64, 4, main_color, bg_color)

    # Slot Frame
    create_9_slice_frame(f"{assets_dir}frame_slot.png", 32, 2, main_color, bg_color)

    # Sword Icon
    create_sword_icon(f"{assets_dir}icon_sword.png", 32, main_color)

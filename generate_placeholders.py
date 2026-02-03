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

def create_class_icon(path, size, color, icon_type):
    """Creates a simple class icon based on type."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if icon_type == "warrior":
        # Sword icon for warrior
        draw.line([(size // 2, size - 5), (size // 2, size - 15)], fill=color, width=3)
        draw.line([(size // 2 - 5, size - 15), (size // 2 + 5, size - 15)], fill=color, width=3)
        draw.line([(size // 2, size - 16), (size // 2, 5)], fill=color, width=3)
        draw.point((size // 2, 4), fill=color)

    elif icon_type == "mage":
        # Staff icon for mage
        draw.line([(size // 2, size - 5), (size // 2, 5)], fill=color, width=3)
        draw.ellipse([(size // 2 - 3, 5), (size // 2 + 3, 11)], fill=color)
        draw.line([(size // 2 - 2, 8), (size // 2 + 2, 8)], fill=color, width=2)

    elif icon_type == "rogue":
        # Dagger icon for rogue
        draw.line([(size // 2, size - 5), (size // 2, 10)], fill=color, width=2)
        draw.line([(size // 2 - 3, 10), (size // 2 + 3, 10)], fill=color, width=2)
        draw.line([(size // 2, 10), (size // 2, 5)], fill=color, width=2)

    elif icon_type == "hero":
        # Shield icon for hero
        draw.arc([(10, 10), (size - 10, size - 10)], 0, 180, fill=color, width=3)
        draw.line([(10, size // 2), (size - 10, size // 2)], fill=color, width=3)

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

    # Class Icons
    create_class_icon(f"{assets_dir}ui/icons/warrior.png", 64, main_color, "warrior")
    create_class_icon(f"{assets_dir}ui/icons/mage.png", 64, main_color, "mage")
    create_class_icon(f"{assets_dir}ui/icons/rogue.png", 64, main_color, "rogue")
    create_class_icon(f"{assets_dir}ui/icons/hero.png", 64, main_color, "hero")

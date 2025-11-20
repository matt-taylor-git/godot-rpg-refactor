#!/usr/bin/env python3
"""
UIButton Migration Script
Replaces regular Button nodes with UIButton component instances in Godot scene files.
"""

import os
import re
import glob


def migrate_scene_file(scene_path):
    """Migrate a single scene file to use UIButton components."""
    with open(scene_path, "r") as f:
        content = f.read()

    # Check if already migrated
    if "ui_button.tscn" in content:
        print(f"Already migrated: {scene_path}")
        return False

    # Find all Button nodes
    button_pattern = r'\[node name="([^"]+)" type="Button" parent="([^"]+)"\]'
    buttons = re.findall(button_pattern, content)

    if not buttons:
        print(f"No buttons found: {scene_path}")
        return False

    # Add external resource reference
    ext_resource_pattern = r'(\[ext_resource type="Script" path="[^"]+" id="(\d+)"\])'
    ext_resources = re.findall(ext_resource_pattern, content)

    # Find the highest ID number
    max_id = 0
    for _, id_str in ext_resources:
        max_id = max(max_id, int(id_str))

    new_id = max_id + 1

    if ext_resources:
        # Insert after the last ext_resource
        last_ext_resource = ext_resources[-1][0]
        new_ext_resource = f'\n[ext_resource type="PackedScene" uid="uid://banlt66gdvndq" path="res://scenes/components/ui_button.tscn" id="{new_id}"]'
        content = content.replace(
            last_ext_resource, last_ext_resource + new_ext_resource
        )
    else:
        # No ext_resources found, add at the beginning
        header_end = content.find("\n\n[node name=")
        if header_end == -1:
            print(f"Could not find header end in {scene_path}")
            return False

        new_ext_resource = f'[ext_resource type="PackedScene" uid="uid://banlt66gdvndq" path="res://scenes/components/ui_button.tscn" id="{new_id}"]\n\n'
        content = content[:header_end] + new_ext_resource + content[header_end:]

    # Replace Button nodes with UIButton instances
    for button_name, parent in buttons:
        old_pattern = rf'\[node name="{button_name}" type="Button" parent="{parent}"\]'
        new_pattern = rf'[node name="{button_name}" parent="{parent}" instance=ExtResource("{new_id}")]'
        content = re.sub(old_pattern, new_pattern, content)

    # Write back
    with open(scene_path, "w") as f:
        f.write(content)

    print(f"Migrated {len(buttons)} buttons in: {scene_path}")
    return True


def main():
    """Main migration function."""
    # Find all scene files in scenes/ui/
    scene_files = glob.glob("scenes/ui/*.tscn")

    migrated_count = 0
    total_buttons = 0

    for scene_file in scene_files:
        # Skip already migrated files
        with open(scene_file, "r") as f:
            if "ui_button.tscn" in f.read():
                continue

        # Count buttons before migration
        with open(scene_file, "r") as f:
            content = f.read()
            buttons_before = len(re.findall(r'type="Button"', content))

        if migrate_scene_file(scene_file):
            migrated_count += 1
            total_buttons += buttons_before

    print(f"\nMigration complete!")
    print(f"Files migrated: {migrated_count}")
    print(f"Total buttons replaced: {total_buttons}")


if __name__ == "__main__":
    main()

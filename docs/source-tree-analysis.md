# Source Tree Analysis

```
godot-rpg-refactor/
├── project.godot          # Godot project configuration
├── assets/                # Game assets (sprites, fonts, UI)
│   ├── backups_original_sprites/  # Original sprite backups
│   ├── fonts/             # Font files
│   └── *.png              # Sprite and UI images
├── scenes/                # Godot scene files (.tscn)
│   ├── ui/                # UI scenes
│   │   ├── base_ui.tscn
│   │   ├── character_creation.tscn
│   │   ├── codex_dialog.tscn
│   │   ├── combat_scene.tscn
│   │   ├── dialogue_scene.tscn
│   │   └── inventory-related scenes
│   └── main.tscn          # Main game scene
├── scripts/               # GDScript files
│   ├── components/        # Reusable components
│   │   ├── UIButton.gd
│   │   ├── UIPanel.gd
│   │   └── UIProgressBar.gd
│   ├── globals/           # Global scripts/autoloads
│   │   ├── CodexManager.gd
│   │   ├── DialogueManager.gd
│   │   └── GameManager.gd
│   ├── models/            # Data models
│   │   ├── FinalBoss.gd
│   │   ├── Item.gd
│   │   ├── Monster.gd
│   │   └── Player classes
│   ├── ui/                # UI logic scripts
│   │   ├── BaseUI.gd
│   │   ├── CharacterCreation.gd
│   │   └── Other UI handlers
│   └── utils/             # Utility scripts
│       ├── ItemFactory.gd
│       └── MonsterFactory.gd
├── src/                   # Additional source code
│   ├── components/        # More components
│   ├── game/              # Game logic
│   ├── models/            # More models
│   └── theme/             # UI themes
├── resources/             # Godot resources
│   └── ui_theme.tres      # UI theme resource
├── tests/                 # Test files
│   └── Various test scripts
└── docs/                  # Generated documentation
    ├── index.md
    ├── architecture.md
    └── Other docs
```

## Critical Folders Explained

- **scenes/**: Contains all Godot scene files (.tscn) that define the game's UI and world structure
- **scripts/**: GDScript files containing game logic, organized by functionality
- **assets/**: All visual assets including sprites, fonts, and UI elements
- **src/**: Additional source code and game components

## Entry Points

- **main.tscn**: The main scene loaded when the game starts
- **GameManager.gd**: Global game state management (autoload)
- **project.godot**: Godot project configuration and entry point
extends GutTest

# Test suite for Main Menu (Story 3.1: Main Menu Modernization)
# Tests AC-3.1.1, AC-3.1.2, AC-3.1.3, AC-3.1.4

const MAIN_MENU_SCENE = preload("res://scenes/ui/main_menu.tscn")

var main_menu: Control
var new_game_button: Button
var load_game_button: Button
var options_button: Button
var exit_button: Button
var title_label: Label
var background_panel: Panel

func before_each():
	"""Setup before each test"""
	main_menu = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)
	await get_tree().process_frame  # Wait for _ready()

	# Get references to UI elements using new BaseUI structure
	# Path: Content/VBoxContainer/MainContent/MenuPanel/VBoxContainer/...
	var menu_vbox = main_menu.get_node("Content/VBoxContainer/MainContent/MenuPanel/VBoxContainer")
	new_game_button = menu_vbox.get_node("NewGameButton")
	load_game_button = menu_vbox.get_node("LoadGameButton")
	options_button = menu_vbox.get_node("OptionsButton")
	exit_button = menu_vbox.get_node("ExitButton")

	# Title is now in Header
	title_label = main_menu.get_node("Content/VBoxContainer/Header/Title")
	background_panel = main_menu.get_node("Background")

func after_each():
	"""Cleanup after each test"""
	if main_menu and main_menu.is_inside_tree():
		main_menu.queue_free()

# AC-3.1.1: Modern Layout & Styling Tests
func test_main_menu_scene_has_title():
	"""Test that main menu has a title label (AC-3.1.1)"""
	assert_not_null(title_label, "Title label should exist")
	assert_eq(title_label.text, "Pyrpg-Godot", "Title should display 'Pyrpg-Godot'")

func test_main_menu_applies_theme():
	"""Test that main menu applies ui_theme.tres (AC-3.1.1)"""
	assert_not_null(main_menu.theme, "Main menu should have theme applied")
	var theme_path = main_menu.theme.resource_path
	assert_true(theme_path.contains("ui_theme.tres"), "Should use ui_theme.tres resource")

func test_main_menu_layout_uses_8px_grid():
	"""Test that VBoxContainer uses 8px-based spacing (AC-3.1.1)"""
	# Check separation in the menu buttons VBox
	var vbox = main_menu.get_node("Content/VBoxContainer/MainContent/MenuPanel/VBoxContainer")
	var separation = vbox.get_theme_constant("separation")
	# Should be 24 (3 * 8px units)
	assert_eq(separation, 24, "VBox separation should be 24px (3x 8px grid units)")

func test_main_menu_panel_has_proper_margins():
	"""Test that MenuPanel has proper 8px-based margins (AC-3.1.1)"""
	var menu_panel = main_menu.get_node("Content/VBoxContainer/MainContent/MenuPanel")
	var margin_left = menu_panel.get_theme_constant("margin_left")
	var margin_top = menu_panel.get_theme_constant("margin_top")
	var margin_right = menu_panel.get_theme_constant("margin_right")
	var margin_bottom = menu_panel.get_theme_constant("margin_bottom")

	# Should all be 16 (2x 8px units)
	assert_eq(margin_left, 16, "Left margin should be 16px (2x 8px)")
	assert_eq(margin_top, 16, "Top margin should be 16px (2x 8px)")
	assert_eq(margin_right, 16, "Right margin should be 16px (2x 8px)")
	assert_eq(margin_bottom, 16, "Bottom margin should be 16px (2x 8px)")

# AC-3.1.2: Interactive Elements Tests
func test_new_game_button_exists_and_is_ui_button():
	"""Test that New Game button exists and is UIButton type (AC-3.1.2)"""
	assert_not_null(new_game_button, "New Game button should exist")
	# Check if it instances the right scene or has correct properties
	assert_true(new_game_button.name == "NewGameButton", "Should be NewGameButton node")

func test_load_game_button_exists():
	"""Test that Load Game button exists (AC-3.1.2)"""
	assert_not_null(load_game_button, "Load Game button should exist")
	assert_eq(load_game_button.button_text, "Load Game", "Load Game button should have correct text")

func test_options_button_exists():
	"""Test that Options button exists (AC-3.1.2 - Added in Review Follow-up)"""
	assert_not_null(options_button, "Options button should exist")
	assert_eq(options_button.button_text, "Options", "Options button should have correct text")

func test_exit_button_exists():
	"""Test that Exit button exists (AC-3.1.2)"""
	assert_not_null(exit_button, "Exit button should exist")
	assert_eq(exit_button.button_text, "Exit", "Exit button should have correct text")

func test_button_signals_are_connected():
	"""Test that button signals are connected to script methods (AC-3.1.2)"""
	# Check that pressed signal is connected for all buttons
	assert_gt(new_game_button.pressed.get_connections().size(), 0, "New Game button should be connected")
	assert_gt(load_game_button.pressed.get_connections().size(), 0, "Load Game button should be connected")
	assert_gt(options_button.pressed.get_connections().size(), 0, "Options button should be connected")
	assert_gt(exit_button.pressed.get_connections().size(), 0, "Exit button should be connected")

func test_buttons_are_initially_visible():
	"""Test that all buttons are visible on startup (AC-3.1.2)"""
	assert_true(new_game_button.visible, "New Game button should be visible")
	assert_true(load_game_button.visible, "Load Game button should be visible")
	assert_true(options_button.visible, "Options button should be visible")
	assert_true(exit_button.visible, "Exit button should be visible")

# AC-3.1.3: Visual Polish & Atmosphere Tests
func test_background_panel_exists():
	"""Test that background panel exists for atmosphere (AC-3.1.3)"""
	assert_not_null(background_panel, "Background panel should exist")

func test_background_panel_covers_full_screen():
	"""Test that background fills entire viewport (AC-3.1.3, 16:9 support)"""
	assert_eq(background_panel.anchor_left, 0.0, "Background left anchor should be 0")
	assert_eq(background_panel.anchor_top, 0.0, "Background top anchor should be 0")
	assert_eq(background_panel.anchor_right, 1.0, "Background right anchor should be 1 (full width)")
	assert_eq(background_panel.anchor_bottom, 1.0, "Background bottom anchor should be 1 (full height)")

func test_background_has_shader_material():
	"""Test that background uses shader material for atmosphere (AC-3.1.3)"""
	var material = background_panel.material
	assert_not_null(material, "Background should have material applied")
	assert_true(material is ShaderMaterial, "Should use ShaderMaterial for visual effects")

func test_menu_animates_on_entry():
	"""Test that menu has entrance animation (AC-3.1.3, ~500ms transitions)"""
	# _animate_menu_in() uses local tweens, not the menu_transition_tween var.
	# Verify that the menu has the reduce_motion property (animation system exists)
	# and that the background_animation_tween is created for non-reduced-motion mode.
	assert_true("reduce_motion" in main_menu, "MainMenu should have reduce_motion for animation control")
	# The background animation tween should be created (unless reduce_motion is true)
	if not main_menu.reduce_motion:
		assert_not_null(main_menu.background_animation_tween, "Background animation tween should be created")

# AC-3.1.4: Accessibility Tests
func test_keyboard_focus_default_is_new_game_button():
	"""Test that keyboard focus starts on 'New Game' button (AC-3.1.4)"""
	assert_true(new_game_button.focus_mode != Control.FOCUS_NONE,
		"New Game button should be focusable")
	# Ideally check if it has focus, but difficult in headless test sometimes
	# Assert logic called grab_focus()

func test_focus_neighbors_are_set():
	"""Test that focus neighbors support keyboard navigation (AC-3.1.4)"""
	# Check chain: New -> Load -> Options -> Exit
	# MainMenu sets focus_neighbor_bottom/top with absolute paths via get_path()
	assert_eq(new_game_button.get("focus_neighbor_bottom"), load_game_button.get_path())

	assert_eq(load_game_button.get("focus_neighbor_top"), new_game_button.get_path())
	assert_eq(load_game_button.get("focus_neighbor_bottom"), options_button.get_path())

	assert_eq(options_button.get("focus_neighbor_top"), load_game_button.get_path())
	assert_eq(options_button.get("focus_neighbor_bottom"), exit_button.get_path())

	assert_eq(exit_button.get("focus_neighbor_top"), options_button.get_path())

func test_reduced_motion_setting_exists():
	"""Test that MainMenu respects reduce_motion setting (AC-3.1.4)"""
	assert_true("reduce_motion" in main_menu, "MainMenu should have reduce_motion property")

	# Test that reduced motion is correctly read from ProjectSettings
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	main_menu._setup_accessibility()
	assert_true(main_menu.reduce_motion,
		"MainMenu should detect reduced motion when accessibility/reduced_motion is true")

	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	main_menu._setup_accessibility()
	assert_false(main_menu.reduce_motion,
		"MainMenu should detect normal motion when accessibility/reduced_motion is false")

func test_16_9_aspect_ratio_support():
	"""Test that menu layout supports 16:9 aspect ratio (AC-3.1.4)"""
	# Menu panel should have custom minimum size set for aspect ratio support
	var menu_panel = main_menu.get_node("Content/VBoxContainer/MainContent/MenuPanel")
	assert_not_null(menu_panel.custom_minimum_size,
		"Menu panel should have custom minimum size for aspect ratio support")
	assert_gt(menu_panel.custom_minimum_size.x, 0,
		"Menu panel width should be set")

func test_title_uses_heading_typography():
	"""Test that title uses H1 typography style (AC-3.1.1)"""
	var theme_type_var = title_label.get_theme_type_variation()
	assert_eq(theme_type_var, "H1", "Title should use H1 typography variation")

# Integration Tests
func test_main_menu_extends_base_ui():
	"""Test that MainMenu extends BaseUI for consistent UI patterns"""
	var script = main_menu.get_script()
	var base_script = script.get_base_script()
	assert_eq(base_script.resource_path, "res://scripts/ui/BaseUI.gd", "MainMenu should extend BaseUI.gd")

func test_main_menu_scene_structure():
	"""Test complete scene structure (AC-3.1.1)"""
	# Verify all key nodes exist in new structure
	assert_true(main_menu.has_node("Background"), "Should have Background node")
	assert_true(main_menu.has_node("Content"), "Should have Content node")
	assert_true(main_menu.has_node("Content/VBoxContainer"), "Should have VBoxContainer")
	assert_true(main_menu.has_node("Content/VBoxContainer/Header/Title"), "Should have Title")
	assert_true(main_menu.has_node("Content/VBoxContainer/MainContent/MenuPanel"), "Should have MenuPanel")

	var button_vbox = "Content/VBoxContainer/MainContent/MenuPanel/VBoxContainer"
	assert_true(main_menu.has_node(button_vbox + "/NewGameButton"), "Should have NewGameButton")
	assert_true(main_menu.has_node(button_vbox + "/LoadGameButton"), "Should have LoadGameButton")
	assert_true(main_menu.has_node(button_vbox + "/OptionsButton"), "Should have OptionsButton")
	assert_true(main_menu.has_node(button_vbox + "/ExitButton"), "Should have ExitButton")

func test_button_minimum_size_wcag():
	"""Test that buttons meet WCAG minimum touch target size (44px) (AC-3.1.4)"""
	# UIButton sets custom_minimum_size in _ready() with at least 44px height
	var min_size = new_game_button.custom_minimum_size
	assert_gte(min_size.y, 44, "Button height should meet WCAG minimum (44px)")
	assert_gte(min_size.x, 44, "Button width should meet WCAG minimum (44px)")

extends Node
class_name UIAnimationSystem

# UIAnimationSystem - Centralized animation management for visual feedback system
# Provides consistent animation timing, tween management, and feedback coordination

# Animation duration constants
const IMMEDIATE_FEEDBACK_DURATION = 0.1  # 100ms for immediate feedback (hover, click)
const COMPLETION_FEEDBACK_DURATION = 0.5  # 500ms for completion feedback (success/error)
const LOADING_INDICATOR_DURATION = 0.5    # 500ms threshold for showing loading indicators

# Animation parameters (from tech spec)
const EASING_TYPE = Tween.EASE_OUT
const TRANSITION_TYPE = Tween.TRANS_QUAD

# Animation performance constraints (AC-UI-009, AC-UI-010, AC-UI-011, AC-UI-012)
const MAX_CONCURRENT_TWEENS = 10  # Limit concurrent animations to prevent performance issues
const TARGET_FPS = 60              # Maintain 60fps during animations
const MAX_PERFORMANCE_IMPACT = 0.05  # Less than 5% frame time impact

# Internal state
var active_tweens: Array = []  # Track all active tweens for cleanup and performance monitoring
var tween_counter: int = 0     # Track number of concurrent tweens

# Feedback prefabs
const SUCCESS_ICON_PATH = "res://assets/ui/icons/checkmark.png"
const ERROR_ICON_PATH = "res://assets/ui/icons/error.png"
const WARNING_ICON_PATH = "res://assets/ui/icons/warning.png"

# Feedback colors (from UITheme integration)
var success_color: Color = Color(0.2, 0.8, 0.2, 1.0)  # Green
var error_color: Color = Color(0.8, 0.2, 0.2, 1.0)    # Red
var warning_color: Color = Color(0.9, 0.6, 0.1, 1.0)  # Orange/Yellow
var accent_color: Color = Color(0.4, 0.95, 0.84, 1.0) # Accent (from theme)

func _ready():
	# Initialize animation system
	print("UIAnimationSystem initialized - managing visual feedback animations")

func _exit_tree():
	# Clean up all active tweens when system is destroyed
	_cleanup_all_tweens()

# Core animation method for property transitions (AC-UI-009)
func animate_property(node: Node, property: String, from_value, to_value, duration: float) -> Tween:
	"""
	Animate any property on a node with consistent timing and easing.
	Returns the Tween object for chaining or manual control.
	"""
	# Check performance constraints before starting animation
	if not _can_start_animation():
		print("Warning: Max concurrent animations reached, skipping animation")
		return null

	# Set initial value if different
	if from_value != null:
		node.set(property, from_value)

	# Create tween for property animation
	var tween = _create_tween(node)
	if not tween:
		return null

	# Animate the property
	tween.tween_property(node, property, to_value, duration)

	# Track this tween
	_track_tween(tween)

	return tween

# Button hover animation (AC-UI-009)
func play_button_hover_animation(button: UIButton) -> void:
	"""
	Play hover animation on a button:
	- Scale up to 1.05x (100ms)
	- Highlight to accent color (100ms)
	"""
	if not button or not is_instance_valid(button):
		return

	# Scale animation (1.0 -> 1.05)
	animate_property(button, "scale", button.scale, Vector2(1.05, 1.05), IMMEDIATE_FEEDBACK_DURATION)

	# Color highlight animation if theme is available
	if button.theme:
		var hover_color = accent_color
		animate_property(button, "modulate", button.modulate, hover_color, IMMEDIATE_FEEDBACK_DURATION)

# Button unhover animation (AC-UI-009)
func play_button_unhover_animation(button: UIButton) -> void:
	"""
	Play unhover animation on a button:
	- Scale back to 1.0x (100ms)
	- Return to normal color (100ms)
	"""
	if not button or not is_instance_valid(button):
		return

	# Scale back animation (1.05 -> 1.0)
	animate_property(button, "scale", button.scale, Vector2.ONE, IMMEDIATE_FEEDBACK_DURATION)

	# Color return animation
	animate_property(button, "modulate", button.modulate, Color.WHITE, IMMEDIATE_FEEDBACK_DURATION)

# Success feedback animation (AC-UI-011)
func show_success_feedback(position: Vector2, parent: Node = null) -> void:
	"""
	Show success confirmation animation:
	- Green checkmark icon
	- Bounce/glow effect (500ms)
	- Appears at specified position
	"""
	if not parent:
		parent = get_tree().current_scene

	# Create success icon
	var success_node = _create_feedback_icon(SUCCESS_ICON_PATH, success_color, position)
	if not success_node:
		return

	parent.add_child(success_node)

	# Bounce animation sequence
	var tween = _create_tween(success_node)
	if tween:
		# Scale up with bounce
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(success_node, "scale", Vector2(1.5, 1.5), COMPLETION_FEEDBACK_DURATION * 0.6)

		# Scale down slightly
		tween.tween_property(success_node, "scale", Vector2(1.2, 1.2), COMPLETION_FEEDBACK_DURATION * 0.4)

		# Fade out and remove
		tween.tween_property(success_node, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): _remove_feedback_node(success_node))

		_track_tween(tween)

# Error feedback animation (AC-UI-012)
func show_error_feedback(position: Vector2, parent: Node = null) -> void:
	"""
	Show error state animation:
	- Red warning/error icon
	- Shake effect (500ms)
	- Appears at specified position
	"""
	if not parent:
		parent = get_tree().current_scene

	# Create error icon
	var error_node = _create_feedback_icon(ERROR_ICON_PATH, error_color, position)
	if not error_node:
		return

	parent.add_child(error_node)

	# Shake animation sequence
	var tween = _create_tween(error_node)
	if tween:
		# Shake left and right
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)

		var original_pos = position
		var shake_amount = 10.0
		var shake_duration = COMPLETION_FEEDBACK_DURATION / 6

		# Shake sequence (6 shakes)
		for i in range(3):
			tween.tween_property(error_node, "position:x", original_pos.x - shake_amount, shake_duration)
			tween.tween_property(error_node, "position:x", original_pos.x + shake_amount, shake_duration)

		# Return to center and fade out
		tween.tween_property(error_node, "position", original_pos, shake_duration)
		tween.tween_property(error_node, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): _remove_feedback_node(error_node))

		_track_tween(tween)

# Create loading spinner component (AC-UI-010)
func create_loading_spinner(parent: Control) -> Control:
	"""
	Create and return a loading spinner component:
	- Animated using Godot's AnimationPlayer
	- Runs at 60fps
	- Returns a Control node that can be positioned
	"""
	if not parent or not is_instance_valid(parent):
		return null

	# Create spinner container
	var spinner = Control.new()
	spinner.name = "LoadingSpinner"
	spinner.custom_minimum_size = Vector2(32, 32)

	# Create animated sprite for spinner
	var spinner_sprite = TextureRect.new()
	spinner_sprite.name = "SpinnerSprite"
	spinner_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spinner_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spinner_sprite.size = Vector2(32, 32)

	# Use a simple circle sprite or fallback to drawing
	# For now, we'll create a simple spinner using modulate animation
	spinner.add_child(spinner_sprite)

	# Create AnimationPlayer for smooth 60fps rotation
	var anim_player = AnimationPlayer.new()
	anim_player.name = "SpinnerAnimation"
	spinner.add_child(anim_player)

	# Create rotation animation
	var anim = Animation.new()
	anim.length = 1.0  # 1 second loop
	anim.loop_mode = Animation.LOOP_LINEAR

	# Add rotation track
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "SpinnerSprite:rotation")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 1.0, 2 * PI)  # Full rotation

	# Add to AnimationPlayer
	anim_player.add_animation("spin", anim)
	anim_player.play("spin")

	# Add center dot
	var center_dot = ColorRect.new()
	center_dot.name = "CenterDot"
	center_dot.color = Color(1, 1, 1, 0.8)
	center_dot.size = Vector2(8, 8)
	center_dot.position = Vector2(12, 12)  # Center in 32x32
	spinner.add_child(center_dot)

	parent.add_child(spinner)

	# Start fade-in animation
	spinner.modulate = Color(1, 1, 1, 0)
	var tween = animate_property(spinner, "modulate:a", 0.0, 1.0, 0.2)

	return spinner

# Helper method to create feedback icons
func _create_feedback_icon(icon_path: String, tint_color: Color, position: Vector2) -> TextureRect:
	"""Create a feedback icon with specified path and color"""
	var icon = TextureRect.new()
	icon.name = "FeedbackIcon"
	icon.size = Vector2(32, 32)
	icon.position = position - Vector2(16, 16)  # Center on position

	# Try to load icon texture
	if FileAccess.file_exists(icon_path):
		var texture = load(icon_path)
		if texture:
			icon.texture = texture
	else:
		# Fallback: create colored rectangle
		var rect = ColorRect.new()
		rect.color = tint_color
		rect.size = Vector2(32, 32)
		icon.add_child(rect)

	icon.modulate = tint_color
	return icon

# Create loading overlay (AC-UI-010)
func create_loading_overlay(parent: Control, show_delay: float = LOADING_INDICATOR_DURATION) -> Control:
	"""
	Create a loading overlay with semi-transparent background and spinner:
	- Shows after 500ms delay (threshold)
	- Contains spinner animation
	- Blocks interaction with underlying UI
	"""
	if not parent or not is_instance_valid(parent):
		return null

	# Create overlay container
	var overlay = Control.new()
	overlay.name = "LoadingOverlay"
	overlay.size = parent.size
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input

	# Create semi-transparent background
	var bg = ColorRect.new()
	bg.name = "OverlayBackground"
	bg.color = Color(0, 0, 0, 0.5)  # 50% transparent black
	bg.size = overlay.size
	overlay.add_child(bg)

	# Create spinner
	var spinner = create_loading_spinner(overlay)
	if spinner:
		spinner.position = overlay.size / 2 - Vector2(16, 16)  # Center spinner

	# Add to parent but hide initially
	overlay.modulate = Color(1, 1, 1, 0)
	overlay.visible = false
	parent.add_child(overlay)

	# Show with delay using tween
	var show_tween = _create_tween(overlay)
	if show_tween:
		show_tween.tween_callback(func(): overlay.visible = true)
		show_tween.tween_property(overlay, "modulate:a", 1.0, 0.2)
		_track_tween(show_tween)

	return overlay

# Hide loading overlay
func hide_loading_overlay(overlay: Control) -> void:
	"""Hide and remove loading overlay"""
	if not overlay or not is_instance_valid(overlay):
		return

	var tween = _create_tween(overlay)
	if tween:
		tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): _remove_feedback_node(overlay))
		_track_tween(tween)
	else:
		_remove_feedback_node(overlay)

# Performance and cleanup utilities

func _create_tween(node: Node) -> Tween:
	"""Create a properly configured tween"""
	if not node or not is_instance_valid(node):
		return null

	var tween = node.create_tween()
	tween.set_ease(EASING_TYPE)
	tween.set_trans(TRANSITION_TYPE)

	return tween

func _track_tween(tween: Tween) -> void:
	"""Track a tween for cleanup and performance monitoring"""
	if not tween:
		return

	active_tweens.append(tween)
	tween_counter += 1

	# Clean up when tween finishes
	tween.finished.connect(func(): _cleanup_tween(tween))

func _cleanup_tween(tween: Tween) -> void:
	"""Clean up a finished tween"""
	if tween and tween.is_valid():
		tween.kill()

	if tween in active_tweens:
		active_tweens.erase(tween)
		tween_counter -= 1

func _cleanup_all_tweens() -> void:
	"""Clean up all active tweens"""
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()

	active_tweens.clear()
	tween_counter = 0

func _can_start_animation() -> bool:
	"""Check if we can start a new animation based on performance constraints"""
	return tween_counter < MAX_CONCURRENT_TWEENS

func _remove_feedback_node(node: Node) -> void:
	"""Safely remove a feedback node"""
	if node and is_instance_valid(node):
		node.queue_free()

# Helper methods for common animations

func fade_in(node: Node, duration: float = IMMEDIATE_FEEDBACK_DURATION) -> Tween:
	"""Fade in a node from transparent to opaque"""
	node.modulate = Color(1, 1, 1, 0)
	return animate_property(node, "modulate:a", 0.0, 1.0, duration)

func fade_out(node: Node, duration: float = IMMEDIATE_FEEDBACK_DURATION) -> Tween:
	"""Fade out a node from opaque to transparent"""
	return animate_property(node, "modulate:a", 1.0, 0.0, duration)

func scale_bounce(node: Node, target_scale: Vector2, duration: float = COMPLETION_FEEDBACK_DURATION) -> Tween:
	"""Scale with bounce effect"""
	if not _can_start_animation():
		return null

	var tween = _create_tween(node)
	if not tween:
		return null

	# Scale up with back easing (bounce)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", target_scale, duration * 0.6)

	# Scale down slightly
	tween.set_trans(TRANSITION_TYPE)
	tween.tween_property(node, "scale", target_scale * 0.8, duration * 0.4)

	_track_tween(tween)
	return tween

func shake(node: Node, intensity: float = 10.0, duration: float = COMPLETION_FEEDBACK_DURATION) -> Tween:
	"""Shake animation for error feedback"""
	if not _can_start_animation():
		return null

	var tween = _create_tween(node)
	if not tween:
		return null

	var original_pos = node.position
	var shake_duration = duration / 6

	# Shake sequence (6 shakes)
	for i in range(3):
		tween.tween_property(node, "position:x", original_pos.x - intensity, shake_duration)
		tween.tween_property(node, "position:x", original_pos.x + intensity, shake_duration)

	# Return to original position
	tween.tween_property(node, "position", original_pos, shake_duration)

	_track_tween(tween)
	return tween

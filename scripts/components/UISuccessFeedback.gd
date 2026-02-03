class_name UISuccessFeedback
extends Node

# UISuccessFeedback - Success confirmation feedback component
# Provides bounce/glow animations, green color coding, and sound integration

# Signals
signal feedback_shown  # Emitted when feedback animation starts
signal feedback_complete  # Emitted when feedback animation completes

# Configuration
@export var auto_show: bool = false  # Automatically show on ready
@export var animation_duration: float = 0.5  # 500ms duration
@export var bounce_scale: Vector2 = Vector2(1.5, 1.5)  # Final scale after bounce
@export var sound_effect: AudioStream = null  # Sound effect to play
@export var position_offset: Vector2 = Vector2(0, -50)  # Offset from anchor node

# Internal state
var animation_system: UIAnimationSystem = null
var feedback_icon: TextureRect = null
var is_showing: bool = false

func _ready():
	# Initialize animation system reference
	animation_system = UIAnimationSystem.new()
	add_child(animation_system)

	# Auto-show if configured
	if auto_show:
		call_deferred("show_feedback")

func show_feedback(anchor_node: Node = null) -> void:
	"""
	Show success feedback animation:
	- Creates green checkmark icon
	- Plays bounce/glow animation (500ms)
	- Plays sound effect if configured
	- Positions relative to anchor_node or center screen
	"""
	if is_showing:
		return

	is_showing = true

	# Determine position
	var position = Vector2.ZERO
	if anchor_node:
		# Position relative to anchor node
		if anchor_node is Control:
			position = anchor_node.global_position + Vector2(anchor_node.size.x / 2, anchor_node.size.y / 2)
		else:
			position = anchor_node.global_position
		position += position_offset
	else:
		# Center of viewport
		var viewport = get_viewport().get_visible_rect()
		position = viewport.size / 2 + position_offset

	# Show feedback using animation system
	animation_system.show_success_feedback(position, get_parent())

	# Play sound effect
	if sound_effect:
		_play_sound()

	feedback_shown.emit()

	# Complete animation
	call_deferred("_on_feedback_complete")

func show_feedback_at_position(position: Vector2) -> void:
	"""
	Show success feedback at specific position
	"""
	if is_showing:
		return

	is_showing = true

	# Show feedback using animation system
	animation_system.show_success_feedback(position, get_parent())

	# Play sound effect
	if sound_effect:
		_play_sound()

	feedback_shown.emit()
	call_deferred("_on_feedback_complete")

func show_feedback_near_mouse() -> void:
	"""
	Show success feedback near mouse cursor
	"""
	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	show_feedback_at_position(mouse_pos + position_offset)

func set_sound_effect(stream: AudioStream) -> void:
	"""
	Set sound effect to play with feedback
	"""
	sound_effect = stream

func set_animation_duration(duration: float) -> void:
	"""
	Override default 500ms animation duration
	"""
	animation_duration = duration

# Internal methods

func _play_sound() -> void:
	"""
	Play success sound effect
	"""
	if not sound_effect:
		return

	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sound_effect
	audio_player.volume_db = -10.0  # Default volume
	add_child(audio_player)
	audio_player.play()

	# Clean up after playing
	audio_player.finished.connect(func():
		audio_player.queue_free()
	)

func _on_feedback_complete() -> void:
	"""
	Called when feedback animation completes
	"""
	is_showing = false
	feedback_complete.emit()

# Factory methods

static func create_and_show(parent: Node, anchor: Node = null, sound: AudioStream = null) -> UISuccessFeedback:
	"""
	Factory method: Create and immediately show success feedback
	"""
	var feedback = UISuccessFeedback.new()
	parent.add_child(feedback)

	if sound:
		feedback.set_sound_effect(sound)

	feedback.show_feedback(anchor)

	return feedback

static func attach_to_button(button: UIButton, sound: AudioStream = null) -> UISuccessFeedback:
	"""
	Attach success feedback to a button - shows when button is pressed
	"""
	var feedback = UISuccessFeedback.new()
	feedback.set_sound_effect(sound)
	button.add_child(feedback)

	# Connect to button press
	button.connect("pressed", Callable(feedback, "show_feedback").bind(button))

	return feedback

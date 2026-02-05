class_name UIErrorFeedback
extends Node

# UIErrorFeedback - Error state feedback component
# Provides shake/red flash animations, red color coding, and error persistence

# Signals
signal error_shown  # Emitted when error is shown
signal error_dismissed  # Emitted when error is dismissed

# Configuration
@export var error_color: Color = Color(0.8, 0.2, 0.2, 1.0)  # Red color coding
@export var animation_duration: float = 0.5  # 500ms duration
@export var shake_intensity: float = 15.0  # Shake amount in pixels
@export var persists_until_corrected: bool = true  # Stay visible until error is fixed
@export var sound_effect: AudioStream = null  # Error sound effect
@export var position_offset: Vector2 = Vector2(0, -50)  # Offset from anchor node

# Internal state
var animation_system: UIAnimationSystem = null
var error_nodes: Array = []  # Track error UI elements
var is_showing: bool = false
var error_message: String = ""

func _ready():
	# Initialize animation system reference
	animation_system = UIAnimationSystem.new()
	add_child(animation_system)

func show_error(anchor_node: Node = null, message: String = "Error occurred") -> void:
	"""
	Show error feedback animation:
	- Creates red warning/error icon
	- Plays shake/red flash animation (500ms)
	- Persists until corrected if configured
	- Shows error message
	"""
	if is_showing and persists_until_corrected:
		# Update existing error if already showing
		_update_error_message(message)
		return

	is_showing = true
	error_message = message

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

	# Show error feedback using animation system
	animation_system.show_error_feedback(position, get_parent())

	# Show error message popup if provided
	if not message.is_empty():
		_show_error_message(position, message)

	# Play sound effect
	if sound_effect:
		_play_sound()

	error_shown.emit()

func show_error_at_position(position: Vector2, message: String = "Error occurred") -> void:
	"""
	Show error feedback at specific position
	"""
	if is_showing and persists_until_corrected:
		_update_error_message(message)
		return

	is_showing = true
	error_message = message

	# Show error feedback using animation system
	animation_system.show_error_feedback(position, get_parent())

	# Show error message
	if not message.is_empty():
		_show_error_message(position, message)

	# Play sound effect
	if sound_effect:
		_play_sound()

	error_shown.emit()

func dismiss_error() -> void:
	"""
	Dismiss error feedback:
	- Removes error UI elements
	- Emits error_dismissed signal
	"""
	if not is_showing:
		return

	# Remove all error nodes
	for node in error_nodes:
		if node and is_instance_valid(node):
			node.queue_free()

	error_nodes.clear()
	is_showing = false

	error_dismissed.emit()

func set_error_color(color: Color) -> void:
	"""
	Set error color (default is red)
	"""
	error_color = color

func set_animation_duration(duration: float) -> void:
	"""
	Override default 500ms animation duration
	"""
	animation_duration = duration

func set_persistence(persist: bool) -> void:
	"""
	Set whether error persists until corrected
	"""
	persists_until_corrected = persist

func set_sound_effect(stream: AudioStream) -> void:
	"""
	Set sound effect to play with error
	"""
	sound_effect = stream

func add_error_icon(node: Control) -> void:
	"""
	Add error icon to a specific node (for validation errors)
	"""
	# Create error indicator
	var error_icon = TextureRect.new()
	error_icon.name = "ErrorIcon"
	error_icon.size = Vector2(16, 16)
	error_icon.position = Vector2(node.size.x - 20, 2)
	error_icon.modulate = error_color

	# Try to load error icon
	var icon_path = "res://assets/ui/icons/error.png"
	if ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		if texture:
			error_icon.texture = texture

	node.add_child(error_icon)
	error_nodes.append(error_icon)

# Internal methods

func _update_error_message(new_message: String) -> void:
	"""
	Update existing error message
	"""
	error_message = new_message

	# Find and update message label if exists
	for node in error_nodes:
		if node.name == "ErrorMessageLabel":
			if node is Label:
				node.text = new_message
			break

func _show_error_message(position: Vector2, message: String) -> void:
	"""
	Show error message label
	"""
	var message_label = Label.new()
	message_label.name = "ErrorMessageLabel"
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.modulate = error_color
	message_label.position = position + Vector2(-100, 40)  # Below icon
	message_label.size = Vector2(200, 40)

	get_parent().add_child(message_label)
	error_nodes.append(message_label)

func _play_sound() -> void:
	"""
	Play error sound effect
	"""
	if not sound_effect:
		return

	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sound_effect
	audio_player.volume_db = -5.0  # Error sound slightly louder
	add_child(audio_player)
	audio_player.play()

	# Clean up after playing
	audio_player.finished.connect(func():
		audio_player.queue_free()
	)

# Factory methods

static func create_and_show(
	parent: Node, message: String,
	anchor: Node = null,
	sound: AudioStream = null) -> UIErrorFeedback:
	"""
	Factory method: Create and immediately show error feedback
	"""
	var error_feedback = UIErrorFeedback.new()
	parent.add_child(error_feedback)

	if sound:
		error_feedback.set_sound_effect(sound)

	error_feedback.show_error(anchor, message)

	return error_feedback

static func attach_to_validation(field: Control, message: String, sound: AudioStream = null) -> UIErrorFeedback:
	"""
	Attach error feedback to a form field for validation errors
	"""
	var error_feedback = UIErrorFeedback.new()
	error_feedback.set_sound_effect(sound)
	field.add_child(error_feedback)

	# Set persistence to true for validation errors
	error_feedback.set_persistence(true)

	# Add error icon to field
	error_feedback.add_error_icon(field)

	# Show error
	error_feedback.show_error(field, message)

	return error_feedback

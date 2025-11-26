extends Control
class_name UILoadingIndicator

# UILoadingIndicator - Loading indicator component with spinner animation and progress feedback
# Provides 500ms threshold detection, progress support, and smooth 60fps animations

# Configuration
@export var spinner_size: int = 32  # Size of spinner in pixels
@export var show_progress: bool = false  # Show progress bar
@export var progress_text: String = "Loading..."  # Text to display
@export var threshold_ms: float = 500.0  # Milliseconds before showing indicator
@export var fade_in_duration: float = 0.2  # Fade-in animation duration

# Signals
signal loading_started  # Emitted when loading starts (after threshold)
signal loading_completed  # Emitted when loading completes
signal progress_updated(progress: float, status: String)  # Progress updates

# Internal state
var animation_player: AnimationPlayer = null
var spinner_sprite: TextureRect = null
var progress_bar: ProgressBar = null  # Optional progress bar
var status_label: Label = null
var is_loading: bool = false
var show_timer: Timer = null
var start_time: float = 0.0
var current_progress: float = 0.0

# Performance monitoring
var frame_times: Array = []  # Track frame times during animation
var target_fps: int = 60

func _ready():
	# Create child nodes
	_create_child_nodes()

	# Initialize as hidden
	visible = false
	modulate = Color(1, 1, 1, 0)

	print("UILoadingIndicator ready - threshold: %dms" % threshold_ms)

func _create_child_nodes():
	# Create spinner sprite
	if not has_node("SpinnerSprite"):
		spinner_sprite = TextureRect.new()
		spinner_sprite.name = "SpinnerSprite"
		spinner_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spinner_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spinner_sprite.size = Vector2(spinner_size, spinner_size)
		add_child(spinner_sprite)
	else:
		spinner_sprite = $SpinnerSprite

	# Create AnimationPlayer for spinner rotation
	if not has_node("SpinnerAnimation"):
		animation_player = AnimationPlayer.new()
		animation_player.name = "SpinnerAnimation"
		add_child(animation_player)
		_create_spinner_animation()
	else:
		animation_player = $SpinnerAnimation

	# Create status label
	if not has_node("StatusLabel"):
		status_label = Label.new()
		status_label.name = "StatusLabel"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_label.text = progress_text
		add_child(status_label)
	else:
		status_label = $StatusLabel

	# Position elements
	_position_elements()

	# Create show timer for threshold detection
	if not has_node("ShowTimer"):
		show_timer = Timer.new()
		show_timer.name = "ShowTimer"
		show_timer.one_shot = true
		show_timer.wait_time = threshold_ms / 1000.0
		show_timer.connect("timeout", Callable(self, "_on_show_timer_timeout"))
		add_child(show_timer)
	else:
		show_timer = $ShowTimer
		show_timer.connect("timeout", Callable(self, "_on_show_timer_timeout"))

	# Create progress bar if enabled
	if show_progress and not has_node("ProgressBar"):
		progress_bar = ProgressBar.new()
		progress_bar.name = "ProgressBar"
		progress_bar.min_value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0
		progress_bar.show_percentage = true
		add_child(progress_bar)
		_position_progress_bar()

func _create_spinner_animation():
	# Create smooth 60fps rotation animation
	var anim = Animation.new()
	anim.length = 1.0  # 1 second per rotation
	anim.loop_mode = Animation.LOOP_LINEAR

	# Rotation track
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "SpinnerSprite:rotation")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 1.0, 2 * PI)  # 360 degrees

	# Add animation to the AnimationPlayer using the root library
	if animation_player.has_animation_library(""):
		var library = animation_player.get_animation_library("")
		library.add_animation("spin", anim)
	else:
		# Create root library if it doesn't exist
		var library = AnimationLibrary.new()
		library.add_animation("spin", anim)
		animation_player.add_animation_library("", library)

func _position_elements():
	# Center spinner
	if spinner_sprite:
		spinner_sprite.position = Vector2(
			(size.x - spinner_size) / 2,
			(size.y - spinner_size) / 2 - 20  # Offset up for label
		)

	# Position status label below spinner
	if status_label:
		var label_height = status_label.get_minimum_size().y
		status_label.position = Vector2(
			0,
			(size.y - label_height) / 2 + 20
		)
		status_label.size = Vector2(size.x, label_height)

func _position_progress_bar():
	if progress_bar:
		var bar_height = 20
		progress_bar.position = Vector2(
			(size.x - 200) / 2,  # Center horizontally, 200px width
			size.y - bar_height - 40  # 40px from bottom
		)
		progress_bar.size = Vector2(200, bar_height)

# Public API

func start_loading() -> void:
	"""
	Start loading with threshold detection:
	- Timer starts
	- Indicator shows after threshold_ms
	- Emits loading_started signal
	"""
	if is_loading:
		return

	is_loading = true
	start_time = Time.get_ticks_msec()
	current_progress = 0.0

	# Start threshold timer
	show_timer.start()

	print("Loading started - will show after %dms" % threshold_ms)

func stop_loading() -> void:
	"""
	Stop loading and hide indicator:
	- Stops spinner animation
	- Fades out
	- Emits loading_completed signal
	"""
	if not is_loading:
		return

	is_loading = false

	# Stop timer if still running
	if show_timer and show_timer.is_stopped() == false:
		show_timer.stop()

	# Hide with fade animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, fade_in_duration)
	tween.tween_callback(func(): _hide_complete())

	# Stop spinner
	if animation_player:
		animation_player.stop()

	loading_completed.emit()

	# Log elapsed time
	var elapsed = Time.get_ticks_msec() - start_time
	print("Loading completed - elapsed: %dms" % elapsed)

func update_progress(progress: float, status: String = "") -> void:
	"""
	Update loading progress (0.0 to 1.0):
	- Updates progress bar if enabled
	- Updates status text
	- Ensures smooth transitions
	"""
	current_progress = clamp(progress, 0.0, 1.0)

	# Update progress bar
	if progress_bar:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(progress_bar, "value", current_progress, 0.1)

	# Update status text
	if status_label:
		if not status.is_empty():
			status_label.text = status
		elif progress_text.is_empty() == false:
			status_label.text = "%s %d%%" % [progress_text, int(current_progress * 100)]

	progress_updated.emit(current_progress, status)

func show_immediate() -> void:
	"""
	Show indicator immediately without threshold delay:
	- Useful for operations known to be slow
	"""
	if visible:
		return

	visible = true

	# Fade in animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

	# Start spinner
	if animation_player:
		animation_player.play("spin")

	is_loading = true
	start_time = Time.get_ticks_msec()

# Internal methods

func _on_show_timer_timeout():
	# Threshold reached - show indicator
	show_immediate()
	loading_started.emit()

func _hide_complete():
	# Hide after fade out
	visible = false
	modulate = Color(1, 1, 1, 0)  # Reset for next time

# Performance monitoring

func _process(delta):
	# Monitor frame rate during animations
	if is_loading and visible:
		frame_times.append(delta)

		# Keep only recent frame times (last second)
		if frame_times.size() > 60:
			frame_times.pop_front()

func get_average_fps() -> float:
	"""Get average FPS during loading animation"""
	if frame_times.is_empty():
		return 60.0

	var total_time = 0.0
	for time in frame_times:
		total_time += time

	return frame_times.size() / total_time

func validate_performance() -> bool:
	"""
	Validate performance requirements (AC-UI-010):
	- Minimum 50fps during animations
	- Maintains 60fps target
	"""
	var avg_fps = get_average_fps()
	return avg_fps >= 50.0

# Configuration methods

func set_spinner_size(size_px: int) -> void:
	"""Change spinner size"""
	spinner_size = size_px
	if spinner_sprite:
		spinner_sprite.size = Vector2(size_px, size_px)
	_position_elements()

func set_threshold_ms(ms: float) -> void:
	"""Change show threshold"""
	threshold_ms = ms
	if show_timer:
		show_timer.wait_time = ms / 1000.0

func set_progress_text(text: String) -> void:
	"""Update progress text template"""
	progress_text = text
	if status_label and is_loading == false:
		status_label.text = text

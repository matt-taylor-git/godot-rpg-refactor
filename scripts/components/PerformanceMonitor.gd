extends Node
class_name PerformanceMonitor

# PerformanceMonitor - Tracks animation performance metrics
# AC-2.2.4: Animation Performance
# - Frame rate maintains 60fps
# - Frame drops below 55fps trigger warning (dev mode)
# - Memory usage under 500MB
# - Animations don't delay game logic

signal fps_warning(current_fps: float)
signal memory_warning(current_mb: float)
signal performance_log(entry: Dictionary)

# Configuration
const TARGET_FPS = 60.0
const WARNING_FPS_THRESHOLD = 55.0
const CONSECUTIVE_FRAMES_FOR_WARNING = 3
const MEMORY_WARNING_MB = 500.0
const SAMPLE_INTERVAL = 0.5 # Sample every 500ms for efficiency

# State
var is_monitoring: bool = false
var is_debug_mode: bool = false
var show_overlay: bool = false

# Tracking
var low_fps_consecutive_count: int = 0
var fps_samples: Array[float] = []
var memory_samples: Array[float] = []
var animation_timings: Dictionary = {}
var sample_timer: float = 0.0

# Debug overlay nodes
var overlay_label: Label = null

func _ready() -> void:
	# Check if in debug/development mode
	is_debug_mode = OS.is_debug_build()
	
	# Create debug overlay (hidden by default)
	_create_debug_overlay()

func _create_debug_overlay() -> void:
	overlay_label = Label.new()
	overlay_label.name = "PerformanceOverlay"
	overlay_label.text = "FPS: --\nMem: -- MB"
	overlay_label.position = Vector2(10, 10)
	overlay_label.z_index = 1000 # Always on top
	overlay_label.visible = false
	
	# Style the label
	overlay_label.add_theme_color_override("font_color", Color.WHITE)
	overlay_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	overlay_label.add_theme_constant_override("shadow_offset_x", 1)
	overlay_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Add a background panel
	var panel = Panel.new()
	panel.name = "OverlayBackground"
	panel.custom_minimum_size = Vector2(150, 80)
	panel.modulate = Color(0, 0, 0, 0.7)
	panel.z_index = 999
	panel.visible = false
	
	add_child(panel)
	add_child(overlay_label)

func _input(event: InputEvent) -> void:
	# Toggle debug overlay with F12 (dev mode only)
	if is_debug_mode and event is InputEventKey:
		if event.pressed and event.keycode == KEY_F12:
			toggle_overlay()

func toggle_overlay() -> void:
	show_overlay = !show_overlay
	if overlay_label:
		overlay_label.visible = show_overlay
	var panel = get_node_or_null("OverlayBackground")
	if panel:
		panel.visible = show_overlay

func start_monitoring() -> void:
	is_monitoring = true
	fps_samples.clear()
	memory_samples.clear()
	low_fps_consecutive_count = 0
	sample_timer = 0.0

func stop_monitoring() -> void:
	is_monitoring = false

func _process(delta: float) -> void:
	if not is_monitoring:
		return
	
	# Always track FPS for warning system
	var current_fps = Engine.get_frames_per_second()
	
	# Check for frame drops - AC-2.2.4
	if current_fps < WARNING_FPS_THRESHOLD:
		low_fps_consecutive_count += 1
		if low_fps_consecutive_count >= CONSECUTIVE_FRAMES_FOR_WARNING:
			_trigger_fps_warning(current_fps)
	else:
		low_fps_consecutive_count = 0
	
	# Sample at interval for efficiency
	sample_timer += delta
	if sample_timer >= SAMPLE_INTERVAL:
		sample_timer = 0.0
		_take_sample(current_fps)
	
	# Update overlay if visible
	if show_overlay and overlay_label:
		_update_overlay(current_fps)

func _take_sample(current_fps: float) -> void:
	fps_samples.append(current_fps)
	
	# Get memory usage
	var memory_mb = _get_memory_usage_mb()
	memory_samples.append(memory_mb)
	
	# Check memory warning
	if memory_mb > MEMORY_WARNING_MB:
		_trigger_memory_warning(memory_mb)
	
	# Keep sample arrays bounded
	const MAX_SAMPLES = 120 # ~60 seconds at 0.5s interval
	if fps_samples.size() > MAX_SAMPLES:
		fps_samples.pop_front()
	if memory_samples.size() > MAX_SAMPLES:
		memory_samples.pop_front()

func _get_memory_usage_mb() -> float:
	# Get memory usage from Performance singleton
	var memory_bytes = Performance.get_monitor(Performance.MEMORY_STATIC)
	return memory_bytes / (1024.0 * 1024.0)

func _trigger_fps_warning(fps: float) -> void:
	if is_debug_mode:
		push_warning("Performance Warning: FPS dropped to %.1f (threshold: %.1f)" % [fps, WARNING_FPS_THRESHOLD])
	emit_signal("fps_warning", fps)
	
	# Log the event
	var log_entry = {
		"type": "fps_warning",
		"fps": fps,
		"timestamp": Time.get_unix_time_from_system(),
		"active_animations": animation_timings.keys()
	}
	emit_signal("performance_log", log_entry)

func _trigger_memory_warning(memory_mb: float) -> void:
	if is_debug_mode:
		push_warning("Performance Warning: Memory usage at %.1f MB (threshold: %.1f MB)" % [memory_mb, MEMORY_WARNING_MB])
	emit_signal("memory_warning", memory_mb)
	
	var log_entry = {
		"type": "memory_warning",
		"memory_mb": memory_mb,
		"timestamp": Time.get_unix_time_from_system()
	}
	emit_signal("performance_log", log_entry)

func _update_overlay(fps: float) -> void:
	var memory_mb = _get_memory_usage_mb()
	var fps_color = "green" if fps >= TARGET_FPS else ("yellow" if fps >= WARNING_FPS_THRESHOLD else "red")
	var mem_color = "green" if memory_mb < MEMORY_WARNING_MB * 0.8 else ("yellow" if memory_mb < MEMORY_WARNING_MB else "red")
	
	overlay_label.text = "FPS: %.0f [color=%s]●[/color]\nMem: %.1f MB [color=%s]●[/color]\nAnims: %d" % [
		fps, fps_color, memory_mb, mem_color, animation_timings.size()
	]

# Animation timing tracking
func start_animation_timing(animation_id: String) -> void:
	animation_timings[animation_id] = Time.get_ticks_msec()

func end_animation_timing(animation_id: String) -> void:
	if animation_id in animation_timings:
		var start_time = animation_timings[animation_id]
		var end_time = Time.get_ticks_msec()
		var duration_ms = end_time - start_time
		animation_timings.erase(animation_id)
		
		# Log animation completion
		var log_entry = {
			"type": "animation_completed",
			"animation_id": animation_id,
			"duration_ms": duration_ms,
			"timestamp": Time.get_unix_time_from_system()
		}
		emit_signal("performance_log", log_entry)
		
		# Warn if animation took too long (blocking potential)
		if duration_ms > 600: # > 600ms is suspicious
			if is_debug_mode:
				push_warning("Animation '%s' took %d ms (may be blocking)" % [animation_id, duration_ms])

# Get current performance stats
func get_stats() -> Dictionary:
	var avg_fps = 0.0
	if fps_samples.size() > 0:
		for fps in fps_samples:
			avg_fps += fps
		avg_fps /= fps_samples.size()
	
	var avg_memory = 0.0
	if memory_samples.size() > 0:
		for mem in memory_samples:
			avg_memory += mem
		avg_memory /= memory_samples.size()
	
	return {
		"current_fps": Engine.get_frames_per_second(),
		"average_fps": avg_fps,
		"min_fps": fps_samples.min() if fps_samples.size() > 0 else 0.0,
		"current_memory_mb": _get_memory_usage_mb(),
		"average_memory_mb": avg_memory,
		"peak_memory_mb": memory_samples.max() if memory_samples.size() > 0 else 0.0,
		"active_animations": animation_timings.size(),
		"fps_warnings": low_fps_consecutive_count
	}

# Check if performance is acceptable
func is_performance_acceptable() -> bool:
	var stats = get_stats()
	return stats.current_fps >= WARNING_FPS_THRESHOLD and stats.current_memory_mb < MEMORY_WARNING_MB

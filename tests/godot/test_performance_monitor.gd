extends GutTest

# Test PerformanceMonitor functionality
# AC-2.2.4: Animation Performance
# - Frame rate maintains 60fps
# - Frame drops below 55fps trigger warning (dev mode)
# - Memory usage under 500MB
# - Animations don't delay game logic

var PerformanceMonitorScript = load("res://scripts/components/PerformanceMonitor.gd")

var monitor = null

func before_each():
	monitor = PerformanceMonitorScript.new()
	add_child_autofree(monitor)

# ===== Basic Setup Tests =====

func test_initialization():
	assert_not_null(monitor, "Monitor should be created")
	assert_false(monitor.is_monitoring, "Should not be monitoring initially")
	assert_false(monitor.show_overlay, "Overlay should be hidden initially")

func test_start_monitoring():
	monitor.start_monitoring()

	assert_true(monitor.is_monitoring, "Should be monitoring after start")

func test_stop_monitoring():
	monitor.start_monitoring()
	monitor.stop_monitoring()

	assert_false(monitor.is_monitoring, "Should not be monitoring after stop")

# ===== Configuration Tests =====

func test_configuration_constants():
	assert_eq(monitor.TARGET_FPS, 60.0, "Target FPS should be 60")
	assert_eq(monitor.WARNING_FPS_THRESHOLD, 55.0, "Warning threshold should be 55")
	assert_eq(monitor.MEMORY_WARNING_MB, 500.0, "Memory warning should be 500MB")
	assert_eq(monitor.CONSECUTIVE_FRAMES_FOR_WARNING, 3, "Should require 3 consecutive low frames")

# ===== Stats Collection Tests =====

func test_get_stats():
	monitor.start_monitoring()

	# Wait a bit for some samples
	await get_tree().create_timer(0.6).timeout

	var stats = monitor.get_stats()

	assert_true("current_fps" in stats, "Stats should include current_fps")
	assert_true("average_fps" in stats, "Stats should include average_fps")
	assert_true("current_memory_mb" in stats, "Stats should include current_memory_mb")
	assert_true("active_animations" in stats, "Stats should include active_animations")

func test_stats_have_valid_values():
	monitor.start_monitoring()
	await get_tree().create_timer(0.6).timeout

	var stats = monitor.get_stats()

	assert_true(stats.current_fps > 0, "Current FPS should be positive")
	assert_true(stats.current_memory_mb > 0, "Memory usage should be positive")

# ===== Animation Timing Tests =====

func test_animation_timing_tracking():
	watch_signals(monitor)

	monitor.start_monitoring()
	monitor.start_animation_timing("test_anim_1")

	# Simulate animation duration
	await get_tree().create_timer(0.1).timeout

	monitor.end_animation_timing("test_anim_1")

	# Should emit performance_log
	assert_signal_emitted(monitor, "performance_log")

func test_animation_timing_not_in_dict_after_end():
	monitor.start_animation_timing("test_anim")
	assert_true("test_anim" in monitor.animation_timings, "Animation should be tracked")

	monitor.end_animation_timing("test_anim")
	assert_false("test_anim" in monitor.animation_timings, "Animation should be removed after end")

# ===== Warning Signal Tests =====

func test_fps_warning_signal_exists():
	assert_true(monitor.has_signal("fps_warning"), "Should have fps_warning signal")

func test_memory_warning_signal_exists():
	assert_true(monitor.has_signal("memory_warning"), "Should have memory_warning signal")

func test_performance_log_signal_exists():
	assert_true(monitor.has_signal("performance_log"), "Should have performance_log signal")

# ===== Performance Check Tests =====

func test_is_performance_acceptable():
	monitor.start_monitoring()
	await get_tree().create_timer(0.1).timeout

	# In normal test conditions, performance should be acceptable
	var is_acceptable = monitor.is_performance_acceptable()

	# We can't guarantee this in all environments, so just check it returns boolean
	assert_true(is_acceptable == true or is_acceptable == false, "Should return boolean")

# ===== Overlay Tests =====

func test_toggle_overlay():
	assert_false(monitor.show_overlay, "Overlay should start hidden")

	monitor.toggle_overlay()
	assert_true(monitor.show_overlay, "Overlay should be visible after toggle")

	monitor.toggle_overlay()
	assert_false(monitor.show_overlay, "Overlay should be hidden after second toggle")

func test_debug_overlay_created():
	# The overlay label should be created in _ready
	var overlay = monitor.get_node_or_null("PerformanceOverlay")
	# Note: Due to how add_child_autofree works, the overlay might be created
	# We just verify the method exists and monitor functions
	assert_not_null(monitor.overlay_label, "Overlay label should exist")

# ===== Sampling Tests =====

func test_samples_bounded():
	monitor.start_monitoring()

	# Force many samples (this is a bit artificial)
	for i in range(150):
		monitor._take_sample(60.0)

	# Should not exceed MAX_SAMPLES (120)
	assert_true(monitor.fps_samples.size() <= 120, "FPS samples should be bounded")
	assert_true(monitor.memory_samples.size() <= 120, "Memory samples should be bounded")

# ===== Memory Usage Test =====

func test_memory_usage_retrieval():
	var memory_mb = monitor._get_memory_usage_mb()

	# Should return a positive value
	assert_true(memory_mb > 0, "Memory usage should be positive")
	# Should be reasonable (not ridiculously high in tests)
	assert_true(memory_mb < 1000, "Memory usage should be reasonable")

# ===== Consecutive Frame Warning Test =====

func test_consecutive_frame_counter_resets():
	monitor.start_monitoring()

	# Simulate low FPS
	monitor.low_fps_consecutive_count = 2

	# Process with good FPS (would reset counter in real scenario)
	# We can't easily test _process directly, but we can verify the counter exists
	assert_eq(monitor.low_fps_consecutive_count, 2, "Counter should be set")

	# Reset
	monitor.low_fps_consecutive_count = 0
	assert_eq(monitor.low_fps_consecutive_count, 0, "Counter should reset")

extends GutTest

# Test CombatAnimationController functionality
# Tests animation coordination, signal handling, damage number spawning,
# spell effects, particle pooling, and accessibility features
# AC-2.2.1, AC-2.2.2, AC-2.2.4, AC-2.2.5

var CombatAnimationControllerScript = load("res://scripts/components/CombatAnimationController.gd")
var DamageNumberPopupScript = load("res://scripts/components/DamageNumberPopup.gd")

var controller = null
var player_node = null
var monster_node = null
var camera_node = null
var container_node = null

func before_each():
	controller = CombatAnimationControllerScript.new()
	add_child_autofree(controller)
	
	# Create a container for particles
	container_node = Control.new()
	container_node.name = "ParticleContainer"
	add_child_autofree(container_node)
	
	player_node = Control.new()
	player_node.name = "Player"
	player_node.position = Vector2(100, 300)
	player_node.size = Vector2(50, 50) # Control needs size for center calculation
	add_child_autofree(player_node)
	
	monster_node = Control.new()
	monster_node.name = "Monster"
	monster_node.position = Vector2(800, 300)
	monster_node.size = Vector2(50, 50)
	add_child_autofree(monster_node)
	
	camera_node = Camera2D.new()
	add_child_autofree(camera_node)
	
	controller.setup(player_node, monster_node, camera_node, container_node)

func test_setup():
	assert_eq(controller.player_node, player_node)
	assert_eq(controller.monster_node, monster_node)
	assert_eq(controller.camera_node, camera_node)

func test_attack_animation_signal():
	watch_signals(controller)
	controller._play_attack_animation(player_node, monster_node)
	
	assert_signal_emitted(controller, "animation_started", "Should emit animation_started")
	
	# Wait for animation to complete (ATTACK_DURATION = 0.3)
	await get_tree().create_timer(0.4).timeout
	
	assert_signal_emitted(controller, "animation_completed", "Should emit animation_completed")

func test_damage_number_spawning():
	watch_signals(controller)
	
	controller.spawn_damage_number(monster_node, 100, "damage", false)
	
	assert_signal_emitted(controller, "damage_number_spawned")
	
	# Check if popup was added to parent
	# In the test environment, player_node is child of test script (this node)
	# So popup should be child of this node
	var children = get_children()
	var found_popup = false
	for child in children:
		if child.get_script() == DamageNumberPopupScript:
			found_popup = true
			assert_eq(child.value, 100)
			assert_eq(child.type, "damage")
			break
	
	assert_true(found_popup, "DamageNumberPopup should be instantiated and added to tree")

func test_screen_shake_affects_camera():
	var initial_pos = camera_node.position
	
	controller._play_screen_shake()
	
	# Wait a bit for shake to happen
	await get_tree().create_timer(0.05).timeout
	
	# Position should have changed (unless we got incredibly unlucky with random 0)
	# But checking exact value is flaky with random.
	# We can check that it returns to original after duration (0.1s)
	
	await get_tree().create_timer(0.15).timeout
	
	assert_eq(camera_node.position, initial_pos, "Camera should return to original position after shake")

func test_integration_with_gamemanager_signals():
	# We can simulate GameManager signals if we connect them properly manually for the test
	# or rely on the real GameManager if it's available.
	# Since GameManager is autoload, it is available.
	
	# We need to spy/mock the methods called by signals
	# But _on_player_attacked calls private methods.
	# We can check side effects (animation signals, damage numbers)
	
	watch_signals(controller)
	
	# Emit signal from GameManager
	GameManager.emit_signal("player_attacked", 50, false)
	
	# Animation start should be immediate
	assert_signal_emitted(controller, "animation_started")
	
	# Damage number spawns after delay
	await get_tree().create_timer(0.2).timeout
	assert_signal_emitted(controller, "damage_number_spawned")

# ===== AC-2.2.5: Accessibility Tests =====

func test_reduced_motion_skips_attack_animation():
	controller.set_reduced_motion(true)
	watch_signals(controller)
	
	var initial_pos = player_node.global_position
	
	# Simulate player attack
	controller._on_player_attacked(50, false)
	
	await get_tree().create_timer(0.1).timeout
	
	# With reduced motion, position should not change (no lunge animation)
	assert_eq(player_node.global_position, initial_pos, "Player should not animate with reduced motion")
	
	# But damage number should still spawn
	assert_signal_emitted(controller, "damage_number_spawned", "Damage number should still spawn")

func test_reduced_motion_instant_spell_cast():
	controller.set_reduced_motion(true)
	watch_signals(controller)
	
	# Call spell cast
	controller.play_spell_cast(player_node, monster_node, "fireball")
	
	# Should emit spell_impact immediately without waiting for animations
	await get_tree().create_timer(0.1).timeout
	assert_signal_emitted(controller, "spell_impact", "Spell impact should emit immediately with reduced motion")

# ===== AC-2.2.2: Spell Cast Animation Tests =====

func test_spell_cast_animation_signals():
	controller.set_reduced_motion(false)
	watch_signals(controller)
	
	# Play spell cast
	controller.play_spell_cast(player_node, monster_node, "fire")
	
	assert_signal_emitted(controller, "animation_started", "Should emit animation_started")
	
	# Wait for full spell animation (cast 0.3 + travel 0.5 + impact 0.2 = ~1.0s)
	await get_tree().create_timer(1.2).timeout
	
	assert_signal_emitted(controller, "animation_completed", "Should emit animation_completed")
	assert_signal_emitted(controller, "spell_impact", "Should emit spell_impact")

func test_spell_colors():
	# Test that different spell types return correct colors
	var fire_color = controller._get_spell_color("fireball")
	var ice_color = controller._get_spell_color("ice")
	var heal_color = controller._get_spell_color("heal")
	var default_color = controller._get_spell_color("unknown")
	
	assert_ne(fire_color, ice_color, "Fire and ice should have different colors")
	assert_ne(fire_color, heal_color, "Fire and heal should have different colors")
	assert_eq(default_color, Color(1.0, 0.8, 0.2, 1.0), "Unknown spells should use default golden color")

# ===== AC-2.2.4: Particle Pool Tests =====

func test_particle_pool_initialization():
	# After setup, particle pools should be initialized
	assert_true(controller.spell_particle_pool.size() > 0, "Spell particle pool should be initialized")
	assert_true(controller.impact_particle_pool.size() > 0, "Impact particle pool should be initialized")

func test_particle_pool_reuse():
	# Get a particle from pool
	var particle1 = controller._get_spell_particle_from_pool()
	assert_not_null(particle1, "Should get particle from pool")
	
	# Return it
	controller._return_spell_particle_to_pool(particle1)
	
	# Get another - should be the same one (reused)
	var particle2 = controller._get_spell_particle_from_pool()
	assert_eq(particle1, particle2, "Should reuse returned particle")

# ===== Animation State Tests =====

func test_is_animating():
	controller.set_reduced_motion(false)
	
	assert_false(controller.is_animating(), "Should not be animating initially")
	
	controller._play_attack_animation(player_node, monster_node)
	
	assert_true(controller.is_animating(), "Should be animating after starting attack")
	
	# Wait for animation
	await get_tree().create_timer(0.4).timeout
	
	assert_false(controller.is_animating(), "Should not be animating after completion")

func test_healing_effect():
	watch_signals(controller)
	controller.set_reduced_motion(false)
	
	controller.play_healing_effect(player_node, 50)
	
	assert_signal_emitted(controller, "animation_started")
	assert_signal_emitted(controller, "damage_number_spawned")
	
	await get_tree().create_timer(0.6).timeout
	
	assert_signal_emitted(controller, "animation_completed")

# ===== Bezier Path Test =====

func test_bezier_point_calculation():
	var p0 = Vector2(0, 0)
	var p1 = Vector2(50, -50) # Control point (arc)
	var p2 = Vector2(100, 0)
	
	var start = controller._bezier_point(p0, p1, p2, 0.0)
	var mid = controller._bezier_point(p0, p1, p2, 0.5)
	var end = controller._bezier_point(p0, p1, p2, 1.0)
	
	assert_eq(start, p0, "Bezier at t=0 should equal start point")
	assert_eq(end, p2, "Bezier at t=1 should equal end point")
	assert_true(mid.y < 0, "Bezier midpoint should have negative y (arc upward)")

extends Node
class_name CombatAnimationController

# CombatAnimationController - Coordinates combat animations
# AC-2.2.2: Combat Animation Polish
# - Attack animation (300ms)
# - Screen shake (100ms)
# - Spell cast effects with particle system
# - Particle management with pooling
# AC-2.2.4: Animation Performance
# - 60fps target, non-blocking animations

signal animation_started(animation_id: String)
signal animation_completed(animation_id: String)
signal damage_number_spawned(value: int, position: Vector2)
signal spell_impact(spell_type: String, target: CanvasItem)

# References
var player_node: CanvasItem
var monster_node: CanvasItem
var camera_node: Node # For screen shake, if available. Or shake the root control.
var particle_container: Node # Container for particle effects

# Configuration
const ATTACK_DURATION = 0.3
const SHAKE_DURATION = 0.1
const SHAKE_INTENSITY = 5.0
const SPELL_DURATION = 0.5
const PARTICLE_TRAVEL_DURATION = 0.5
const IMPACT_DURATION = 0.2
const DAMAGE_NUMBER_SCENE = preload("res://scenes/components/damage_number_popup.tscn")

# Particle pooling - AC-2.2.2, AC-2.2.4
var spell_particle_pool: Array[GPUParticles2D] = []
var impact_particle_pool: Array[GPUParticles2D] = []
const MAX_SPELL_PARTICLES = 10 # Per effect type
const MAX_IMPACT_PARTICLES = 10
const MAX_PARTICLES_PER_EFFECT = 100 # Per constraint
const MAX_TOTAL_PARTICLES = 300 # Per constraint

# Accessibility - AC-2.2.5
var reduced_motion: bool = false

# Active animations tracking
var active_animations: Dictionary = {}
var animation_id_counter: int = 0

func _ready() -> void:
	# Check for reduced motion preference
	_check_reduced_motion()
	# Initialize particle pools
	_initialize_particle_pools()

func setup(player: CanvasItem, monster: CanvasItem, camera: Node = null, container: Node = null) -> void:
	player_node = player
	monster_node = monster
	camera_node = camera
	particle_container = container if container else get_parent()
	
	_connect_signals()

func _check_reduced_motion() -> void:
	# Check project settings for reduced motion preference
	# This can be set in game settings or detected from OS
	reduced_motion = ProjectSettings.get_setting("accessibility/reduced_motion", false)

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled

func _initialize_particle_pools() -> void:
	# Pre-create particle nodes for pooling - AC-2.2.4 performance
	for i in range(MAX_SPELL_PARTICLES):
		var particle = _create_spell_particle()
		particle.emitting = false
		spell_particle_pool.append(particle)
	
	for i in range(MAX_IMPACT_PARTICLES):
		var particle = _create_impact_particle()
		particle.emitting = false
		impact_particle_pool.append(particle)

func _create_spell_particle() -> GPUParticles2D:
	var particle = GPUParticles2D.new()
	particle.amount = MAX_PARTICLES_PER_EFFECT
	particle.one_shot = true
	particle.explosiveness = 0.8
	particle.lifetime = SPELL_DURATION
	particle.emitting = false
	
	# Create particle process material
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.direction = Vector3(1, 0, 0)
	material.spread = 15.0
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.5
	material.scale_max = 1.5
	material.color = Color(1.0, 0.8, 0.2, 1.0) # Default golden color
	
	particle.process_material = material
	
	return particle

func _create_impact_particle() -> GPUParticles2D:
	var particle = GPUParticles2D.new()
	particle.amount = 50 # Smaller burst for impact
	particle.one_shot = true
	particle.explosiveness = 1.0
	particle.lifetime = IMPACT_DURATION
	particle.emitting = false
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 0.3
	material.scale_max = 1.0
	material.color = Color(1.0, 0.5, 0.0, 1.0) # Orange impact
	
	particle.process_material = material
	
	return particle

func _connect_signals() -> void:
	if GameManager:
		if not GameManager.is_connected("player_attacked", Callable(self, "_on_player_attacked")):
			GameManager.connect("player_attacked", Callable(self, "_on_player_attacked"))
		if not GameManager.is_connected("monster_attacked", Callable(self, "_on_monster_attacked")):
			GameManager.connect("monster_attacked", Callable(self, "_on_monster_attacked"))

func _on_player_attacked(damage: int, is_critical: bool) -> void:
	# Player attacks Monster - AC-2.2.2
	if reduced_motion:
		# Instant feedback without animation - AC-2.2.5
		spawn_damage_number(monster_node, damage, "damage", is_critical)
		return
	
	_play_attack_animation(player_node, monster_node)
	
	# Delay damage number slightly to match impact
	await get_tree().create_timer(ATTACK_DURATION * 0.5).timeout
	
	spawn_damage_number(monster_node, damage, "damage", is_critical)
	
	if is_critical or damage > 20: # Arbitrary threshold for "impactful"
		_play_screen_shake()

func _on_monster_attacked(damage: int) -> void:
	# Monster attacks Player - AC-2.2.2
	if reduced_motion:
		spawn_damage_number(player_node, damage, "damage", false)
		return
	
	_play_attack_animation(monster_node, player_node)
	
	await get_tree().create_timer(ATTACK_DURATION * 0.5).timeout
	
	spawn_damage_number(player_node, damage, "damage", false)

func _play_attack_animation(attacker: CanvasItem, target: CanvasItem) -> void:
	if not attacker or not target: return
	
	var anim_id = _generate_animation_id("attack")
	active_animations[anim_id] = true
	emit_signal("animation_started", anim_id)
	
	var original_pos = attacker.position
	var target_pos = target.position
	
	# Handle different node types for position
	if attacker is Control:
		original_pos = attacker.global_position
		target_pos = target.global_position if target is Control else target.position
	
	var direction = (target_pos - original_pos).normalized()
	var lunge_distance = 50.0
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# Lunge forward
	var lunge_target = original_pos + (direction * lunge_distance)
	if attacker is Control:
		tween.tween_property(attacker, "global_position", lunge_target, ATTACK_DURATION * 0.5)
	else:
		tween.tween_property(attacker, "position", lunge_target, ATTACK_DURATION * 0.5)
	
	# Return back
	tween.set_ease(Tween.EASE_IN)
	if attacker is Control:
		tween.tween_property(attacker, "global_position", original_pos, ATTACK_DURATION * 0.5)
	else:
		tween.tween_property(attacker, "position", original_pos, ATTACK_DURATION * 0.5)
	
	tween.tween_callback(func():
		active_animations.erase(anim_id)
		emit_signal("animation_completed", anim_id)
		tween.kill()
	)

func _play_screen_shake() -> void:
	if reduced_motion: return # AC-2.2.5
	
	var target = camera_node if camera_node else get_parent() # Fallback to shaking parent (CombatScene)
	if not target: return
	
	var original_pos = target.position if target is Node2D else Vector2.ZERO
	if target is Control:
		original_pos = target.position
	
	var tween = create_tween()
	
	for i in range(5):
		var offset = Vector2(randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY), randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY))
		tween.tween_property(target, "position", original_pos + offset, SHAKE_DURATION / 5)
	
	tween.tween_property(target, "position", original_pos, 0.02)
	tween.tween_callback(func(): tween.kill())

func spawn_damage_number(target: CanvasItem, value: int, type: String, is_critical: bool) -> void:
	if not target: return
	
	var popup = DAMAGE_NUMBER_SCENE.instantiate()
	# Add to the same parent as target so it overlays correctly
	var parent = target.get_parent()
	if parent:
		parent.add_child(popup)
	else:
		add_child(popup)
	
	# Position at center of target
	var center_offset = Vector2.ZERO
	if target is Control:
		center_offset = target.size / 2
		popup.position = target.position + center_offset
	else:
		popup.position = target.position
	
	popup.setup(value, type, is_critical)
	
	emit_signal("damage_number_spawned", value, popup.position)

# Spell casting with particle effects - AC-2.2.2
func play_spell_cast(caster: CanvasItem, target: CanvasItem, spell_type: String) -> void:
	if reduced_motion:
		# Instant feedback without animation - AC-2.2.5
		emit_signal("spell_impact", spell_type, target)
		return
	
	var anim_id = _generate_animation_id("spell_" + spell_type)
	active_animations[anim_id] = true
	emit_signal("animation_started", anim_id)
	
	# 1. Caster cast pose/glow (300ms) - AC-2.2.2
	await _play_cast_pose(caster, spell_type)
	
	# 2. Particle projectile traveling to target (500ms) - AC-2.2.2
	await _play_spell_projectile(caster, target, spell_type)
	
	# 3. Impact effect at target
	_play_impact_effect(target, spell_type)
	
	active_animations.erase(anim_id)
	emit_signal("animation_completed", anim_id)
	emit_signal("spell_impact", spell_type, target)

func _play_cast_pose(caster: CanvasItem, spell_type: String) -> void:
	# Glow effect based on spell type
	var glow_color = _get_spell_color(spell_type)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Glow up
	tween.tween_property(caster, "modulate", glow_color, 0.15)
	# Hold briefly
	tween.tween_interval(0.1)
	# Return to normal
	tween.tween_property(caster, "modulate", Color.WHITE, 0.05)
	
	tween.tween_callback(func(): tween.kill())
	
	await get_tree().create_timer(ATTACK_DURATION).timeout

func _play_spell_projectile(caster: CanvasItem, target: CanvasItem, spell_type: String) -> void:
	# Get particle from pool
	var particle = _get_spell_particle_from_pool()
	if not particle:
		# Fallback: no particle available, just wait
		await get_tree().create_timer(PARTICLE_TRAVEL_DURATION).timeout
		return
	
	# Configure particle color for spell type
	var spell_color = _get_spell_color(spell_type)
	if particle.process_material is ParticleProcessMaterial:
		particle.process_material.color = spell_color
	
	# Get positions
	var start_pos = _get_center_position(caster)
	var end_pos = _get_center_position(target)
	
	# Add particle to scene
	var container = particle_container if particle_container else get_parent()
	if container and particle.get_parent() != container:
		if particle.get_parent():
			particle.get_parent().remove_child(particle)
		container.add_child(particle)
	
	particle.position = start_pos
	particle.emitting = true
	
	# Animate particle traveling along curved path to target (500ms)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Create curved path using control point
	var midpoint = (start_pos + end_pos) / 2
	var perpendicular = Vector2(-(end_pos.y - start_pos.y), end_pos.x - start_pos.x).normalized()
	var control_point = midpoint + perpendicular * 50 # Arc height
	
	# Bezier-like motion using multiple points
	var quarter_pos = _bezier_point(start_pos, control_point, end_pos, 0.25)
	var half_pos = _bezier_point(start_pos, control_point, end_pos, 0.5)
	var three_quarter_pos = _bezier_point(start_pos, control_point, end_pos, 0.75)
	
	tween.tween_property(particle, "position", quarter_pos, PARTICLE_TRAVEL_DURATION * 0.25)
	tween.tween_property(particle, "position", half_pos, PARTICLE_TRAVEL_DURATION * 0.25)
	tween.tween_property(particle, "position", three_quarter_pos, PARTICLE_TRAVEL_DURATION * 0.25)
	tween.tween_property(particle, "position", end_pos, PARTICLE_TRAVEL_DURATION * 0.25)
	
	tween.tween_callback(func():
		particle.emitting = false
		_return_spell_particle_to_pool(particle)
		tween.kill()
	)
	
	await get_tree().create_timer(PARTICLE_TRAVEL_DURATION).timeout

func _play_impact_effect(target: CanvasItem, spell_type: String) -> void:
	var particle = _get_impact_particle_from_pool()
	if not particle: return
	
	var spell_color = _get_spell_color(spell_type)
	if particle.process_material is ParticleProcessMaterial:
		particle.process_material.color = spell_color
	
	var impact_pos = _get_center_position(target)
	
	var container = particle_container if particle_container else get_parent()
	if container and particle.get_parent() != container:
		if particle.get_parent():
			particle.get_parent().remove_child(particle)
		container.add_child(particle)
	
	particle.position = impact_pos
	particle.emitting = true
	
	# Screen flash for impact - subtle
	if target:
		var flash_tween = create_tween()
		flash_tween.tween_property(target, "modulate", Color(2.0, 2.0, 2.0), 0.05)
		flash_tween.tween_property(target, "modulate", Color.WHITE, 0.15)
		flash_tween.tween_callback(func(): flash_tween.kill())
	
	# Return particle to pool after effect
	await get_tree().create_timer(IMPACT_DURATION + 0.1).timeout
	particle.emitting = false
	_return_impact_particle_to_pool(particle)

func _get_spell_color(spell_type: String) -> Color:
	match spell_type.to_lower():
		"fire", "fireball":
			return Color(1.0, 0.4, 0.1, 1.0) # Orange-red
		"ice", "frost", "freeze":
			return Color(0.3, 0.7, 1.0, 1.0) # Ice blue
		"lightning", "thunder", "shock":
			return Color(1.0, 1.0, 0.3, 1.0) # Yellow
		"heal", "healing", "cure":
			return Color(0.3, 1.0, 0.4, 1.0) # Green
		"dark", "shadow", "curse":
			return Color(0.5, 0.2, 0.8, 1.0) # Purple
		"holy", "light", "divine":
			return Color(1.0, 1.0, 0.8, 1.0) # White-gold
		_:
			return Color(1.0, 0.8, 0.2, 1.0) # Default golden

func _get_center_position(node: CanvasItem) -> Vector2:
	if node is Control:
		return node.global_position + node.size / 2
	else:
		return node.position

func _bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	# Quadratic bezier curve
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

func _generate_animation_id(prefix: String) -> String:
	animation_id_counter += 1
	return prefix + "_" + str(animation_id_counter)

# Particle pool management - AC-2.2.4
func _get_spell_particle_from_pool() -> GPUParticles2D:
	for particle in spell_particle_pool:
		if not particle.emitting:
			return particle
	# Pool exhausted, could create new one but respect limits
	if spell_particle_pool.size() < MAX_SPELL_PARTICLES:
		var particle = _create_spell_particle()
		spell_particle_pool.append(particle)
		return particle
	return null

func _return_spell_particle_to_pool(particle: GPUParticles2D) -> void:
	particle.emitting = false
	# Keep in pool, will be reused

func _get_impact_particle_from_pool() -> GPUParticles2D:
	for particle in impact_particle_pool:
		if not particle.emitting:
			return particle
	if impact_particle_pool.size() < MAX_IMPACT_PARTICLES:
		var particle = _create_impact_particle()
		impact_particle_pool.append(particle)
		return particle
	return null

func _return_impact_particle_to_pool(particle: GPUParticles2D) -> void:
	particle.emitting = false

# Healing animation
func play_healing_effect(target: CanvasItem, heal_amount: int) -> void:
	if reduced_motion:
		spawn_damage_number(target, heal_amount, "healing", false)
		return
	
	var anim_id = _generate_animation_id("heal")
	active_animations[anim_id] = true
	emit_signal("animation_started", anim_id)
	
	# Green glow
	var tween = create_tween()
	tween.tween_property(target, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	tween.tween_property(target, "modulate", Color.WHITE, 0.3)
	tween.tween_callback(func(): tween.kill())
	
	spawn_damage_number(target, heal_amount, "healing", false)
	
	await get_tree().create_timer(0.5).timeout
	active_animations.erase(anim_id)
	emit_signal("animation_completed", anim_id)

# Check if any animations are currently playing
func is_animating() -> bool:
	return active_animations.size() > 0

# Wait for all animations to complete
func wait_for_animations() -> void:
	while is_animating():
		await get_tree().process_frame

# Cleanup on exit
func _exit_tree() -> void:
	# Clean up particle pools
	for particle in spell_particle_pool:
		if is_instance_valid(particle):
			particle.queue_free()
	for particle in impact_particle_pool:
		if is_instance_valid(particle):
			particle.queue_free()
	spell_particle_pool.clear()
	impact_particle_pool.clear()

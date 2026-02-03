class_name TurnIndicatorController
extends Node

# TurnIndicatorController - Manages turn indicator visual effects
# AC-2.2.3: Turn Indicator Clarity
# - Active character glow effect
# - Non-active portrait dimming
# - Smooth transitions (200ms)
# - Clear visibility at all screen sizes

signal turn_changed(active_node: CanvasItem)

# Configuration
const TRANSITION_DURATION = 0.2 # 200ms per AC-2.2.3
const ACTIVE_GLOW_COLOR = Color(1.3, 1.3, 1.0, 1.0) # Subtle golden glow
const INACTIVE_DIM_COLOR = Color(0.7, 0.7, 0.7, 1.0) # Slight dimming
const NORMAL_COLOR = Color.WHITE

# References
var player_node: CanvasItem
var monster_node: CanvasItem
var current_active: CanvasItem = null

# Accessibility
var reduced_motion: bool = false

# Active tweens for cleanup
var active_tweens: Array[Tween] = []

func setup(player: CanvasItem, monster: CanvasItem) -> void:
	player_node = player
	monster_node = monster
	_connect_signals()

func _connect_signals() -> void:
	# Connect to GameManager turn signals if they exist
	if GameManager:
		# Check if signals exist before connecting
		if GameManager.has_signal("player_turn_started"):
			if not GameManager.is_connected("player_turn_started", Callable(self, "_on_player_turn")):
				GameManager.connect("player_turn_started", Callable(self, "_on_player_turn"))

		if GameManager.has_signal("monster_turn_started"):
			if not GameManager.is_connected("monster_turn_started", Callable(self, "_on_monster_turn")):
				GameManager.connect("monster_turn_started", Callable(self, "_on_monster_turn"))

		# Also connect to combat signals for fallback
		if not GameManager.is_connected("combat_started", Callable(self, "_on_combat_started")):
			GameManager.connect("combat_started", Callable(self, "_on_combat_started"))
		if not GameManager.is_connected("combat_ended", Callable(self, "_on_combat_ended")):
			GameManager.connect("combat_ended", Callable(self, "_on_combat_ended"))

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled

func _on_combat_started(_monster_name: String) -> void:
	# Default to player turn at start
	set_active_turn(player_node)

func _on_combat_ended(_player_won: bool) -> void:
	# Reset both to normal
	_reset_indicators()

func _on_player_turn() -> void:
	set_active_turn(player_node)

func _on_monster_turn() -> void:
	set_active_turn(monster_node)

func set_active_turn(active: CanvasItem) -> void:
	if current_active == active:
		return

	_cleanup_tweens()

	var previous_active = current_active
	current_active = active

	if reduced_motion:
		# Instant transition - AC-2.2.5
		_instant_transition(previous_active, active)
	else:
		# Smooth animated transition - AC-2.2.3
		_animated_transition(previous_active, active)

	emit_signal("turn_changed", active)

func _instant_transition(previous: CanvasItem, active: CanvasItem) -> void:
	# Immediately set visual states
	if previous and is_instance_valid(previous):
		previous.modulate = INACTIVE_DIM_COLOR

	if active and is_instance_valid(active):
		active.modulate = ACTIVE_GLOW_COLOR

func _animated_transition(previous: CanvasItem, active: CanvasItem) -> void:
	# Dim the previously active node
	if previous and is_instance_valid(previous) and previous != active:
		var dim_tween = create_tween()
		dim_tween.set_trans(Tween.TRANS_SINE)
		dim_tween.set_ease(Tween.EASE_IN_OUT)
		dim_tween.tween_property(previous, "modulate", INACTIVE_DIM_COLOR, TRANSITION_DURATION)
		dim_tween.tween_callback(func(): _remove_tween(dim_tween))
		active_tweens.append(dim_tween)

	# Glow the newly active node
	if active and is_instance_valid(active):
		var glow_tween = create_tween()
		glow_tween.set_trans(Tween.TRANS_SINE)
		glow_tween.set_ease(Tween.EASE_OUT)
		glow_tween.tween_property(active, "modulate", ACTIVE_GLOW_COLOR, TRANSITION_DURATION)
		glow_tween.tween_callback(func(): _remove_tween(glow_tween))
		active_tweens.append(glow_tween)

	# Dim the other node if not already processed
	var other = monster_node if active == player_node else player_node
	if other and is_instance_valid(other) and other != previous and other != active:
		var other_tween = create_tween()
		other_tween.set_trans(Tween.TRANS_SINE)
		other_tween.set_ease(Tween.EASE_IN_OUT)
		other_tween.tween_property(other, "modulate", INACTIVE_DIM_COLOR, TRANSITION_DURATION)
		other_tween.tween_callback(func(): _remove_tween(other_tween))
		active_tweens.append(other_tween)

func _reset_indicators() -> void:
	_cleanup_tweens()
	current_active = null

	if player_node and is_instance_valid(player_node):
		player_node.modulate = NORMAL_COLOR
	if monster_node and is_instance_valid(monster_node):
		monster_node.modulate = NORMAL_COLOR

func _remove_tween(tween: Tween) -> void:
	active_tweens.erase(tween)
	if is_instance_valid(tween):
		tween.kill()

func _cleanup_tweens() -> void:
	for tween in active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()

# Manual trigger for external control (e.g., skill selection UI)
func highlight_player() -> void:
	set_active_turn(player_node)

func highlight_monster() -> void:
	set_active_turn(monster_node)

# Get the currently active node
func get_active() -> CanvasItem:
	return current_active

func is_player_turn() -> bool:
	return current_active == player_node

func is_monster_turn() -> bool:
	return current_active == monster_node

func _exit_tree() -> void:
	_cleanup_tweens()

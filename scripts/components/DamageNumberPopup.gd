class_name DamageNumberPopup
extends Control

# DamageNumberPopup - Visual feedback for damage and healing events
# AC-2.2.1: Damage and Healing Numbers
# - Bounce animation (500ms)
# - Red for damage, Green for healing
# - Shake effect for damage
# - Pulse effect for healing
# - Critical hit larger + screen flash (handled by controller or additional effect)
# - Fade out (400ms)

# Configuration
const DAMAGE_COLOR = Color(0.8, 0.2, 0.2, 1.0) # Red
const HEALING_COLOR = Color(0.2, 0.8, 0.2, 1.0) # Green
const CRITICAL_SCALE = 1.5
const NORMAL_SCALE = 1.0
const ANIMATION_DURATION = 0.5 # 500ms bounce
const FADE_DURATION = 0.4 # 400ms fade
const LIFETIME = 1.0 # Total lifetime

# Properties
var value: int = 0
var type: String = "damage" # "damage", "healing", "miss", "blocked", "status"
var is_critical: bool = false
var _text_override: String = ""
var _use_text_override: bool = false

# Nodes
@onready var label: Label = $Label

func _ready() -> void:
	if label:
		_update_visuals()
		_start_animation()

func setup(new_value: int, new_type: String, critical: bool = false) -> void:
	value = new_value
	type = new_type
	is_critical = critical
	_use_text_override = false

	# Update immediately if ready, otherwise _ready will handle it
	if is_node_ready() and label:
		_update_visuals()
		_start_animation()


func setup_text(text: String, new_type: String = "status", critical: bool = false) -> void:
	# Floating text modes: MISS, BLOCKED, status names, etc.
	value = 0
	type = new_type
	is_critical = critical
	_text_override = text
	_use_text_override = true
	if is_node_ready() and label:
		_update_visuals()
		_start_animation()


func _update_visuals() -> void:
	if _use_text_override and _text_override != "":
		label.text = _text_override
	elif type == "miss":
		label.text = "MISS"
	elif type == "blocked":
		label.text = "BLOCKED"
	elif type == "healing":
		label.text = "+" + str(value)
	else:
		label.text = str(value)

	_apply_type_color()

	# Set scale based on critical
	var target_scale = CRITICAL_SCALE if is_critical else NORMAL_SCALE
	scale = Vector2(target_scale, target_scale)

	# Center pivot for correct scaling
	pivot_offset = size / 2


func _apply_type_color() -> void:
	match type:
		"healing":
			label.modulate = HEALING_COLOR
		"miss", "blocked":
			label.modulate = Color(0.85, 0.85, 0.9, 1.0)
		"status":
			label.modulate = Color(0.85, 0.7, 1.0, 1.0)
		_:
			label.modulate = DAMAGE_COLOR

func _start_animation() -> void:
	var tween = create_tween()

	# 1. Bounce / Float up animation (500ms)
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Move up
	var target_pos = position - Vector2(0, 50)
	tween.tween_property(self, "position", target_pos, ANIMATION_DURATION)

	# Scale punch for critical
	if is_critical:
		scale = Vector2.ZERO
		tween.tween_property(self, "scale", Vector2(CRITICAL_SCALE, CRITICAL_SCALE), ANIMATION_DURATION)
	else:
		scale = Vector2.ZERO
		tween.tween_property(self, "scale", Vector2(NORMAL_SCALE, NORMAL_SCALE), ANIMATION_DURATION)

	# Special effects based on type
	if type == "damage":
		# Shake effect
		_apply_shake()
	elif type == "healing":
		# Pulse effect is handled by the scale tween mostly, but could add specific pulse
		pass

	# 2. Fade out sequence
	# We want fade out to happen after a short delay or towards the end
	# The AC says "fade out smoothly over 400ms".
	# Let's chain it.

	var fade_tween = create_tween()
	fade_tween.tween_interval(ANIMATION_DURATION) # Wait for bounce
	fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	fade_tween.tween_callback(queue_free)

func _apply_shake() -> void:
	# Simple shake using a separate tween
	var shake_tween = create_tween()
	var shake_offset = 5.0
	var shake_duration = 0.05

	for i in range(5):
		shake_tween.tween_property(label, "position:x", shake_offset, shake_duration)
		shake_tween.tween_property(label, "position:x", -shake_offset, shake_duration)

	shake_tween.tween_property(label, "position:x", 0.0, shake_duration)

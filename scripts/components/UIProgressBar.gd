extends ProgressBar

# UIProgressBar - Enhanced progress bar with label and animations

@export var label_text: String = "Progress"
@export var show_label: bool = true
@export var animate_changes: bool = true
@export var animation_speed: float = 2.0

@onready var label: Label = $Label

var target_value: float = 0.0

func _ready():
	_update_label()
	if show_label and label:
		label.visible = true
	else:
		label.visible = false

func _process(delta):
	if animate_changes and value != target_value:
		var diff = target_value - value
		var change = sign(diff) * animation_speed * delta * 100
		if abs(change) > abs(diff):
			change = diff
		value += change

func set_progress(new_value: float, new_label: String = ""):
	target_value = clamp(new_value, min_value, max_value)
	if animate_changes:
		# Animation will handle the change in _process
		pass
	else:
		value = target_value

	if new_label:
		label_text = new_label
		_update_label()

func set_label_text(text: String):
	label_text = text
	_update_label()

func set_show_label(show: bool):
	show_label = show
	if label:
		label.visible = show

func _update_label():
	if label:
		label.text = label_text
		if show_percentage:
			label.text += " (" + str(int(value)) + "%)"

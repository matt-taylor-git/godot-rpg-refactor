extends Panel

# UIPanel - Reusable panel component with content management

@export var panel_title: String = ""
@export var content_separation: int = 10

@onready var container: VBoxContainer = $MarginContainer/VBoxContainer

func _ready():
	if panel_title:
		_add_title_label()

func add_content(node: Node):
	if container:
		container.add_child(node)

func clear_content():
	if container:
		for child in container.get_children():
			child.queue_free()

func add_spacer(size: int = 10):
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, size)
	add_content(spacer)

func _add_title_label():
	var title_label = Label.new()
	title_label.text = panel_title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.theme = theme
	title_label.add_theme_font_size_override("font_size", 18)
	container.add_child(title_label)

	var separator = HSeparator.new()
	container.add_child(separator)

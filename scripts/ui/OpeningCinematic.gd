extends Control

signal intro_finished

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@export var autoplay: bool = true

var _is_finishing: bool = false

@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var skip_hint: Label = $SkipHint


func _ready() -> void:
	video_player.finished.connect(_finish_intro)
	_animate_skip_hint()
	if not autoplay:
		return

	if video_player.stream == null:
		call_deferred("_finish_intro")
		return

	video_player.play()


func _input(event: InputEvent) -> void:
	if not _is_skip_event(event):
		return
	get_viewport().set_input_as_handled()
	_finish_intro()


func _is_skip_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _animate_skip_hint() -> void:
	skip_hint.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.65)
	tween.tween_property(skip_hint, "modulate:a", 0.72, 0.45).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): tween.kill())


func _finish_intro() -> void:
	if _is_finishing:
		return
	_is_finishing = true
	set_process_input(false)
	video_player.stop()
	intro_finished.emit()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

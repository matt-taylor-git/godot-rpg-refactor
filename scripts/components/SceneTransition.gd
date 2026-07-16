extends CanvasLayer

# SceneTransition - Global fade overlay for scene changes
# Autoload so the overlay survives change_scene_to_file()

const FADE_OUT_DURATION := 0.25
const FADE_IN_DURATION := 0.25

var _overlay: ColorRect = null
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Warm charcoal, not pure black (style guide)
	_overlay.color = Color(0.08, 0.07, 0.06, 0.0)
	_overlay.z_index = 100
	add_child(_overlay)


func is_busy() -> bool:
	return _busy


func change_scene(scene_path: String) -> void:
	if _busy:
		return
	if not ResourceLoader.exists(scene_path):
		print("SceneTransition: scene not found: ", scene_path)
		return

	_busy = true
	var reduce_motion: bool = ProjectSettings.get_setting(
		"accessibility/reduced_motion", false
	)

	if reduce_motion:
		get_tree().change_scene_to_file(scene_path)
		_busy = false
		return

	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.color.a = 0.0

	var fade_out := create_tween()
	fade_out.tween_property(_overlay, "color:a", 1.0, FADE_OUT_DURATION)
	await fade_out.finished
	fade_out.kill()

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("SceneTransition: failed to change scene: ", error)

	# Wait a frame so the new scene is in the tree before fading in
	await get_tree().process_frame
	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.tween_property(_overlay, "color:a", 0.0, FADE_IN_DURATION)
	await fade_in.finished
	fade_in.kill()

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

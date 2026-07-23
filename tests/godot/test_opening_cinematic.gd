extends GutTest

const OPENING_SCENE_PATH: String = "res://scenes/ui/opening_cinematic.tscn"

var opening: Control


func before_each() -> void:
	var opening_scene: PackedScene = load(OPENING_SCENE_PATH)
	opening = opening_scene.instantiate()
	opening.set("autoplay", false)
	add_child(opening)
	await get_tree().process_frame


func after_each() -> void:
	if opening and is_instance_valid(opening):
		opening.video_player.stop()
		opening.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func test_video_is_full_screen_and_uses_rendered_cinematic() -> void:
	var video_player: VideoStreamPlayer = opening.get_node("VideoPlayer")
	assert_not_null(video_player.stream, "Opening cinematic should have a video stream")
	assert_eq(video_player.stream.resource_path, "res://assets/video/opening_cinematic.ogv")
	assert_true(video_player.expand, "Opening cinematic should scale to the viewport")


func test_cinematic_contains_no_baked_in_game_title_label() -> void:
	var skip_hint: Label = opening.get_node("SkipHint")
	assert_false("pyrpg" in skip_hint.text.to_lower(), "Opening overlay should remain title-neutral")


func test_keyboard_mouse_and_controller_inputs_can_skip() -> void:
	var key_event := InputEventKey.new()
	key_event.pressed = true
	assert_true(opening._is_skip_event(key_event))

	var mouse_event := InputEventMouseButton.new()
	mouse_event.pressed = true
	assert_true(opening._is_skip_event(mouse_event))

	var controller_event := InputEventJoypadButton.new()
	controller_event.pressed = true
	assert_true(opening._is_skip_event(controller_event))


func test_released_or_repeated_inputs_do_not_skip() -> void:
	var released_key := InputEventKey.new()
	assert_false(opening._is_skip_event(released_key))

	var repeated_key := InputEventKey.new()
	repeated_key.pressed = true
	repeated_key.echo = true
	assert_false(opening._is_skip_event(repeated_key))

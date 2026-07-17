extends Node

# ScreenshotTour - Walks game scenes/dialogs and writes PNGs under screenshots/latest/
# Trigger: godot --path . -- --screenshot-tour
# Prefer: .\tools\Run-ScreenshotTour.ps1

const OUTPUT_REL := "res://screenshots/latest"
const SETTLE_TIMEOUT_SEC := 5.0

# Single place to extend the gallery. Each step:
#   id (required), scene?, dialog? (res path), start_combat?
const TOUR: Array = [
	{"id": "main_menu", "scene": "main_menu"},
	{"id": "character_creation", "scene": "character_creation"},
	# town_scene / world_map alias to exploration hub
	{"id": "hub", "scene": "exploration_scene"},
	{
		"id": "combat",
		"start_combat": true,
		"combat_monster": "wolf",
		"combat_area": "forest",
	},
	{
		"id": "combat_skills",
		"start_combat": true,
		"combat_monster": "goblin",
		"combat_area": "cave",
		"combat_ui": "skills",
	},
	{
		"id": "combat_low_hp",
		"start_combat": true,
		"combat_monster": "orc",
		"combat_area": "mountain",
		"combat_seed": {"player_hp_frac": 0.2},
	},
	{"id": "victory", "scene": "victory_scene"},
	{"id": "game_over", "scene": "game_over_scene"},
	{"id": "shop", "scene": "exploration_scene", "dialog": "res://scenes/ui/shop_dialog.tscn"},
	{"id": "inventory", "scene": "exploration_scene", "dialog": "res://scenes/ui/inventory_dialog.tscn"},
	{"id": "skills", "scene": "exploration_scene", "dialog": "res://scenes/ui/skills_dialog.tscn"},
	{"id": "quest_log", "scene": "exploration_scene", "dialog": "res://scenes/ui/quest_log_dialog.tscn"},
	{
		"id": "dialogue",
		"scene": "exploration_scene",
		"dialog": "res://scenes/ui/dialogue_scene.tscn",
		"start_dialogue": "quest_giver",
	},
	{
		"id": "quest_complete",
		"scene": "exploration_scene",
		"dialog": "res://scenes/ui/quest_completion_dialog.tscn",
		"quest_complete_demo": true,
	},
	{"id": "options", "scene": "main_menu", "dialog": "res://scenes/ui/options_dialog.tscn"},
	{"id": "save_slot", "scene": "main_menu", "dialog": "res://scenes/ui/save_slot_dialog.tscn"},
	{"id": "game_menu", "scene": "exploration_scene", "dialog": "res://scenes/ui/game_menu_dialog.tscn"},
	{"id": "codex", "scene": "exploration_scene", "dialog": "res://scenes/ui/codex_dialog.tscn"},
]

var _output_dir: String = ""
var _results: Array = []
var _started_at: String = ""


func _ready() -> void:
	print("ScreenshotTour: starting")
	call_deferred("_run_tour")


func _run_tour() -> void:
	_started_at = Time.get_datetime_string_from_system(true, true)
	_output_dir = _prepare_output_dir()
	if _output_dir.is_empty():
		print("ScreenshotTour: failed to prepare output dir")
		get_tree().quit(1)
		return

	# Instant scene changes (no fade covering UI)
	if GameSettings:
		GameSettings.set_reduced_motion(true)

	GameManager.new_game("ScreenshotBot", "Warrior")
	_seed_demo_state()

	# Wait a couple frames so autoloads/UI settle
	await get_tree().process_frame
	await get_tree().process_frame

	for step in TOUR:
		# Keep tour captures consistent even if a dialog reloads settings
		if GameSettings:
			GameSettings.set_reduced_motion(true)
		await _run_step(step)

	_write_manifest()
	var failed := 0
	for r in _results:
		if not r.get("ok", false):
			failed += 1
	var ok_count: int = _results.size() - failed
	print(
		"SCREENSHOT_TOUR_DONE ok=%d failed=%d out=%s"
		% [ok_count, failed, _output_dir]
	)
	get_tree().quit(1 if failed > 0 else 0)


func _run_step(step: Dictionary) -> void:
	var step_id: String = str(step.get("id", "unknown"))
	print("ScreenshotTour: step ", step_id)
	var result := {"id": step_id, "ok": false, "path": "", "error": ""}

	# Soft-fail per step so one bad dialog does not abort the tour
	var err_msg: String = await _execute_step(step)
	var dialog_node: Node = _find_tour_dialog()
	if not err_msg.is_empty():
		result["error"] = err_msg
		print("ScreenshotTour: FAIL ", step_id, " — ", err_msg)
		_free_dialog(dialog_node)
		_results.append(result)
		return

	var settle_err: String = await _settle()
	if not settle_err.is_empty():
		result["error"] = settle_err
		print("ScreenshotTour: FAIL ", step_id, " — ", settle_err)
		_free_dialog(dialog_node)
		_results.append(result)
		return

	var png_path := _output_dir.path_join("%s.png" % step_id)
	var capture_err: String = await _capture_to(png_path)
	_free_dialog(dialog_node)

	if not capture_err.is_empty():
		result["error"] = capture_err
		print("ScreenshotTour: FAIL ", step_id, " — ", capture_err)
		_results.append(result)
		return

	result["ok"] = true
	result["path"] = "latest/%s.png" % step_id
	print("ScreenshotTour: wrote ", png_path)
	_results.append(result)


func _execute_step(step: Dictionary) -> String:
	var start_combat: bool = bool(step.get("start_combat", false))
	var scene_name: String = str(step.get("scene", ""))
	var dialog_path: String = str(step.get("dialog", ""))

	if start_combat:
		if not GameManager.get_player():
			return "no player for combat"
		var area_id: String = str(step.get("combat_area", ""))
		if not area_id.is_empty() and GameManager.game_data is Dictionary:
			GameManager.game_data["current_area_id"] = area_id
		var monster_type: String = str(step.get("combat_monster", ""))
		var combat_msg
		if not monster_type.is_empty():
			combat_msg = await GameManager.start_combat_with_type(monster_type)
		else:
			combat_msg = await GameManager.start_combat()
		if typeof(combat_msg) == TYPE_STRING and str(combat_msg).begins_with("No player"):
			return str(combat_msg)
		await _wait_for_scene_host()
		var host := await _wait_for_scene_host()
		if host and host.has_method("apply_screenshot_state"):
			var seed_state: Dictionary = {}
			if step.has("combat_seed") and step["combat_seed"] is Dictionary:
				seed_state = (step["combat_seed"] as Dictionary).duplicate()
			if step.has("combat_ui"):
				seed_state["combat_ui"] = step["combat_ui"]
			if not seed_state.is_empty():
				host.apply_screenshot_state(seed_state)
			await get_tree().process_frame
			await get_tree().process_frame
	elif not scene_name.is_empty():
		var expected := "res://scenes/ui/%s.tscn" % scene_name
		if not ResourceLoader.exists(expected):
			return "scene not found: %s" % expected
		await GameManager.change_scene(scene_name)
		await _wait_for_scene_host()

	if not dialog_path.is_empty():
		if not ResourceLoader.exists(dialog_path):
			return "dialog not found: %s" % dialog_path
		var packed: PackedScene = load(dialog_path) as PackedScene
		if packed == null:
			return "failed to load dialog: %s" % dialog_path
		var dialog: Node = packed.instantiate()
		dialog.add_to_group("screenshot_tour_dialog")
		var host := await _wait_for_scene_host()
		if host == null:
			dialog.free()
			return "no current_scene to host dialog"
		# Quest completion needs quest data before _ready display
		if bool(step.get("quest_complete_demo", false)) and dialog.has_method("set_quest"):
			var demo_quest = QuestFactory.create_quest("kill_goblins", 1)
			demo_quest.current_count = demo_quest.target_count
			demo_quest.completed = true
			dialog.set_quest(demo_quest)
		host.add_child(dialog)
		var start_npc: String = str(step.get("start_dialogue", ""))
		if not start_npc.is_empty() and dialog.has_method("start_dialogue"):
			dialog.start_dialogue(start_npc)
		await get_tree().process_frame
		await get_tree().process_frame

	return ""


func _wait_for_scene_host() -> Node:
	# change_scene_to_file may leave current_scene null for a frame or two
	for _i in range(10):
		var host := _get_scene_host()
		if host:
			return host
		await get_tree().process_frame
	return _get_scene_host()


func _get_scene_host() -> Node:
	var current := get_tree().current_scene
	if current and is_instance_valid(current):
		return current
	# Fallback: last non-tour child of root (current scene sits after autoloads)
	var root := get_tree().root
	for i in range(root.get_child_count() - 1, -1, -1):
		var child: Node = root.get_child(i)
		if child == self or child.name == "ScreenshotTour":
			continue
		# Prefer Control/Node2D UI roots over autoload Nodes
		if child is Control or child is Node2D:
			return child
	return null

func _find_tour_dialog() -> Node:
	var nodes := get_tree().get_nodes_in_group("screenshot_tour_dialog")
	if nodes.is_empty():
		return null
	return nodes[0]

func _settle() -> String:
	var elapsed := 0.0
	while SceneTransition and SceneTransition.is_busy():
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if elapsed > SETTLE_TIMEOUT_SEC:
			return "timeout waiting for SceneTransition"

	# Extra frames so layout/ready finishes after fade
	await get_tree().process_frame
	await get_tree().process_frame
	return ""


func _capture_to(png_path: String) -> String:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		return "viewport texture is null"
	var img: Image = tex.get_image()
	if img == null:
		return "get_image() returned null"
	var err := img.save_png(png_path)
	if err != OK:
		return "save_png failed (%d): %s" % [err, png_path]
	return ""


func _free_dialog(dialog_node: Node) -> void:
	if dialog_node and is_instance_valid(dialog_node):
		dialog_node.queue_free()


func _prepare_output_dir() -> String:
	var abs_dir := ProjectSettings.globalize_path(OUTPUT_REL)
	if DirAccess.dir_exists_absolute(abs_dir):
		_remove_dir_recursive(abs_dir)
	var mk_err := DirAccess.make_dir_recursive_absolute(abs_dir)
	if mk_err != OK:
		print("ScreenshotTour: make_dir failed ", mk_err, " ", abs_dir)
		return ""
	return abs_dir


func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for dir_name in dir.get_directories():
		var child := path.path_join(dir_name)
		_remove_dir_recursive(child)
		DirAccess.remove_absolute(child)


func _seed_demo_state() -> void:
	# Populate inventory, equipment, quests, and codex so dialog captures are reviewable
	var player = GameManager.get_player()
	if player == null:
		print("ScreenshotTour: seed skipped (no player)")
		return

	player.gold = 300
	for item_id in ["sword", "shield", "health_potion", "mana_potion", "gold_coin"]:
		var item = ItemFactory.create_item(item_id)
		if item:
			player.add_item(item)

	# Equip a second sword so inventory still shows icons + filled weapon slot
	var equipped_sword = ItemFactory.create_item("sword")
	if equipped_sword:
		player.equip_item(equipped_sword, "weapon")

	var active_quest = QuestFactory.create_quest("kill_goblins", 1)
	active_quest.current_count = 2
	QuestManager.accept_quest(active_quest)

	var done_quest = QuestFactory.create_quest("collect_herbs", 1)
	done_quest.current_count = done_quest.target_count
	done_quest.completed = true
	QuestManager.completed_quests.append(done_quest)

	if CodexManager:
		CodexManager.unlock_entry("goblin_history")
		CodexManager.unlock_entry("eldridge_founding")

	print("ScreenshotTour: demo state seeded")


func _write_manifest() -> void:
	var manifest := {
		"started_at": _started_at,
		"finished_at": Time.get_datetime_string_from_system(true, true),
		"resolution": "%dx%d"
		% [
			int(get_viewport().get_visible_rect().size.x),
			int(get_viewport().get_visible_rect().size.y),
		],
		"results": _results,
	}
	var path := _output_dir.path_join("manifest.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("ScreenshotTour: could not write manifest ", path)
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("ScreenshotTour: manifest ", path)

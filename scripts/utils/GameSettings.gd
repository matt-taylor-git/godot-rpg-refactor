class_name GameSettings
extends RefCounted

# GameSettings - Persist accessibility (and future audio) settings
# Stored at user://settings.cfg via ConfigFile

const SETTINGS_PATH := "user://settings.cfg"
const SECTION_ACCESSIBILITY := "accessibility"
const SECTION_AUDIO := "audio"  # Reserved for future volume keys

const KEY_REDUCED_MOTION := "reduced_motion"
# Future (not used yet — leave for audio workstream):
# const KEY_MUSIC_VOLUME := "music_volume"
# const KEY_SFX_VOLUME := "sfx_volume"

static var _reduced_motion: bool = false
static var _loaded: bool = false


static func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err == OK:
		_reduced_motion = bool(
			config.get_value(SECTION_ACCESSIBILITY, KEY_REDUCED_MOTION, false)
		)
	else:
		_reduced_motion = false

	_apply_to_project_settings()
	_loaded = true


static func save_settings() -> void:
	var config := ConfigFile.new()
	# Preserve existing keys if file already exists
	config.load(SETTINGS_PATH)
	config.set_value(SECTION_ACCESSIBILITY, KEY_REDUCED_MOTION, _reduced_motion)
	# Future audio placeholders (commented — do not write until audio lands):
	# config.set_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, 0.8)
	# config.set_value(SECTION_AUDIO, KEY_SFX_VOLUME, 0.9)
	config.save(SETTINGS_PATH)
	_apply_to_project_settings()


static func get_reduced_motion() -> bool:
	if not _loaded:
		load_settings()
	return _reduced_motion


static func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	_apply_to_project_settings()


static func _apply_to_project_settings() -> void:
	ProjectSettings.set_setting("accessibility/reduced_motion", _reduced_motion)

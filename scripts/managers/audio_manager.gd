class_name AudioManager extends Node

# Signals
signal volumes_changed

# Nodes
@export_category("Audio players")
@export var _sound_player: AudioStreamPlayer
@export var _music_player: AudioStreamPlayer

# Volumes
@export_category("Volumes")
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var sound_volume_db: float = -6.0206:
	set(value):
		sound_volume_db = value
		_update_volumes()
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var music_volume_db: float = -6.0206:
	set(value):
		music_volume_db = value
		_update_volumes()
@export_range(-80.0, 6.0, 0.1, "suffix:dB") var master_volume_db: float = -6.0206:
	set(value):
		master_volume_db = value
		_update_volumes()

# Files
@export_category("Music")
@export var main_menu_music: AudioStream
@export var level_1_music: AudioStream
@export var level_2_music: AudioStream
@export var level_3_music: AudioStream

@export_category("Global sounds")
@export var menu_button_stream: AudioStream
@export var undo_stream: AudioStream
@export var puzzle_finished_stream: AudioStream
@export var scene_change_glass: AudioStream

# Variables
var _audio_enabled := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UndoManager.is_undoing_started.connect(play_undo_sound)
	%SceneManager.loading_level.connect(play_puzzle_finished_sound)
	%AnimationManager.animation_player.animation_started.connect(_on_animation_started)
	%AnimationManager.initial_animation_finished.connect(_on_initial_animation_finished)
	call_deferred("_connect_menus")
	_update_volumes()

func _on_initial_animation_finished() -> void:
	_audio_enabled = true
	play_main_menu_music()

func _update_volumes() -> void:
	if _music_player != null:
		_music_player.volume_db = music_volume_db + master_volume_db
	if _sound_player != null:
		_sound_player.volume_db = sound_volume_db + master_volume_db
	volumes_changed.emit()

func _connect_menus() -> void:
	for group in ["main_menu", "pause_menu"]:
		for node in get_tree().get_nodes_in_group(group):
			var menu := node as Menu
			if menu == null:
				continue
			if not menu.button_focus_entered.is_connected(play_menu_button_sound):
				menu.button_focus_entered.connect(play_menu_button_sound)
			if not menu.button_selected.is_connected(play_menu_button_sound):
				menu.button_selected.connect(play_menu_button_sound)

func _on_animation_started(animation_name: StringName) -> void:
	if animation_name == &"scene_change_glass":
		play_scene_change_sound()

func play_main_menu_music() -> void:
	play_music(main_menu_music)

func play_level_music(level: int) -> void:
	match level:
		0:
			play_music(level_1_music)
		1:
			play_music(level_2_music)
		2:
			play_music(level_3_music)

func play_music(stream: AudioStream) -> void:
	if not _audio_enabled or stream == null or _music_player == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()

func play_menu_button_sound() -> void:
	_play_sound(menu_button_stream)

func play_undo_sound() -> void:
	_play_sound(undo_stream)

func play_puzzle_finished_sound() -> void:
	_play_sound(puzzle_finished_stream)

func play_scene_change_sound() -> void:
	_play_sound(scene_change_glass)

func _play_sound(stream: AudioStream) -> void:
	if not _audio_enabled or stream == null or _sound_player == null:
		return
	_sound_player.stream = stream
	_sound_player.play()

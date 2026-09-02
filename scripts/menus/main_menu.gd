class_name MainMenu extends Menu

# Nodes
@onready var scene_manager: SceneManager = %SceneManager
@onready var audio_manager: AudioManager = %AudioManager
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sound_slider: HSlider = %SoundSlider
@export var menu_buttons: Container
@export var level_buttons: GridContainer
@export var tutorial: Control
@export var credits: Control
@export var options_menu: Control
@export var back_button: VBoxContainer


func _ready() -> void:
	super._ready()
	scene_manager.main_menu_requested.connect(_show_main_menu)
	_setup_audio_sliders()
	var animation_manager: AnimationManager = %AnimationManager
	if animation_manager.is_animating:
		_set_buttons_enabled(false)
		animation_manager.initial_animation_finished.connect(_on_initial_animation_finished)

func _on_initial_animation_finished() -> void:
	_set_buttons_enabled(true)
	_focus_initial_node()

func _show_main_menu() -> void:
	visible = true
	_on_back_button_pressed(false)

### Menu Buttons pressed
func _on_play_button_pressed() -> void:
	_button_selected()
	_game_started(0)

func _on_levels_button_pressed() -> void:
	_button_selected()
	menu_buttons.visible = false
	back_button.visible = true
	level_buttons.visible = true
	_focus_button(0)

func _on_options_button_pressed() -> void:
	_button_selected()
	menu_buttons.visible = false
	back_button.visible = true
	options_menu.visible = true
	_focus_button(0)

func _on_tutorial_button_pressed() -> void:
	_button_selected()
	$Logo.visible = false
	menu_buttons.visible = false
	back_button.visible = true
	back_button.position.x = 72.0
	back_button.position.y = 25.0
	tutorial.visible = true
	_focus_button(0)

func _on_credits_button_pressed() -> void:
	_button_selected()
	$Logo.visible = false
	menu_buttons.visible = false
	back_button.visible = true
	back_button.position.x = 72.0
	back_button.position.y = 50.0
	credits.visible = true
	_focus_button(0)

func _on_quit_button_pressed() -> void:
	_button_selected()
	get_tree().quit()

# Sub-Menu Buttons
func _on_back_button_pressed(play_sound := true) -> void:
	if play_sound:
		_button_selected()
	_set_buttons_enabled(true)
	$Logo.visible = true
	back_button.visible = false
	back_button.position.x = 48.0
	back_button.position.y = 138.0
	menu_buttons.visible = true
	level_buttons.visible = false
	tutorial.visible = false
	credits.visible = false
	options_menu.visible = false
	_focus_initial_node()

func _on_level_1_button_pressed() -> void:
	_button_selected()
	_game_started(0)

func _on_level_2_button_pressed() -> void:
	_button_selected()
	_game_started(1)

func _on_level_3_button_pressed() -> void:
	_button_selected()
	_game_started(2)

func _setup_audio_sliders() -> void:
	master_slider.value = _db_to_slider(audio_manager.master_volume_db)
	music_slider.value = _db_to_slider(audio_manager.music_volume_db)
	sound_slider.value = _db_to_slider(audio_manager.sound_volume_db)
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sound_slider.value_changed.connect(_on_sound_volume_changed)

func _db_to_slider(value_db: float) -> float:
	if value_db <= -80.0:
		return 0.0
	return db_to_linear(value_db) * 100.0

func _slider_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return linear_to_db(value / 100.0)

func _on_master_volume_changed(value: float) -> void:
	audio_manager.master_volume_db = _slider_to_db(value)

func _on_music_volume_changed(value: float) -> void:
	audio_manager.music_volume_db = _slider_to_db(value)

func _on_sound_volume_changed(value: float) -> void:
	audio_manager.sound_volume_db = _slider_to_db(value)

func _set_buttons_enabled(enabled: bool) -> void:
	for button in buttons:
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if not enabled:
		get_viewport().gui_release_focus()

func _game_started(level: int) -> void:
	_set_buttons_enabled(false)
	await %AnimationManager.play_scene_change_transition()
	scene_manager.load_level(level)
	visible = false
	await %AnimationManager.play_loading_new_level_transition()

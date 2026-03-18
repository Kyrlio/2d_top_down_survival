extends Control

@export var start_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var camera: Camera2D

@export var game_scene: String = "uid://bu07ap1m14c4n"

const LOADING_SCREEN_SCENE := preload("res://scenes/ui/loading_screen/loading_screen.tscn")

const HOVER_ZOOM_SCALE := 1.05
const ZOOM_TWEEN_TIME := 0.18

var _base_zoom: Vector2
var _zoom_tween: Tween


func _ready() -> void:
	start_button.pressed.connect(_on_button_pressed.bind(start_button))
	start_button.mouse_entered.connect(_on_button_hovered)
	start_button.mouse_exited.connect(_on_button_unhovered)

	settings_button.pressed.connect(_on_button_pressed.bind(settings_button))
	settings_button.mouse_entered.connect(_on_button_hovered)
	settings_button.mouse_exited.connect(_on_button_unhovered)

	quit_button.pressed.connect(_on_button_pressed.bind(quit_button))
	quit_button.mouse_entered.connect(_on_button_hovered)
	quit_button.mouse_exited.connect(_on_button_unhovered)

	if camera != null:
		_base_zoom = camera.zoom


func _on_button_pressed(button: Button) -> void:
	match button:
		start_button:
			_play_loading_and_change_scene()
		settings_button:
			print("settings")
		quit_button:
			get_tree().quit()


func _play_loading_and_change_scene() -> void:
	start_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true

	var loading_screen := LOADING_SCREEN_SCENE.instantiate()
	loading_screen.target_scene = game_scene
	get_tree().root.add_child(loading_screen)


func _on_button_hovered() -> void:
	if camera == null:
		return
	_set_camera_zoom(_base_zoom * HOVER_ZOOM_SCALE)


func _on_button_unhovered() -> void:
	if camera == null:
		return
	_set_camera_zoom(_base_zoom)


func _set_camera_zoom(target_zoom: Vector2) -> void:
	if _zoom_tween != null:
		_zoom_tween.kill()
	_zoom_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_parallel(true)
	_zoom_tween.tween_property(camera, "zoom", target_zoom, ZOOM_TWEEN_TIME)

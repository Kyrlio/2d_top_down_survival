class_name PauseMenu extends Control

signal resume_requested
signal settings_requested
signal quit_requested

@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("escape"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	
	resume_button.pressed.connect(func(): resume_requested.emit())
	settings_button.pressed.connect(func(): settings_requested.emit())
	quit_button.pressed.connect(func(): quit_requested.emit())


func focus_first_button() -> void:
	if resume_button:
		resume_button.grab_focus()

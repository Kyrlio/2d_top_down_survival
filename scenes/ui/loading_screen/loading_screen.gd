extends CanvasLayer

signal loading_screen_has_full_coverage

@export var anim_player: AnimationPlayer
@export var target_scene: String = ""


func _ready() -> void:
	anim_player.play("fade_in")
	await anim_player.animation_finished
	loading_screen_has_full_coverage.emit()

	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
		await get_tree().process_frame
		watch_scene(get_tree().current_scene)


func _start_outro_animation() -> void:
	anim_player.play("fade_out")
	await anim_player.animation_finished
	queue_free()


func watch_scene(scene: Node) -> void:
	if scene != null and scene.has_signal("loading_finished"):
		scene.loading_finished.connect(_on_scene_loading_finished)
		if scene.has_method("has_loading_finished") and scene.has_loading_finished():
			_on_scene_loading_finished()
		elif scene.has_method("request_loading_finished"):
			scene.request_loading_finished()


func _on_scene_loading_finished() -> void:
	await _start_outro_animation()

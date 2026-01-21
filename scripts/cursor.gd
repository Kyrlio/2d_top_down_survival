extends CanvasLayer

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	# Afficher le curseur personnalisé au démarrage
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	sprite_2d.visible = true


func _physics_process(_delta: float) -> void:
	sprite_2d.global_position = sprite_2d.get_global_mouse_position()


func change_cursor(sprite: CompressedTexture2D, cursor_scale := Vector2.ONE, cursor_pos := Vector2(-10,-8)):
	sprite_2d.texture = sprite
	sprite_2d.scale = cursor_scale
	sprite_2d.offset = cursor_pos

func show_cursor(visibility: bool):
	sprite_2d.visible = visibility
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func get_actual_cursor() -> CompressedTexture2D:
	return sprite_2d.texture

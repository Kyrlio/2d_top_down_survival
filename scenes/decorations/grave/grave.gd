extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var texture_regions: Array[Rect2] = [
	Rect2(688.0, 256.0, 16.0, 16.0), 
	Rect2(704.0, 256.0, 16.0, 16.0),
	Rect2(720.0, 256.0, 16.0, 16.0),
	Rect2(736.0, 256.0, 16.0, 16.0),
	Rect2(752.0, 256.0, 16.0, 16.0)
]

func _ready() -> void:
	var region: Rect2 = texture_regions.pick_random()
	var texture: AtlasTexture = sprite.texture
	texture.region = region
	sprite.texture = texture

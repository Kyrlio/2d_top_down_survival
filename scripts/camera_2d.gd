@icon("uid://d1ugg8acbjdv6")
class_name GameCamera extends Camera2D

const NOISE_GROWTH: float = 750
const SHAKE_DECAY_RATE: float = 10

@onready var player: Player = $".."

## Distance maximale de décalage vers la souris (en pixels)
@export var mouse_lookahead_distance: float = 50.0
## Vitesse de lissage du mouvement de la caméra (plus élevé = plus réactif)
@export var camera_smoothing_speed: float = 10.0
## Vitesse de lissage du lookahead souris (plus bas = plus smooth)
@export var lookahead_smoothing_speed: float = 5.0

@export_category("Camera Shake")
@export var noise_texture: FastNoiseLite
@export var shake_strength: float

static var instance: GameCamera

var _current_lookahead_offset: Vector2 = Vector2.ZERO
var noise_offset_x: float
var noise_offset_y: float
var current_shake_percentage: float


func _ready() -> void:
	instance = self


func _process(delta: float) -> void:
	_apply_shake(delta)
	# Calculer l'offset de lookahead basé sur la position de la souris
	var target_lookahead_offset := _calculate_mouse_lookahead_offset()
	
	# Smooth le lookahead offset
	_current_lookahead_offset = _current_lookahead_offset.lerp(
		target_lookahead_offset,
		1.0 - exp(-delta * lookahead_smoothing_speed)
	)
	
	# Position cible = joueur + offset souris
	var target_pos := player.global_position + _current_lookahead_offset
	
	# Smooth vers la position cible
	global_position = global_position.lerp(target_pos, 1.0 - exp(-delta * camera_smoothing_speed))


## Calcule le décalage de lookahead basé sur la position de la souris dans le viewport
func _calculate_mouse_lookahead_offset() -> Vector2:
	# Obtenir la position de la souris dans le viewport (0,0 = coin supérieur gauche)
	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_center := viewport_size / 2.0
	var mouse_viewport_pos := get_viewport().get_mouse_position()
	
	# Vecteur du centre du viewport vers la souris, normalisé entre -1 et 1
	var offset_direction := (mouse_viewport_pos - viewport_center) / viewport_center
	
	# Limiter la magnitude à 1 (si la souris est hors du viewport)
	if offset_direction.length() > 1.0:
		offset_direction = offset_direction.normalized()
	
	# Appliquer la distance de lookahead
	return offset_direction * mouse_lookahead_distance


static func shake(shake_percent: float) -> void:
	instance.current_shake_percentage = clamp(shake_percent, 0, 1)


func _apply_shake(delta: float):
	if current_shake_percentage == 0:
		return
	
	noise_offset_x += NOISE_GROWTH * delta
	noise_offset_y += NOISE_GROWTH * delta
	
	var offset_sample_x := noise_texture.get_noise_2d(noise_offset_x, 0)
	var offset_sample_y := noise_texture.get_noise_2d(0, noise_offset_y)
	
	offset = Vector2(offset_sample_x, offset_sample_y) * shake_strength * current_shake_percentage * current_shake_percentage
	
	current_shake_percentage = max(current_shake_percentage - (SHAKE_DECAY_RATE * delta), 0)

extends Camera2D

@onready var player: Player = $".."

## Distance maximale de décalage vers la souris (en pixels)
@export var mouse_lookahead_distance: float = 50.0
## Vitesse de lissage du mouvement de la caméra (plus élevé = plus réactif)
@export var camera_smoothing_speed: float = 10.0
## Vitesse de lissage du lookahead souris (plus bas = plus smooth)
@export var lookahead_smoothing_speed: float = 5.0

var _current_lookahead_offset: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
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

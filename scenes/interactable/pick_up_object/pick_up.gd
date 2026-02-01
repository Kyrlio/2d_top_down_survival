extends Area2D

@export var slot_data: SlotData

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _base_sprite_pos: Vector2
var _base_shadow_scale: Vector2

func _ready() -> void:
	sprite.texture = slot_data.item_data.texture
	_base_sprite_pos = sprite.position
	_base_shadow_scale = shadow.scale


func _on_area_entered(area: Area2D) -> void:
	Callable(disable_collision).call_deferred()
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_method(tween_collect.bind(global_position), 0.0, 1.0, .5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ZERO, .05).set_delay(.45)
	tween.chain() #Attend que les précédents tween se finissent pour faire la suite
	
	if area.owner.inventory_data.pick_up_slot_data(slot_data):
		tween.tween_callback(collect)


func collect() -> void:
	queue_free()


func disable_collision() -> void:
	collision_shape.disabled = true


func _on_drop_animation_finished() -> void:
	monitoring = true
	monitorable = true


func tween_collect(percent: float, start_position: Vector2) -> void:
	var player: Player = PlayerManager.player
	if player == null:
		return
	
	global_position = start_position.lerp(player.global_position, percent)
	var direction_from_start = player.global_position - start_position


func play_drop_animation(target_pos: Vector2, start_pos: Vector2 = global_position) -> void:
	global_position = start_pos
	monitoring = false
	monitorable = false

	var travel_time := 0.4
	var height := 12.0
	var bounce_height := 6.0

	var mid_pos := start_pos.lerp(target_pos, 0.5)
	var move_tween := create_tween()
	move_tween.tween_property(self, "global_position", mid_pos, travel_time * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "global_position", target_pos, travel_time * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move_tween.tween_callback(_on_drop_animation_finished)

	var sprite_tween := create_tween()
	var apex := _base_sprite_pos + Vector2(0, -height)
	var bounce_apex := _base_sprite_pos + Vector2(0, -bounce_height)
	sprite_tween.tween_property(sprite, "position", apex, travel_time * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite_tween.tween_property(sprite, "position", _base_sprite_pos, travel_time * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sprite_tween.tween_property(sprite, "position", bounce_apex, travel_time * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite_tween.tween_property(sprite, "position", _base_sprite_pos, travel_time * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var shadow_tween := create_tween()
	shadow_tween.tween_property(shadow, "scale", _base_shadow_scale * 0.7, travel_time * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	shadow_tween.tween_property(shadow, "scale", _base_shadow_scale, travel_time * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	shadow_tween.tween_property(shadow, "scale", _base_shadow_scale * 0.85, travel_time * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	shadow_tween.tween_property(shadow, "scale", _base_shadow_scale, travel_time * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

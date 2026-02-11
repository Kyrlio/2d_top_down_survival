extends Area2D

@export var slot_data: SlotData

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _base_sprite_pos: Vector2
var _base_shadow_scale: Vector2

var height: float = 0.0
var z_velocity: float = 0.0
var ground_velocity: Vector2 = Vector2.ZERO
var bounce_damp: float = 0.6
var friction: float = 2.0
var gravity2: float = 980.0

var is_bouncing: bool = false

func _ready() -> void:
	sprite.texture = slot_data.item_data.texture
	_base_sprite_pos = sprite.position
	_base_shadow_scale = shadow.scale


func _process(delta: float) -> void:
	if not is_bouncing:
		return
	
	# Height simulator
	z_velocity -= gravity2 * delta
	height += z_velocity * delta
	
	# Ground bounce
	if height <= 0.0:
		height = 0.0
		# Inverse velocity (bounce)
		z_velocity = -z_velocity * bounce_damp
		
		# Stop if bounce too small
		if z_velocity < 50.0:
			z_velocity = 0
			is_bouncing = false
			ground_velocity = Vector2.ZERO
	
	# Ground movements
	# Friction
	if is_bouncing and height <= 0.0:
		pass
	
	# Check walls
	if ground_velocity != Vector2.ZERO:
		var motion = ground_velocity * delta
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + motion, 4)
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(query)
		
		if result:
			ground_velocity = Vector2.ZERO
		else:
			global_position += motion
	
	# Visualsht
	sprite.position.y = _base_sprite_pos.y - height


func launch(direction: Vector2, speed: float, initial_height: float = 20.0) -> void:
	ground_velocity = direction * speed
	height = initial_height
	z_velocity = 150.0
	is_bouncing = true


func _on_area_entered(area: Area2D) -> void:
	# Vérifier que l'owner a un inventory_data
	if not area.owner or not "inventory_data" in area.owner:
		return
	
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


func _on_timer_timeout() -> void:
	collision_shape.disabled = false
	animation_player.play("idle")

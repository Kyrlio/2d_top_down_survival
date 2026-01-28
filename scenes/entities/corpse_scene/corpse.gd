extends RigidBody2D

@export var corpse_sprite: CompressedTexture2D
@export var push_impulse: float = 50
@export var use_player_velocity: bool = true

@onready var sprite: Sprite2D = $Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if corpse_sprite != null:
		sprite.texture = corpse_sprite
	contact_monitor = true
	max_contacts_reported = 4
	if has_signal("body_entered"):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		body = body as CharacterBody2D
		var impulse: Vector2 = Vector2.ZERO
		if use_player_velocity:
			var vel: Vector2 = body.velocity
			if vel.length() > 0.0:
				impulse = vel.normalized() * push_impulse
			if impulse == Vector2.ZERO:
				var dir: Vector2 = (global_position - body.global_position).normalized()
				impulse = dir * push_impulse
			apply_impulse(impulse)

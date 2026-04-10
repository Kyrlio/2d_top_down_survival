class_name EnemyProjectile extends Area2D

@export var speed: float = 75.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

@onready var hit_area: HitArea2D = $HitArea2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.rotation = direction.angle()
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	if hit_area:
		hit_area.set_damage(damage)
		hit_area.enabled(true)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_area_entered(_area: Area2D) -> void:
	queue_free.call_deferred()

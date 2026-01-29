@icon("uid://cd083uunbism8")
class_name Sword extends Node2D

@export var slash3_dash_speed: int = 600

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hit_area: HitArea2D = $Sprite/HitArea2D
@onready var combo_timer: Timer = $ComboTimer
@onready var cooldown_timer: Timer = $CooldownTimer

var combo_stage: int = 0
var wielder: CharacterBody2D


func setup(new_wielder: CharacterBody2D) -> void:
	wielder = new_wielder


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slash":
		animation_player.play("sword_return")


func slash3_dash() -> void:
	if not wielder:
		return
	
	var direction = Vector2.RIGHT
	
	if wielder.has_method("get_effective_aim"):
		direction = wielder.get_effective_aim()
	else:
		direction = wielder.velocity.normalized()
	
	wielder.velocity = direction * slash3_dash_speed
	wielder.move_and_slide()


func set_damage(amount: int) -> void:
	hit_area.set_damage(amount)
	
	
func add_damage(amount: int) -> void:
	hit_area.damage += amount

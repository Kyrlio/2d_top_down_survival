@icon("uid://cd083uunbism8")
class_name Sword extends Node2D

@export var slash3_dash_speed: int = 600
@export var attack_speed: float = 1.0:
	set(value):
		attack_speed = max(0.1, value)
		_apply_attack_speed()

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hit_area: HitArea2D = $Sprite/HitArea2D
@onready var combo_timer: Timer = $ComboTimer
@onready var cooldown_timer: Timer = $CooldownTimer

var combo_stage: int = 0
var wielder: CharacterBody2D
var base_cooldown: float = 0.7
var base_combo_time: float = 0.15


func _ready() -> void:
	if cooldown_timer:
		base_cooldown = cooldown_timer.wait_time
	if combo_timer:
		base_combo_time = combo_timer.wait_time
	_apply_attack_speed()


func _apply_attack_speed() -> void:
	if not is_node_ready() or not animation_player:
		return
	animation_player.speed_scale = attack_speed
	cooldown_timer.wait_time = base_cooldown / attack_speed
	combo_timer.wait_time = base_combo_time / attack_speed


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

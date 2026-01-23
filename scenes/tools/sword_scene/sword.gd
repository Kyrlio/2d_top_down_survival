@icon("uid://cd083uunbism8")
class_name Sword extends Node2D

@export var slash3_dash_speed: int = 600

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hit_area: HitArea2D = $Sprite/HitArea2D
@onready var combo_timer: Timer = $ComboTimer
@onready var cooldown_timer: Timer = $CooldownTimer

var combo_stage: int = 0


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slash":
		animation_player.play("sword_return")


func slash3_dash() -> void:
	# Vérifier si l'attaque vient du joueur
	var node: Node2D = get_parent()
	var player_node: Player = null
	
	# On remonte la hiérarchie pour trouver le Player
	for i in range(10):
		node = node.get_parent()
		if not node:
			break
		if node is Player:
			player_node = node
			break
	
	player_node.velocity = player_node.get_effective_aim() * slash3_dash_speed
	player_node.move_and_slide()


func set_damage(amount: int) -> void:
	hit_area.set_damage(amount)
	
	
func add_damage(amount: int) -> void:
	hit_area.damage += amount

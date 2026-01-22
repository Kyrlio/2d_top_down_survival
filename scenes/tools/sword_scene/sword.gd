@icon("uid://cd083uunbism8")
class_name Sword extends Node2D

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hitbox: Area2D = $Sprite/HitArea2D
@onready var combo_timer: Timer = $ComboTimer
@onready var cooldown_timer: Timer = $CooldownTimer


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slash":
		animation_player.play("sword_return")

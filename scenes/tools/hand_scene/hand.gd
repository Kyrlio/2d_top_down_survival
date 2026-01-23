@icon("uid://coy1vju8t06bh")
class_name Hand extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var hit_area_2d: HitArea2D = $Sprite/HitArea2D

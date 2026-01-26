extends Node2D

@export var freeze_slow := 0.06
@export var freeze_time := 0.15

@onready var enemies: Node2D = %Enemies



func _ready() -> void:
	for enemy: CharacterBody2D in enemies.get_children():
		if enemy.has_signal("hit"):
			enemy.hit.connect(freeze_engine)
	var player: Player = get_tree().get_first_node_in_group("player")
	if player.has_signal("hit"):
		player.hit.connect(freeze_engine)


func freeze_engine() -> void:
	Engine.time_scale = freeze_slow
	await get_tree().create_timer(freeze_time * freeze_slow).timeout
	Engine.time_scale = 1.0

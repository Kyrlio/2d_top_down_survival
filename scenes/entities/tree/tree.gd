extends StaticBody2D

const PICK_UP = preload("uid://1atsbj7ft3su")
const WOOD_ITEM = preload("uid://duvhdbndkcyr4")
const TREE_PARTICLES = preload("uid://cix77i6se7tak")

@export var wood_drop_amount: int = 2

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals

var is_dead: bool = false


func _ready() -> void:
	add_to_group("trees")
	animation_player.play("idle")


func _process(_delta: float) -> void:
	if health_component.current_health <= 0:
		_death()


func _death() -> void:
	if health_component.current_health > 0 or is_dead:
		return
	is_dead = true
	animation_player.play("dead")
	spawn_death_particles()
	drop_wood()


func get_hit() -> void:
	if is_dead or health_component.current_health <= 0:
		return
	
	spawn_hit_particles()
	animation_player.stop()
	visuals.scale.x = PlayerManager.player.get_facing_direction()
	animation_player.play("chop")
	health_component.take_damage(1)


func spawn_hit_particles() -> void:
	var particles = TREE_PARTICLES.instantiate()
	add_child(particles)
	particles.spawn_hit_particles()


func spawn_death_particles() -> void:
	var particles = TREE_PARTICLES.instantiate()
	add_child(particles)
	particles.spawn_death_particles()


func drop_wood() -> void:
	var random_amount := wood_drop_amount + randi_range(-1, 1)
	random_amount = max(1, random_amount)
	
	var parent_node := get_parent()
	
	# Créer un pick_up individuel pour chaque morceau de bois
	for i in range(random_amount):
		# Créer le slot_data pour un seul morceau de bois
		var slot_data := SlotData.new()
		slot_data.item_data = WOOD_ITEM
		slot_data.quantity = 1
		
		# Instancier le pick_up
		var pick_up = PICK_UP.instantiate()
		pick_up.slot_data = slot_data
		pick_up.global_position = global_position
		
		parent_node.add_child(pick_up)
		
		var angle_offset := (TAU / random_amount) * i
		var random_variation := randf_range(-0.5, 0.5)
		var final_angle := angle_offset + random_variation
		var direction := Vector2(cos(final_angle), sin(final_angle))
		
		var speed := randf_range(25.0, 50.0)
		
		await get_tree().create_timer(i * 0.05).timeout
		if pick_up.has_method("launch"):
			pick_up.launch(direction, speed)


func _on_hurt_area_2d_area_entered(area: Area2D) -> void:
	if area.owner is Axe:
		get_hit()

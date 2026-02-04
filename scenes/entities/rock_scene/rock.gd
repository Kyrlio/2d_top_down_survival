extends StaticBody2D
class_name Rock

const ROCK_ITEM = preload("uid://x6vl4hk2ral7")
const COAL_ITEM = preload("uid://cqkvd8nigyuau")
const DIAMOND_ITEM = preload("uid://cpbxpf6i5mqid")
const GOLD_ITEM = preload("uid://bh6sc6jc08lts")
const IRON_ITEM = preload("uid://c7ylmq18p255n")
const PICK_UP = preload("uid://1atsbj7ft3su")
const ROCK_HIT_PARTICLES = preload("uid://dd375ap5o3gtu")


const ROCK_Y_REGION: int = 464
const IRON_Y_REGION: int = 336
const COAL_Y_REGION: int = 368
const GOLD_Y_REGION: int = 432
const DIAMOND_Y_REGION: int = 400

@export_enum("Big", "Medium", "Small") var size: String = "Big"
@export_enum("Rock", "Iron", "Coal", "Gold", "Diamond") var mineral: String = "Rock"
@export var rock_drop_amount: int = 2

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visuals: Node2D = $Visuals
@onready var small: Sprite2D = $Visuals/Small
@onready var medium: Sprite2D = $Visuals/Medium
@onready var big: Sprite2D = $Visuals/Big
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurt_area: Area2D = $HurtArea2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var region_x_size: int

func _ready() -> void:
	add_to_group("rock")
	# Dupliquer les textures pour que chaque instance soit indépendante
	big.texture = big.texture.duplicate()
	medium.texture = medium.texture.duplicate()
	small.texture = small.texture.duplicate()
	
	animation_player.play("idle")
	_update_size()
	_update_mineral()


func _update_size() -> void:
	match size:
		"Big":
			big.visible = true 
			medium.visible = false
			small.visible = false
			region_x_size = 784
		
		"Medium":
			big.visible = false 
			medium.visible = true
			small.visible = false
			region_x_size = 816
		
		"Small":
			big.visible = false 
			medium.visible = false
			small.visible = true
			region_x_size = 848


func _update_mineral() -> void:
	match mineral:
		"Rock":
			big.texture.region = Rect2(region_x_size, ROCK_Y_REGION, 32, 32)
			medium.texture.region = Rect2(region_x_size, ROCK_Y_REGION, 32, 32)
			small.texture.region = Rect2(region_x_size, ROCK_Y_REGION, 32, 32)
		
		"Iron":
			big.texture.region = Rect2(region_x_size, IRON_Y_REGION, 32, 32)
			medium.texture.region = Rect2(region_x_size, IRON_Y_REGION, 32, 32)
			small.texture.region = Rect2(region_x_size, IRON_Y_REGION, 32, 32)
		
		"Coal":
			big.texture.region = Rect2(region_x_size, COAL_Y_REGION, 32, 32)
			medium.texture.region = Rect2(region_x_size, COAL_Y_REGION, 32, 32)
			small.texture.region = Rect2(region_x_size, COAL_Y_REGION, 32, 32)
		
		"Gold":
			big.texture.region = Rect2(region_x_size, GOLD_Y_REGION, 32, 32)
			medium.texture.region = Rect2(region_x_size, GOLD_Y_REGION, 32, 32)
			small.texture.region = Rect2(region_x_size, GOLD_Y_REGION, 32, 32)
		
		"Diamond":
			big.texture.region = Rect2(region_x_size, DIAMOND_Y_REGION, 32, 32)
			medium.texture.region = Rect2(region_x_size, DIAMOND_Y_REGION, 32, 32)
			small.texture.region = Rect2(region_x_size, DIAMOND_Y_REGION, 32, 32)


func _death() -> void:
	if health_component.current_health > 0:
		return
	#spawn_death_particles()
	drop_rock.call_deferred()
	visuals.visible = false
	collision_shape.disabled = true
	hurt_area.monitoring = false
	await get_tree().create_timer(1.0).timeout
	queue_free.call_deferred()


func get_hit() -> void:
	if health_component.current_health <= 0:
		_death.call_deferred()
	if health_component.current_health == 9:
		size = "Big"
		_update_size()
		_update_mineral()
	if health_component.current_health == 6:
		size = "Medium"
		call_deferred("drop_rock")
		_update_size()
		_update_mineral()
	if health_component.current_health == 3:
		size = "Small"
		call_deferred("drop_rock")
		_update_size()
		_update_mineral()
	
	spawn_hit_particles()
	animation_player.stop()
	visuals.scale.x = PlayerManager.player.get_facing_direction()
	animation_player.play("mine")
	health_component.take_damage(1)


func spawn_hit_particles() -> void:
	var particles = ROCK_HIT_PARTICLES.instantiate()
	add_child(particles)
	particles.spawn_hit_particles()


func drop_rock() -> void:
	var parent_node := get_parent()
	var drops: Array[Resource] = []
	
	match mineral:
		"Rock":
			var random_amount := rock_drop_amount + randi_range(0, 1)
			random_amount = max(1, random_amount)
			for _i in range(random_amount):
				drops.append(ROCK_ITEM)
		"Iron":
			var iron_amount := randi_range(1, 2)
			for _i in range(iron_amount):
				drops.append(IRON_ITEM)
			drops.append(ROCK_ITEM)
		"Coal":
			var coal_amount := randi_range(1, 2)
			for _i in range(coal_amount):
				drops.append(COAL_ITEM)
			drops.append(ROCK_ITEM)
		"Gold":
			var gold_amount := randi_range(1, 2)
			for _i in range(gold_amount):
				drops.append(GOLD_ITEM)
			drops.append(ROCK_ITEM)
		"Diamond":
			var diamond_amount := randi_range(1, 2)
			for _i in range(diamond_amount):
				drops.append(DIAMOND_ITEM)
			drops.append(ROCK_ITEM)
		_:
			drops.append(ROCK_ITEM)
	
	var total_drops := drops.size()
	if total_drops <= 0:
		return
	
	# Créer un pick_up individuel pour chaque item
	for i in range(total_drops):
		var slot_data := SlotData.new()
		slot_data.item_data = drops[i]
		slot_data.quantity = 1
		
		var pick_up = PICK_UP.instantiate()
		pick_up.slot_data = slot_data
		pick_up.global_position = global_position
		
		parent_node.add_child(pick_up)
		
		var angle_offset := (TAU / total_drops) * i
		var random_variation := randf_range(-0.5, 0.5)
		var final_angle := angle_offset + random_variation
		var direction := Vector2(cos(final_angle), sin(final_angle))
		
		var speed := randf_range(25.0, 50.0)
		
		await get_tree().create_timer(i * 0.05).timeout
		if pick_up.has_method("launch"):
			pick_up.launch(direction, speed)


func _on_hurt_area_area_entered(area: Area2D) -> void:
	if area.owner is Pickaxe:
		get_hit()

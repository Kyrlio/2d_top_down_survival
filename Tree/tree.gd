extends StaticBody2D

const PICK_UP = preload("uid://1atsbj7ft3su")
const WOOD_ITEM = preload("uid://duvhdbndkcyr4")

@export var wood_drop_amount: int = 5

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component: HealthComponent = $HealthComponent
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D
@onready var visuals: Node2D = $Visuals
@onready var death_particles: GPUParticles2D = $DeathParticles

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
	death_particles.emitting = true
	drop_wood()


func get_hit() -> void:
	if is_dead or health_component.current_health <= 0:
		return
	
	if gpu_particles.emitting:
		gpu_particles.restart()
	gpu_particles.emitting = true
	print(gpu_particles.emitting)
	animation_player.stop()
	visuals.scale.x = PlayerManager.player.get_facing_direction()
	animation_player.play("chop")
	health_component.take_damage(1)


func drop_wood() -> void:
	# Quantité aléatoire basée sur wood_drop_amount
	# Si wood_drop_amount = 5, ça peut drop 4, 5 ou 6
	var random_amount := wood_drop_amount + randi_range(-1, 1)
	random_amount = max(1, random_amount)  # Au minimum 1
	
	# Trouver le nœud parent approprié (YSort ou parent direct)
	var parent_node := get_parent()
	var space_state := get_world_2d().direct_space_state
	
	# Créer un pick_up individuel pour chaque morceau de bois
	for i in range(random_amount):
		# Créer le slot_data pour un seul morceau de bois
		var slot_data := SlotData.new()
		slot_data.item_data = WOOD_ITEM
		slot_data.quantity = 1
		
		# Instancier le pick_up
		var pick_up = PICK_UP.instantiate()
		pick_up.slot_data = slot_data
		
		# Position de départ et d'arrivée avec dispersion
		var start_pos := global_position
		var drop_distance := randf_range(15.0, 30.0)  # Distance variable
		var angle_offset := (TAU / random_amount) * i  # Répartir en cercle
		var random_variation := randf_range(-0.3, 0.3)  # Variation aléatoire
		var final_angle := angle_offset + random_variation
		var target_pos := start_pos + Vector2(cos(final_angle), sin(final_angle)) * drop_distance
		
		# Vérifier s'il y a un mur entre start_pos et target_pos (Layer 3 = Environment = valeur 4)
		var query := PhysicsRayQueryParameters2D.create(start_pos, target_pos, 4)
		var result := space_state.intersect_ray(query)
		
		# Si on détecte un mur, ajuster la position pour qu'elle soit juste avant le mur
		if result:
			var collision_point: Vector2 = result.position
			var direction := start_pos.direction_to(target_pos)
			# Reculer de 8 pixels par rapport au point de collision pour éviter d'être dans le mur
			target_pos = collision_point - direction * 8.0
		
		pick_up.global_position = start_pos
		parent_node.add_child(pick_up)
		
		# Ajouter un petit délai entre chaque drop pour un effet plus naturel
		await get_tree().create_timer(i * 0.05).timeout
		
		# Jouer l'animation de drop
		if pick_up.has_method("play_drop_animation"):
			pick_up.play_drop_animation(target_pos, start_pos)


func _on_hurt_area_2d_area_entered(area: Area2D) -> void:
	if area.owner is Axe:
		get_hit()

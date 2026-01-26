@icon("uid://bkl8ritive7gb")
class_name HurtArea2D extends Area2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitorable = false


func _on_area_entered(hit_area: HitArea2D) -> void:
	if hit_area == null:
		return

	# Logic to resolve friendly fire
	var attacker_node = hit_area
	var attack_from_same_team: bool = false
	
	# We search up the tree to find the entity (Player or Enemy)
	for i in range(10):
		attacker_node = attacker_node.get_parent()
		if not attacker_node:
			break
		
		# If the attacker is the owner of this HurtBox, it's friendly fire
		if attacker_node == owner:
			attack_from_same_team = true
			break
			
	if attack_from_same_team:
		return

	if owner.has_method("take_damage"):
		if owner is Player:
			owner.take_damage(hit_area.get_damage(), 0.5)
		else:
			owner.take_damage(hit_area.get_damage())
	
	if owner.has_method("knock_back"):
		apply_knock_back(hit_area)


func apply_knock_back(hit_area: HitArea2D) -> void:
	var source_position = hit_area.global_position
		
	# Vérifier si l'attaque vient du joueur
	var node = hit_area
	var attack_from_player = false
	var player_node: Player = null
	
	# On remonte la hiérarchie pour trouver le Player
	for i in range(10):
		node = node.get_parent()
		if not node:
			break
		if node is Player:
			attack_from_player = true
			player_node = node
			break
	
	if attack_from_player and player_node:
		# Si c'est le joueur, le knockback suit la direction Player -> Souris
		var direction = (get_global_mouse_position() - player_node.global_position).normalized()
		# On place la "source" à l'opposé de la direction voulue par rapport à l'ennemi
		# Knockback va de Source vers Ennemi. Donc on veut (Ennemi - Source) = Direction
		# Source = Ennemi - Direction
		source_position = owner.global_position - direction * 100.0
		
	owner.knock_back(source_position, hit_area.knockback_power)

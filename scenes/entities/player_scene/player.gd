@icon("uid://bih7pe3f5ef4g")
class_name Player extends CharacterBody2D

enum STATE {IDLE, RUN, WALK, ROLL, JUMP, ATTACK}

const ROLL_SPEED: float = 95.0
const ROLL_TIME: float = 0.45
const ROLL_RELOAD_COST: float = 0.8
const TOOLS: Dictionary = {
	"Hand": "uid://bue34yh8nhqm3",
	"Sword": "uid://xdl4mrc4p3qy",
	"Axe": "uid://cu2m18tv3r8a",
	"Pickaxe": "uid://o11e5wuvomof"
}

const HAIRS: Dictionary = {
	"Bowl": "uid://dq368mbpuuhrw",
	"Long": "uid://dxlwp0wm0s4wi",
	"Curly": "uid://buaxhunol21f5",
	"Mop": "uid://bp3rkeywnvr05",
	"Short": "uid://byqd85x02kol0",
	"Spikey": "uid://bnw8jhm42lhvn"
}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visuals: Node2D = %Visuals
@onready var hand_pivot: Node2D = %HandPivot
@onready var tool: Node2D = %Tool
@onready var hair: Sprite2D = %Hair
@onready var running_particles: GPUParticles2D = %RunningParticles

var SPEED: float = 85.0
var current_tool: Node2D
var active_state: STATE = STATE.IDLE
var aim_vector: Vector2 = Vector2.RIGHT
var roll_dir: Vector2 = Vector2.ZERO
var roll_timer: float
var roll_reload_timer: float
var actual_tool_index: int = 0
var actual_hair_index: int = 0
var is_sprinting: bool = false
var is_walking: bool = false


func _ready() -> void:
	switch_state(STATE.IDLE)
	equip_tool(TOOLS.Hand)
	hair.texture = load(HAIRS.Bowl)


## Main processing loop for the player
func _process(delta: float) -> void:
	process_state(delta)
	update_aim_and_visuals(delta)
	update_roll_cooldown(delta)
	move_and_slide()


func _input(event: InputEvent) -> void:
	update_tools(event)
	update_hair(event)
	if event.is_action_pressed("sprint"):
		is_sprinting = true
	if event.is_action_released("sprint"):
		is_sprinting = false


func update_tools(event: InputEvent) -> void:
	if event.is_action_pressed("scroll_down"):
		actual_tool_index = (actual_tool_index + 1) % TOOLS.size()
		equip_tool(TOOLS.values()[actual_tool_index])
	if event.is_action_pressed("scroll_up"):
		actual_tool_index = (actual_tool_index - 1) % TOOLS.size()
		equip_tool(TOOLS.values()[actual_tool_index])


func equip_tool(scene_path: String) -> void:
	for child in tool.get_children():
		child.queue_free()

	var tool_scene = load(scene_path)
	if tool_scene:
		current_tool = tool_scene.instantiate()
		tool.add_child(current_tool)


func update_hair(event: InputEvent) -> void:
	if event.is_action_pressed("next_hair"):
		actual_hair_index = (actual_hair_index + 1) % HAIRS.size()
		hair.texture = load(HAIRS.values()[actual_hair_index])
	if event.is_action_pressed("previous_hair"):
		actual_hair_index = (actual_hair_index - 1) % HAIRS.size()
		hair.texture = load(HAIRS.values()[actual_hair_index])


## Switch the player to a new state
## Handles entrance logic for the new state
func switch_state(to_state: STATE) -> void:
	var previous_state: STATE = active_state
	active_state = to_state
	
	match active_state:
		STATE.IDLE:
			is_walking = false
			running_particles.emitting = false
			animation_player.play("idle")
		
		STATE.WALK:
			is_walking = true
			animation_player.play("walk")
		
		STATE.RUN:
			is_walking = false
			animation_player.play("run")
		
		STATE.ROLL:
			roll_reload_timer = ROLL_RELOAD_COST
			roll_timer = ROLL_TIME
			
			roll_dir = get_movement_vector()
			if roll_dir.length_squared() == 0:
				roll_dir = get_effective_aim()
			
			velocity = roll_dir * ROLL_SPEED
			var anim_length = animation_player.get_animation("roll").length
			animation_player.play("roll", -1, anim_length / ROLL_TIME)
		
		STATE.JUMP:
			animation_player.play("jump")
		
		STATE.ATTACK:
			SPEED = 5
			animation_player.speed_scale = 1.0
			running_particles.emitting = false
			is_walking = false
			
			animation_player.play("attack")
			current_tool.cooldown_timer.start()
			if current_tool is Sword:
				current_tool.animation_player.play("slash")
			else:
				current_tool.animation_player.play("attack")
			
			# On fixe la direction du regard et de l'attaque au début
			var mouse_pos = get_global_mouse_position()
			visuals.scale = Vector2.ONE if (mouse_pos - global_position).x >= 0 else Vector2(-1, 1)
			hand_pivot.look_at(mouse_pos)


## Process the logic for the current state every frame
## Handles transitions between states based on input and conditions
func process_state(delta: float) -> void:
	match active_state:
		STATE.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, 1 - exp(-25 * delta))
			
			if get_movement_vector() != Vector2.ZERO:
				switch_state(STATE.RUN)
			if Input.is_action_just_pressed("roll") and roll_reload_timer <= 0.0:
				switch_state(STATE.ROLL)
			if Input.is_action_just_pressed("jump"):
				switch_state(STATE.JUMP)
			if Input.is_action_pressed("attack") and current_tool.cooldown_timer.is_stopped():
				switch_state(STATE.ATTACK)
		
		STATE.RUN, STATE.WALK:
			if is_sprinting:
				running_particles.emitting = true
				SPEED = 125.0
				animation_player.speed_scale = 1.3
			elif is_walking:
				running_particles.emitting = false
				animation_player.speed_scale = 0.9
				SPEED = 50.0
			else:
				running_particles.emitting = false
				animation_player.speed_scale = 1
				SPEED = 85.0
			
			var target_velocity = get_movement_vector() * SPEED
			velocity = velocity.lerp(target_velocity, 1 - exp(-25 * delta))
			
			if is_equal_approx(get_movement_vector().length_squared(), 0):
				switch_state(STATE.IDLE)
			if Input.is_action_just_pressed("roll") and roll_reload_timer <= 0.0:
				switch_state(STATE.ROLL)
			if Input.is_action_just_pressed("jump"):
				switch_state(STATE.JUMP)
			if Input.is_action_pressed("attack") and current_tool.cooldown_timer.is_stopped():
				switch_state(STATE.ATTACK)
			if Input.is_action_pressed("walk"):
				switch_state(STATE.WALK)
			if Input.is_action_just_released("walk"):
				switch_state(STATE.RUN)
		
		STATE.ROLL:
			if roll_timer > 0.0:
				roll_timer -= delta
				velocity = roll_dir * ROLL_SPEED
				move_and_slide()
			else: # Roll end
				if get_movement_vector().length_squared() > 0:
					switch_state(STATE.RUN)
				else:
					switch_state(STATE.IDLE)
		
		STATE.JUMP:
			await animation_player.animation_finished
			switch_state(STATE.IDLE)
		
		STATE.ATTACK:
			if current_tool is Sword:
				if not current_tool.combo_timer.is_stopped() and Input.is_action_pressed("attack"):
					#current_tool.animation_player.stop()
					current_tool.animation_player.play("slash2")
			
			if not animation_player.is_playing():
				if get_movement_vector() != Vector2.ZERO:
					switch_state(STATE.RUN)
				else:
					switch_state(STATE.IDLE)
			
			var target_velocity = get_movement_vector() * SPEED
			velocity = velocity.lerp(target_velocity, 1 - exp(-25 * delta))


## Update the player's aiming direction and visual orientation (flip)
func update_aim_and_visuals(delta: float) -> void:
	# On ne met pas à jour la direction pendant l'attaque (on lock la visée)
	if active_state == STATE.ATTACK:
		return

	var aim_vec: Vector2 = get_effective_aim()
	visuals.scale = Vector2.ONE if aim_vec.x >= 0 else Vector2(-1, 1)
	
	hand_pivot.rotation = lerp_angle(hand_pivot.rotation, 0.0, 25 * delta)


## Calculate the effective aiming direction based on mouse position
## Returns a normalized Vector2 pointing towards the mouse
func get_effective_aim() -> Vector2:
	var effective_aim: Vector2 = aim_vector
	var mouse_position := get_global_mouse_position()
	effective_aim = global_position.direction_to(mouse_position)
	
	if effective_aim.length_squared() < 0.0001:
		effective_aim = Vector2.RIGHT
	
	return effective_aim.normalized()


## Decrease the roll cooldown timer
func update_roll_cooldown(delta) -> void:
	if roll_reload_timer > 0.0:
		roll_reload_timer -= delta


# ---------------------------- GETTERS ----------------------------

## Get the movement input vector from player controls
## Returns a normalized Vector2 representing input direction
func get_movement_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Get the current facing direction of the player visuals
## Returns 1.0 for right, -1.0 for left
func get_facing_direction():
	return visuals.scale.x

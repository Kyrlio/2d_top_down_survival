@icon("uid://bih7pe3f5ef4g")
class_name Player
extends CharacterBody2D

enum STATE {IDLE, RUN, ROLL}

const SPEED: float = 85.0
const ROLL_SPEED: float = 95.0
const ROLL_TIME: float = 0.45
const ROLL_RELOAD_COST: float = 0.8
const TOOLS: Array[String] = ["uid://ion4fpq1baa2", "uid://coh1chcl1j7qk", "uid://c24jmm17ykbk4", "uid://cs646keppvhr2"]


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visuals: Node2D = $Visuals
@onready var tool: Sprite2D = %Tool

var active_state: STATE = STATE.IDLE
var aim_vector: Vector2 = Vector2.RIGHT
var roll_dir: Vector2 = Vector2.ZERO
var roll_timer: float
var roll_reload_timer: float
var actual_tool_index: int = 0


func _ready() -> void:
	switch_state(STATE.IDLE)
	tool.texture = load(TOOLS[actual_tool_index])


## Main processing loop for the player
func _process(delta: float) -> void:
	process_state(delta)
	update_aim_and_visuals()
	update_roll_cooldown(delta)
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scroll_down"):
		actual_tool_index = (actual_tool_index + 1) % TOOLS.size()
		tool.texture = load(TOOLS[actual_tool_index])
	elif event.is_action_pressed("scroll_up"):
		actual_tool_index = (actual_tool_index - 1) % TOOLS.size()
		tool.texture = load(TOOLS[actual_tool_index])


## Switch the player to a new state
## Handles entrance logic for the new state
func switch_state(to_state: STATE) -> void:
	var previous_state: STATE = active_state
	active_state = to_state
	
	match active_state:
		STATE.IDLE:
			animation_player.play("idle")
		
		STATE.RUN:
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
		
		STATE.RUN:
			var target_velocity = get_movement_vector() * SPEED
			velocity = velocity.lerp(target_velocity, 1 - exp(-25 * delta))
			
			if is_equal_approx(get_movement_vector().length_squared(), 0):
				switch_state(STATE.IDLE)
			if Input.is_action_just_pressed("roll") and roll_reload_timer <= 0.0:
				switch_state(STATE.ROLL)
		
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


## Update the player's aiming direction and visual orientation (flip)
func update_aim_and_visuals() -> void:
	var aim_vec: Vector2 = get_effective_aim()
	visuals.scale = Vector2.ONE if aim_vec.x >= 0 else Vector2(-1, 1)


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

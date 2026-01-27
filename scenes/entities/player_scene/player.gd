@icon("uid://bih7pe3f5ef4g")
class_name Player extends CharacterBody2D

signal hit

enum STATE {
	IDLE,
	RUN,
	WALK,
	ROLL,
	ATTACK,
	PARRY,
	HURT
}

const ROLL_SPEED: float = 95.0
const ROLL_TIME: float = 0.3
const ROLL_RELOAD_COST: float = 0.8

# Movement Settings
const SPEED_WALK: float = 50.0
const SPEED_RUN: float = 85.0
const SPEED_SPRINT: float = 125.0
const SPEED_ATTACK: float = 8.0
const TOOL_SWITCH_COOLDOWN: float = 0.075


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
@onready var hit_gpu_particles: GPUParticles2D = %HitGPUParticles

var pushback_force: Vector2 = Vector2.ZERO

var speed: float = SPEED_RUN
var current_tool: Node2D
var active_state: STATE = STATE.IDLE
var aim_vector: Vector2 = Vector2.RIGHT
var roll_dir: Vector2 = Vector2.ZERO
var roll_timer: float
var roll_reload_timer: float
var tool_switch_timer: float = 0.0
var actual_tool_index: int = 0
var actual_hair_index: int = 0
var is_sprinting: bool = false
var is_walking: bool = false
var can_take_damage: bool = true

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player")
	hair.texture = load(HAIRS.Bowl)
	equip_tool(TOOLS.Hand)
	switch_state(STATE.IDLE)


## Main processing loop for the player (Physics synchronized)
func _process(delta: float) -> void:
	process_state(delta)
	update_aim_and_visuals(delta)
	update_roll_cooldown(delta)
	update_tool_switch_timer(delta)

	move_and_slide()


## Processes input events, such as tool switching and hair changing.
func _input(event: InputEvent) -> void:
	update_tools(event)
	update_hair(event)
	if event.is_action_pressed("sprint"):
		is_sprinting = true
	if event.is_action_released("sprint"):
		is_sprinting = false


## Updates the current tool based on scroll input.
func update_tools(event: InputEvent) -> void:
	if tool_switch_timer > 0.0:
		return

	if event.is_action_pressed("scroll_down"):
		actual_tool_index = (actual_tool_index + 1) % TOOLS.size()
		equip_tool(TOOLS.values()[actual_tool_index])
		tool_switch_timer = TOOL_SWITCH_COOLDOWN
	elif event.is_action_pressed("scroll_up"):
		actual_tool_index = (actual_tool_index - 1) % TOOLS.size()
		equip_tool(TOOLS.values()[actual_tool_index])
		tool_switch_timer = TOOL_SWITCH_COOLDOWN


## Instantiates and equips a tool from the given scene path.
func equip_tool(scene_path: String) -> void:
	for child in tool.get_children():
		child.queue_free()

	var tool_scene = load(scene_path)
	if tool_scene:
		current_tool = tool_scene.instantiate()
		tool.add_child(current_tool)


## Updates the current hair style based on input.
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
	# var _previous_state: STATE = active_state # Unused
	active_state = to_state
	
	match active_state:
		STATE.IDLE: _enter_state_idle()
		STATE.WALK: _enter_state_walk()
		STATE.RUN: _enter_state_run()
		STATE.ROLL: _enter_state_roll()
		STATE.ATTACK: _enter_state_attack()
		STATE.PARRY: _enter_state_parry()
		STATE.HURT: _enter_stater_hurt()


## Process the logic for the current state every frame
## Handles transitions between states based on input and conditions
func process_state(delta: float) -> void:
	match active_state:
		STATE.IDLE: _update_state_idle(delta)
		STATE.RUN, STATE.WALK: _update_state_move(delta)
		STATE.ROLL: _update_state_roll(delta)
		STATE.ATTACK: _update_state_attack(delta)
		STATE.PARRY: _update_state_parry(delta)
		STATE.HURT: _update_state_hurt(delta)


func take_damage(amount: int, invincible_time: float = 0.0, ignore_invincible: bool = false) -> void:
	if active_state == STATE.ROLL:
		return
	if not can_take_damage and not ignore_invincible:
		return
	switch_state(STATE.HURT)
	if invincible_time > 0.0:
		can_take_damage = false
		await get_tree().create_timer(0.2).timeout
		var invincible_tween := get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		invincible_tween.tween_property(visuals, "modulate:a", 1.0, invincible_time / 4.0)
		invincible_tween.chain().tween_property(visuals, "modulate:a", 0.5, invincible_time / 4.0)
		invincible_tween.chain().chain().tween_property(visuals, "modulate:a", 1.0, invincible_time / 4.0)
		invincible_tween.chain().chain().chain().tween_property(visuals, "modulate:a", 0.5, invincible_time / 4.0)
		invincible_tween.chain().chain().chain().chain().tween_property(visuals, "modulate:a", 1.0, invincible_time / 4.0).finished.connect(
			_reset_can_take_damage)


func _reset_can_take_damage() -> void:
	can_take_damage = true


func knock_back(source_position: Vector2, power: float = 1.0) -> void:
	if active_state == STATE.ROLL:
		return
	hit_gpu_particles.rotation = get_angle_to(source_position) + PI
	hit_gpu_particles.emitting = true
	var knockback_strength = 200.0 * power
	pushback_force = - global_position.direction_to(source_position) * knockback_strength


# ---------------------------- STATE ENTRY LOGIC ----------------------------------------------------------------------------------------------

## Handles logic when entering the IDLE state.
func _enter_state_idle() -> void:
	is_walking = false
	running_particles.emitting = false
	animation_player.play("idle")


## Handles logic when entering the WALK state.
func _enter_state_walk() -> void:
	speed = SPEED_WALK
	is_walking = true
	animation_player.play("walk")


## Handles logic when entering the RUN state.
func _enter_state_run() -> void:
	speed = SPEED_RUN
	is_walking = false
	animation_player.play("run")


## Handles logic when entering the ROLL state.
func _enter_state_roll() -> void:
	roll_reload_timer = ROLL_RELOAD_COST
	roll_timer = ROLL_TIME
	
	roll_dir = get_movement_vector()
	if roll_dir.length_squared() == 0:
		roll_dir = get_effective_aim()
	
	velocity = roll_dir * ROLL_SPEED
	var anim_length = animation_player.get_animation("roll").length
	animation_player.play("roll", -1, anim_length / ROLL_TIME)


## Handles logic when entering the ATTACK state.
func _enter_state_attack() -> void:
	speed = SPEED_ATTACK
	animation_player.speed_scale = 1.0
	running_particles.emitting = false
	is_walking = false
	
	animation_player.play("attack")
	current_tool.cooldown_timer.stop()
	current_tool.cooldown_timer.start()
	
	if current_tool is Sword:
		current_tool.combo_stage = 1
		current_tool.hit_area.knockback_power = 1.0
		current_tool.animation_player.play("slash")
	else:
		current_tool.animation_player.play("attack")
	
	# Lock aim direction and update visuals
	var mouse_pos = get_global_mouse_position()
	update_facing_direction()
	hand_pivot.look_at(mouse_pos)


func _enter_state_parry() -> void:
	speed = SPEED_ATTACK
	if current_tool is Sword:
		current_tool.animation_player.play("parry")


func _enter_stater_hurt() -> void:
	speed = SPEED_WALK
	animation_player.play("hit")
	GameCamera.shake(2)
	hit.emit()
	

# ---------------------------- STATE UPDATE LOGIC ----------------------------------------------------------------------------------------------

## Updates logic for the IDLE state.
func _update_state_idle(delta: float) -> void:
	velocity = velocity.lerp(Vector2.ZERO, 1 - exp(-25 * delta))
	
	if get_movement_vector() != Vector2.ZERO:
		switch_state(STATE.RUN)
	
	_check_common_state_transitions()


## Updates logic for RUN and WALK states.
func _update_state_move(delta: float) -> void:
	if is_sprinting:
		running_particles.emitting = true
		speed = SPEED_SPRINT
		animation_player.speed_scale = 1.3
	elif is_walking:
		running_particles.emitting = false
		animation_player.speed_scale = 0.9
		speed = SPEED_WALK
	else:
		running_particles.emitting = false
		animation_player.speed_scale = 1
		speed = SPEED_RUN
	
	var target_velocity = get_movement_vector() * speed
	velocity = velocity.lerp(target_velocity, 1 - exp(-25 * delta))
	
	if is_equal_approx(get_movement_vector().length_squared(), 0):
		switch_state(STATE.IDLE)
	
	if Input.is_action_pressed("walk") and active_state == STATE.RUN:
		switch_state(STATE.WALK)
	if Input.is_action_just_released("walk") and active_state == STATE.WALK:
		switch_state(STATE.RUN)

	_check_common_state_transitions()


## Updates logic for the ROLL state.
func _update_state_roll(_delta: float) -> void:
	if roll_timer > 0.0:
		roll_timer -= _delta
		velocity = roll_dir * ROLL_SPEED
		move_and_slide()
	else:
		if get_movement_vector().length_squared() > 0:
			switch_state(STATE.RUN)
		else:
			switch_state(STATE.IDLE)


func _update_state_parry(_delta) -> void:
	if Input.is_action_just_released("parry"):
		switch_state(STATE.IDLE)


## Updates logic for the ATTACK state.
func _update_state_attack(delta: float) -> void:
	_handle_attack_combo()
	
	if not animation_player.is_playing():
		if get_movement_vector() != Vector2.ZERO:
			switch_state(STATE.RUN)
		else:
			switch_state(STATE.IDLE)
	
	var target_velocity = get_movement_vector() * speed
	velocity = velocity.lerp(target_velocity, 1 - exp(-25 * delta))


func _update_state_hurt(delta) -> void:
	pushback_force = pushback_force.lerp(Vector2.ZERO, delta * 10.0)
	velocity = pushback_force
	
	if not animation_player.is_playing():
		switch_state(STATE.IDLE)

# ------------------------------------------------------------------------------------------------------------------------------------------------

## Handles the attack combo logic for weapons that support it (e.g., Sword).
func _handle_attack_combo() -> void:
	if current_tool is Sword:
		if not current_tool.combo_timer.is_stopped() and Input.is_action_pressed("attack"):
			if current_tool.combo_stage == 1:
				_trigger_combo_stage(2, "slash2", "attack_2")
			elif current_tool.combo_stage == 2:
				_trigger_combo_stage(3, "slash3", "attack_3")


## Triggers a specific combo stage animation.
func _trigger_combo_stage(stage: int, tool_anim: String, player_anim: String) -> void:
	current_tool.cooldown_timer.stop()
	current_tool.cooldown_timer.start()
	current_tool.combo_timer.stop()
	current_tool.combo_stage = stage
	
	if stage == 3:
		current_tool.hit_area.knockback_power = 5
	else:
		current_tool.hit_area.knockback_power = 1.0
	
	if stage == 3:
		current_tool.animation_player.stop()
	
	var mouse_pos = get_global_mouse_position()
	update_facing_direction()
	hand_pivot.look_at(mouse_pos)

	current_tool.animation_player.play(tool_anim)
	animation_player.play(player_anim)


## Common transitions checked in Idle and Move states (Roll, Jump, Attack)
func _check_common_state_transitions() -> void:
	if Input.is_action_just_pressed("roll") and roll_reload_timer <= 0.0:
		switch_state(STATE.ROLL)
	if Input.is_action_pressed("attack") and current_tool.cooldown_timer.is_stopped():
		switch_state(STATE.ATTACK)
	if Input.is_action_pressed("parry"):
		switch_state(STATE.PARRY)


## Update the player's aiming direction and visual orientation (flip)
func update_aim_and_visuals(delta: float) -> void:
	# On ne met pas à jour la direction pendant l'attaque (on lock la visée)
	if active_state == STATE.ATTACK:
		return

	var aim_vec: Vector2 = get_effective_aim()
	visuals.scale = Vector2.ONE if aim_vec.x >= 0 else Vector2(-1, 1)
	
	hand_pivot.rotation = lerp_angle(hand_pivot.rotation, 0.0, 25 * delta)


func update_facing_direction() -> void:
	var mouse_pos = get_global_mouse_position()
	visuals.scale = Vector2.ONE if (mouse_pos - global_position).x >= 0 else Vector2(-1, 1)


## Decrease the roll cooldown timer
func update_roll_cooldown(delta) -> void:
	if roll_reload_timer > 0.0:
		roll_reload_timer -= delta


## Decrease the tool switch cooldown timer
func update_tool_switch_timer(delta: float) -> void:
	if tool_switch_timer > 0.0:
		tool_switch_timer -= delta


# ---------------------------- GETTERS ----------------------------

## Get the movement input vector from player controls
## Returns a normalized Vector2 representing input direction
func get_movement_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Get the current facing direction of the player visuals
## Returns 1.0 for right, -1.0 for left
func get_facing_direction():
	return visuals.scale.x


## Calculate the effective aiming direction based on mouse position
## Returns a normalized Vector2 pointing towards the mouse
func get_effective_aim() -> Vector2:
	var effective_aim: Vector2 = aim_vector
	var mouse_position := get_global_mouse_position()
	effective_aim = global_position.direction_to(mouse_position)
	
	if effective_aim.length_squared() < 0.0001:
		effective_aim = Vector2.RIGHT
	
	return effective_aim.normalized()

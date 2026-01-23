@icon("uid://47471th1ui0o")
class_name Enemy extends CharacterBody2D

signal hit

enum STATE {IDLE, HURT}

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var hp_progress_bar: ProgressBar = %HPProgressBar
@onready var hit_gpu_particles: GPUParticles2D = %HitGPUParticles

var active_state: STATE = STATE.IDLE
var pushback_force: Vector2 = Vector2.ZERO


func _ready() -> void:
	switch_state(STATE.IDLE)


func _process(delta: float) -> void:
	process_state(delta)
	
	pushback_force = lerp(pushback_force, Vector2.ZERO, delta * 10.0)
	velocity = pushback_force
	
	move_and_slide()


func switch_state(to_state: STATE) -> void:
	var previous_state := active_state
	active_state = to_state
	
	match active_state:
		STATE.IDLE:
			animation_player.play("idle")
		
		STATE.HURT:
			if animation_player.is_playing():
				animation_player.stop()
			animation_player.play("hit")
			GameCamera.shake(1)
			


func process_state(delta: float) -> void:
	match active_state:
		STATE.IDLE:
			pass
		
		STATE.HURT:
			if not animation_player.is_playing():
				switch_state(STATE.IDLE)


func take_damage(amount: int) -> void:
	switch_state(STATE.HURT)
	hp_progress_bar.value = max(0, hp_progress_bar.value - amount)
	hit.emit()
	if hp_progress_bar.value == 0:
		queue_free()


func knock_back(source_position: Vector2) -> void:
	hit_gpu_particles.rotation = get_angle_to(source_position) + PI
	pushback_force = -global_position.direction_to(source_position) * 100

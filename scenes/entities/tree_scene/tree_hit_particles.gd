extends Node2D

@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var death_particles: GPUParticles2D = $DeathParticles


func spawn_hit_particles() -> void:
	hit_particles.emitting = true


func spawn_death_particles() -> void:
	death_particles.emitting = true

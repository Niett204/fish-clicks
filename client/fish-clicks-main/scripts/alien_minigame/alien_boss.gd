extends Node2D

@export var idle_texture: Texture2D
@export var gun_texture: Texture2D
@export var worm_release_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var antenna_glow_left_sprite: Sprite2D = $AntennaGlowLeftSprite
@onready var antenna_glow_right_sprite: Sprite2D = $AntennaGlowRightSprite
@onready var laser_spawn: Marker2D = $LaserSpawn

var antenna_base_color: Color = Color(0.6, 1.0, 0.5, 1.0)
var antenna_pulse_speed: float = 0.008
var antenna_pulse_min_alpha: float = 0.35
var antenna_pulse_max_alpha: float = 0.85
var antenna_glow_enabled: bool = true

func _process(_delta: float) -> void:
	if not antenna_glow_enabled:
		return

	var pulse_t: float = Time.get_ticks_msec() * antenna_pulse_speed
	var pulse: float = 0.5 + 0.5 * sin(pulse_t)
	var alpha: float = lerp(antenna_pulse_min_alpha, antenna_pulse_max_alpha, pulse)

	if is_instance_valid(antenna_glow_left_sprite):
		antenna_glow_left_sprite.modulate = Color(
			antenna_base_color.r,
			antenna_base_color.g,
			antenna_base_color.b,
			alpha
		)

	if is_instance_valid(antenna_glow_right_sprite):
		antenna_glow_right_sprite.modulate = Color(
			antenna_base_color.r,
			antenna_base_color.g,
			antenna_base_color.b,
			alpha
		)

func set_antenna_color(color: Color) -> void:
	antenna_base_color = color

	if is_instance_valid(antenna_glow_left_sprite):
		antenna_glow_left_sprite.modulate = Color(
			color.r,
			color.g,
			color.b,
			antenna_glow_left_sprite.modulate.a
		)

	if is_instance_valid(antenna_glow_right_sprite):
		antenna_glow_right_sprite.modulate = Color(
			color.r,
			color.g,
			color.b,
			antenna_glow_right_sprite.modulate.a
		)

func set_antenna_phase_visual(phase: int) -> void:
	match phase:
		1:
			set_antenna_color(Color(0.4, 1.0, 0.35, 1.0))
			antenna_pulse_speed = 0.006
			antenna_pulse_min_alpha = 0.30
			antenna_pulse_max_alpha = 0.70
		2:
			set_antenna_color(Color(1.0, 0.88, 0.2, 1.0))
			antenna_pulse_speed = 0.010
			antenna_pulse_min_alpha = 0.40
			antenna_pulse_max_alpha = 0.90
		3:
			set_antenna_color(Color(1.0, 0.2, 0.2, 1.0))
			antenna_pulse_speed = 0.016
			antenna_pulse_min_alpha = 0.50
			antenna_pulse_max_alpha = 1.0

func _set_particles_color(particles: GPUParticles2D, color: Color) -> void:
	if particles == null:
		return

	var mat := particles.process_material as ParticleProcessMaterial
	if mat == null:
		return

	mat.color = color

func set_idle_pose() -> void:
	if idle_texture != null:
		sprite.texture = idle_texture

func set_gun_pose() -> void:
	if gun_texture != null:
		sprite.texture = gun_texture

func get_laser_spawn_position() -> Vector2:
	return laser_spawn.global_position


func set_worm_release_pose() -> void:
	if sprite != null and worm_release_texture != null:
		sprite.texture = worm_release_texture


func flash_attack_pose() -> void:
	modulate = Color(1, 1, 1, 1)
	var t := create_tween()
	t.tween_property(self, "modulate", Color(0.7, 1.0, 0.7, 1), 0.1)
	t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

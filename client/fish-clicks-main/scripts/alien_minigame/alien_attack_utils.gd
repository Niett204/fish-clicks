extends Node
class_name AlienAttackUtils

var main: Node2D = null

func setup(main_ref: Node2D) -> void:
	main = main_ref

func get_boss_safe_rect() -> Rect2:
	var center: Vector2 = main.alien.global_position
	var size: Vector2 = Vector2(260.0, 180.0)
	return Rect2(center - size * 0.5, size)

func is_pos_inside_boss_safe_rect(pos: Vector2) -> bool:
	return get_boss_safe_rect().has_point(pos)

func adjust_gun_spawn_pos(pos: Vector2) -> Vector2:
	var final_pos: Vector2 = pos
	var safe_rect: Rect2 = get_boss_safe_rect().grow(70.0)

	if safe_rect.has_point(final_pos):
		final_pos.y = safe_rect.position.y - 80.0

	return final_pos

func prepare_alien_attack() -> Vector2:
	if main.alien.has_method("set_gun_pose"):
		main.alien.set_gun_pose()

	if main.alien.has_method("flash_attack_pose"):
		main.alien.flash_attack_pose()

	return main.alien.get_laser_spawn_position()

func finish_alien_attack() -> void:
	if main.alien.has_method("set_idle_pose"):
		main.alien.set_idle_pose()

func spawn_laser(origin: Vector2, direction: Vector2, custom_speed: float = -1.0) -> Node:
	if main.laser_scene == null:
		return null

	var laser: Node = main.laser_scene.instantiate()
	main.attacks.add_child(laser)

	if laser.has_method("setup"):
		laser.setup(origin, direction, custom_speed)

	return laser

func spawn_floating_gun(pos: Vector2, aim_target: Vector2) -> Node2D:
	if main.floating_gun_scene == null:
		return null

	var final_pos: Vector2 = adjust_gun_spawn_pos(pos)

	var gun: Node2D = main.floating_gun_scene.instantiate()
	main.summons.add_child(gun)
	gun.global_position = final_pos

	if gun.has_method("aim_towards"):
		gun.aim_towards(aim_target)

	if gun.has_method("appear"):
		gun.appear()

	return gun

func remove_floating_gun(gun: Node2D) -> void:
	if gun == null or not is_instance_valid(gun):
		return

	if gun.has_method("disappear"):
		await gun.disappear()
	else:
		gun.queue_free()

func aim_gun_at_target(gun: Node2D, target: Vector2) -> Vector2:
	var dir: Vector2 = (target - gun.global_position).normalized()

	if gun.has_method("aim_direction"):
		gun.aim_direction(dir)
	elif gun.has_method("aim_towards"):
		gun.aim_towards(target)

	return dir

func aim_gun_with_direction(gun: Node2D, dir: Vector2) -> Vector2:
	var final_dir: Vector2 = dir.normalized()

	if gun.has_method("aim_direction"):
		gun.aim_direction(final_dir)

	return final_dir

func get_left_gun_pos(y: float) -> Vector2:
	return Vector2(main.arena_rect_global.position.x - 120.0, y)

func get_right_gun_pos(y: float) -> Vector2:
	return Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x + 120.0, y)

func get_top_left_gun_pos() -> Vector2:
	return Vector2(
		main.arena_rect_global.position.x + main.arena_rect_global.size.x * 0.18,
		main.arena_rect_global.position.y - 140.0
	)

func get_top_right_gun_pos() -> Vector2:
	return Vector2(
		main.arena_rect_global.position.x + main.arena_rect_global.size.x * 0.82,
		main.arena_rect_global.position.y - 140.0
	)

func get_top_center_gun_pos() -> Vector2:
	return Vector2(
		main.arena_rect_global.get_center().x,
		main.arena_rect_global.position.y - 180.0
	)

func get_bottom_left_gun_pos() -> Vector2:
	return Vector2(
		main.arena_rect_global.position.x + main.arena_rect_global.size.x * 0.22,
		main.arena_rect_global.position.y + main.arena_rect_global.size.y + 130.0
	)

func get_bottom_right_gun_pos() -> Vector2:
	return Vector2(
		main.arena_rect_global.position.x + main.arena_rect_global.size.x * 0.78,
		main.arena_rect_global.position.y + main.arena_rect_global.size.y + 130.0
	)

func fire_gun_burst(gun: Node2D, shots: int, delay: float, base_dir: Vector2, spread_deg: float = 0.0) -> void:
	if gun == null or not is_instance_valid(gun):
		return

	for i in range(shots):
		var dir: Vector2 = base_dir

		if spread_deg != 0.0:
			dir = dir.rotated(deg_to_rad(randf_range(-spread_deg, spread_deg)))

		if gun.has_method("aim_direction"):
			gun.aim_direction(dir)

		spawn_laser(gun.get_muzzle_position(), dir)
		await main.get_tree().create_timer(delay).timeout

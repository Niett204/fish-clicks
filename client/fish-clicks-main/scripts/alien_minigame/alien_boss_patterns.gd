extends Node
class_name AlienBossPatterns

var main: Node2D = null
var utils: AlienAttackUtils = null
var active_tracking_guns: int = 0

func setup(main_ref: Node2D, utils_ref: AlienAttackUtils) -> void:
	main = main_ref
	utils = utils_ref


# =========================================================
# BOSS PURO
# =========================================================

func alien_fire_laser_aimed() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.28).timeout

	var to_player: Vector2 = (main.player.global_position - origin).normalized()
	utils.spawn_laser(origin, to_player)
	utils.spawn_laser(origin, to_player.rotated(deg_to_rad(-12.0)))
	utils.spawn_laser(origin, to_player.rotated(deg_to_rad(12.0)))

	await main.get_tree().create_timer(0.40).timeout
	utils.finish_alien_attack()


func alien_fire_laser_burst_aimed() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	for i in range(4):
		var to_player: Vector2 = (main.player.global_position - origin).normalized()

		utils.spawn_laser(origin, to_player)
		utils.spawn_laser(origin, to_player.rotated(deg_to_rad(-9.0)))
		utils.spawn_laser(origin, to_player.rotated(deg_to_rad(9.0)))

		await main.get_tree().create_timer(0.28).timeout

	await main.get_tree().create_timer(0.28).timeout
	utils.finish_alien_attack()


func alien_fire_double_spiral() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.20).timeout

	var waves: int = 16
	var bullets_per_wave: int = 2
	var base_angle: float = 0.0

	for i in range(waves):
		for j in range(bullets_per_wave):
			var angle1: float = base_angle + deg_to_rad(i * 18.0 + j * 180.0)
			var angle2: float = angle1 + deg_to_rad(90.0)

			var dir1: Vector2 = Vector2.RIGHT.rotated(angle1)
			var dir2: Vector2 = Vector2.RIGHT.rotated(angle2)

			if dir1.y > -0.15:
				utils.spawn_laser(origin, dir1)
			if dir2.y > -0.15:
				utils.spawn_laser(origin, dir2)

		await main.get_tree().create_timer(0.08).timeout

	await main.get_tree().create_timer(0.35).timeout
	utils.finish_alien_attack()


func alien_fire_tracking_sweep() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.22).timeout

	for burst in range(5):
		var to_player: Vector2 = (main.player.global_position - origin).normalized()

		for offset_deg: float in [-24.0, -12.0, 0.0, 12.0, 24.0]:
			utils.spawn_laser(origin, to_player.rotated(deg_to_rad(offset_deg)))

		await main.get_tree().create_timer(0.16).timeout

	await main.get_tree().create_timer(0.30).timeout
	utils.finish_alien_attack()


func alien_fire_cross_then_snipe() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var dirs_phase_1: Array[Vector2] = [
		Vector2(-0.65, 1.0),
		Vector2(-0.25, 1.0),
		Vector2(0.25, 1.0),
		Vector2(0.65, 1.0)
	]

	for dir in dirs_phase_1:
		utils.spawn_laser(origin, dir)

	await main.get_tree().create_timer(0.22).timeout

	var dirs_phase_2: Array[Vector2] = [
		Vector2(-1.0, 1.0),
		Vector2(-0.45, 1.0),
		Vector2(0.45, 1.0),
		Vector2(1.0, 1.0)
	]

	for dir in dirs_phase_2:
		utils.spawn_laser(origin, dir)

	await main.get_tree().create_timer(0.18).timeout

	var to_player: Vector2 = (main.player.global_position - origin).normalized()
	utils.spawn_laser(origin, to_player)
	utils.spawn_laser(origin, to_player.rotated(deg_to_rad(-8.0)))
	utils.spawn_laser(origin, to_player.rotated(deg_to_rad(8.0)))

	await main.get_tree().create_timer(0.35).timeout
	utils.finish_alien_attack()


func alien_fire_spiral_then_burst() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var angle: float = deg_to_rad(20.0)

	for i in range(10):
		utils.spawn_laser(origin, Vector2.RIGHT.rotated(angle))
		utils.spawn_laser(origin, Vector2.RIGHT.rotated(angle + PI))

		angle += deg_to_rad(22.0)
		await main.get_tree().create_timer(0.07).timeout

	await main.get_tree().create_timer(0.16).timeout

	var to_player: Vector2 = (main.player.global_position - origin).normalized()
	for offset: float in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		utils.spawn_laser(origin, to_player.rotated(deg_to_rad(offset)))

	await main.get_tree().create_timer(0.32).timeout
	utils.finish_alien_attack()


func alien_fire_open_close_curtain() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.22).timeout

	var shots: int = 5

	for i in range(shots):
		var to_player: Vector2 = (main.player.global_position - origin).normalized()
		utils.spawn_laser(origin, to_player)

		await main.get_tree().create_timer(0.24).timeout

	await main.get_tree().create_timer(0.30).timeout
	utils.finish_alien_attack()


func alien_fire_broken_ring_then_snipe() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var angles_deg: Array[float] = [-130.0, -110.0, -90.0, -70.0, -50.0, -30.0, -10.0, 10.0, 30.0]
	for angle_deg in angles_deg:
		var dir: Vector2 = Vector2.DOWN.rotated(deg_to_rad(angle_deg))
		if dir.y > -0.20:
			utils.spawn_laser(origin, dir)

	await main.get_tree().create_timer(0.22).timeout

	var to_player: Vector2 = (main.player.global_position - origin).normalized()
	utils.spawn_laser(origin, to_player)
	utils.spawn_laser(origin, to_player.rotated(deg_to_rad(-6.0)))
	utils.spawn_laser(origin, to_player.rotated(deg_to_rad(6.0)))

	await main.get_tree().create_timer(0.35).timeout
	utils.finish_alien_attack()


func alien_fire_counter_rotating_spirals() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var angle_a: float = deg_to_rad(-20.0)
	var angle_b: float = deg_to_rad(20.0)

	for i in range(14):
		var dir_a_1: Vector2 = Vector2.RIGHT.rotated(angle_a)
		var dir_a_2: Vector2 = Vector2.RIGHT.rotated(angle_a + PI)
		var dir_b_1: Vector2 = Vector2.RIGHT.rotated(angle_b)
		var dir_b_2: Vector2 = Vector2.RIGHT.rotated(angle_b + PI)

		if dir_a_1.y > -0.20:
			utils.spawn_laser(origin, dir_a_1)
		if dir_a_2.y > -0.20:
			utils.spawn_laser(origin, dir_a_2)
		if dir_b_1.y > -0.20:
			utils.spawn_laser(origin, dir_b_1)
		if dir_b_2.y > -0.20:
			utils.spawn_laser(origin, dir_b_2)

		angle_a += deg_to_rad(18.0)
		angle_b -= deg_to_rad(18.0)

		await main.get_tree().create_timer(0.07).timeout

	await main.get_tree().create_timer(0.35).timeout
	utils.finish_alien_attack()


func alien_fire_solar_crown() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.16).timeout

	var spread_sets: Array = [
		[-0.9, -0.6, -0.3, 0.0, 0.3, 0.6, 0.9],
		[-0.75, -0.45, -0.15, 0.15, 0.45, 0.75],
		[-0.6, -0.3, 0.0, 0.3, 0.6]
	]

	for i in range(3):
		for x in spread_sets[i]:
			utils.spawn_laser(origin, Vector2(float(x), 1.0))
		await main.get_tree().create_timer(0.12).timeout

	await main.get_tree().create_timer(0.30).timeout
	utils.finish_alien_attack()


func alien_fire_fake_gap_trap() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.20).timeout

	var first_line: Array[float] = [-0.9, -0.6, -0.3, 0.3, 0.6, 0.9]
	for x in first_line:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.18).timeout

	utils.spawn_laser(origin, Vector2(-0.12, 1.0))
	utils.spawn_laser(origin, Vector2(0.12, 1.0))

	await main.get_tree().create_timer(0.18).timeout

	var to_player: Vector2 = (main.player.global_position - origin).normalized()
	utils.spawn_laser(origin, to_player)

	await main.get_tree().create_timer(0.30).timeout
	utils.finish_alien_attack()


# =========================================================
# BOSS + GUNS
# =========================================================

func combo_boss_fan_plus_left_right_guns() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()
	var center_y: float = main.arena_rect_global.get_center().y

	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y), main.player.global_position)

	await main.get_tree().create_timer(0.22).timeout

	var boss_dirs: Array[Vector2] = [
		Vector2(-0.35, 1.0),
		Vector2(0.0, 1.0),
		Vector2(0.35, 1.0)
	]
	for dir in boss_dirs:
		utils.spawn_laser(boss_origin, dir)

	await main.get_tree().create_timer(0.12).timeout

	if left_gun != null:
		var left_dir: Vector2 = utils.aim_gun_at_target(left_gun, main.player.global_position)
		utils.spawn_laser(left_gun.get_muzzle_position(), left_dir)

	if right_gun != null:
		var right_dir: Vector2 = utils.aim_gun_at_target(right_gun, main.player.global_position)
		utils.spawn_laser(right_gun.get_muzzle_position(), right_dir)

	await main.get_tree().create_timer(0.24).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()


func combo_boss_aimed_plus_side_guns() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()
	var center_y: float = main.arena_rect_global.get_center().y

	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y - 60.0), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y - 60.0), main.player.global_position)

	await main.get_tree().create_timer(0.24).timeout

	var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
	utils.spawn_laser(boss_origin, to_player)
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(-10.0)))
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(10.0)))

	await main.get_tree().create_timer(0.08).timeout

	if left_gun != null:
		var left_dir: Vector2 = utils.aim_gun_at_target(left_gun, main.player.global_position)
		utils.spawn_laser(left_gun.get_muzzle_position(), left_dir)

	await main.get_tree().create_timer(0.08).timeout

	if right_gun != null:
		var right_dir: Vector2 = utils.aim_gun_at_target(right_gun, main.player.global_position)
		utils.spawn_laser(right_gun.get_muzzle_position(), right_dir)

	await main.get_tree().create_timer(0.24).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()


func combo_boss_burst_plus_corners() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()

	var positions: Array[Vector2] = [
		Vector2(main.arena_rect_global.position.x - 110.0, main.arena_rect_global.position.y - 90.0),
		Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x + 110.0, main.arena_rect_global.position.y - 90.0)
	]

	var guns: Array[Node2D] = []
	for pos in positions:
		if not utils.is_pos_inside_boss_safe_rect(pos):
			var gun := utils.spawn_floating_gun(pos, main.player.global_position)
			if gun != null:
				guns.append(gun)

	await main.get_tree().create_timer(0.22).timeout

	for i in range(2):
		var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
		utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(-8.0)))
		utils.spawn_laser(boss_origin, to_player)
		utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(8.0)))
		await main.get_tree().create_timer(0.14).timeout

	for gun in guns:
		var dir: Vector2 = utils.aim_gun_at_target(gun, main.player.global_position)
		utils.spawn_laser(gun.get_muzzle_position(), dir)

	await main.get_tree().create_timer(0.24).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

	utils.finish_alien_attack()


func combo_side_trap_and_center_burst() -> void:
	var center_y: float = main.arena_rect_global.get_center().y
	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y), main.player.global_position)
	var boss_origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.20).timeout

	if left_gun != null:
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, 0.10))
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, -0.10))

	if right_gun != null:
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, 0.10))
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, -0.10))

	await main.get_tree().create_timer(0.22).timeout

	var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
	for offset in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(offset)))

	await main.get_tree().create_timer(0.25).timeout

	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()


func combo_pincer_attack() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()
	var center_y: float = main.arena_rect_global.get_center().y

	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y - 80.0), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y - 80.0), main.player.global_position)

	await main.get_tree().create_timer(0.20).timeout

	for dir in [Vector2(-0.45, 1.0), Vector2(0.0, 1.0), Vector2(0.45, 1.0)]:
		utils.spawn_laser(boss_origin, dir)

	await main.get_tree().create_timer(0.12).timeout

	if left_gun != null:
		var left_dir: Vector2 = utils.aim_gun_at_target(left_gun, main.player.global_position)
		utils.spawn_laser(left_gun.get_muzzle_position(), left_dir)
		utils.spawn_laser(left_gun.get_muzzle_position(), left_dir.rotated(deg_to_rad(-12.0)))

	if right_gun != null:
		var right_dir: Vector2 = utils.aim_gun_at_target(right_gun, main.player.global_position)
		utils.spawn_laser(right_gun.get_muzzle_position(), right_dir)
		utils.spawn_laser(right_gun.get_muzzle_position(), right_dir.rotated(deg_to_rad(12.0)))

	await main.get_tree().create_timer(0.12).timeout

	var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(-14.0)))
	utils.spawn_laser(boss_origin, to_player)
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(14.0)))

	await main.get_tree().create_timer(0.25).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()


func combo_descending_pincer() -> void:
	var center: Vector2 = main.arena_rect_global.get_center()
	var center_y: float = center.y

	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y - 90.0), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y + 20.0), main.player.global_position)
	var boss_origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.20).timeout

	if left_gun != null:
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, 0.18))
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, -0.02))

	await main.get_tree().create_timer(0.10).timeout

	if right_gun != null:
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, -0.18))
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, 0.02))

	await main.get_tree().create_timer(0.12).timeout

	for dir in [Vector2(-0.25, 1.0), Vector2(0.0, 1.0), Vector2(0.25, 1.0)]:
		utils.spawn_laser(boss_origin, dir)

	await main.get_tree().create_timer(0.24).timeout

	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()


func combo_side_machinegun_and_rain() -> void:
	var center: Vector2 = main.arena_rect_global.get_center()
	var center_y: float = center.y

	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y), main.player.global_position)
	var boss_origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	for i in range(4):
		if left_gun != null:
			utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, randf_range(-0.18, 0.18)))
		if right_gun != null:
			utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, randf_range(-0.18, 0.18)))

		if i >= 1:
			for x in [-0.55, -0.25, 0.0, 0.25, 0.55]:
				utils.spawn_laser(boss_origin, Vector2(x, 1.0))

		await main.get_tree().create_timer(0.12).timeout

	await main.get_tree().create_timer(0.22).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()


# =========================================================
# ESQUINAS / CORNERS
# =========================================================

func combo_corner_collapse() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()

	var top_left: Vector2 = Vector2(main.arena_rect_global.position.x - 110.0, main.arena_rect_global.position.y - 80.0)
	var top_right: Vector2 = Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x + 110.0, main.arena_rect_global.position.y - 80.0)

	var left_gun := utils.spawn_floating_gun(top_left, main.player.global_position)
	var right_gun := utils.spawn_floating_gun(top_right, main.player.global_position)

	await main.get_tree().create_timer(0.20).timeout

	if left_gun != null:
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(0.65, 1.0))
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(0.4, 1.0))

	if right_gun != null:
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-0.65, 1.0))
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-0.4, 1.0))

	await main.get_tree().create_timer(0.20).timeout

	var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
	for offset: float in [-18.0, 0.0, 18.0]:
		utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(offset)))

	await main.get_tree().create_timer(0.25).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()

func alien_fire_supernova_bloom() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var rings: Array = [
		[-0.95, -0.65, -0.35, 0.0, 0.35, 0.65, 0.95],
		[-0.80, -0.50, -0.20, 0.20, 0.50, 0.80],
		[-0.65, -0.35, 0.0, 0.35, 0.65]
	]

	for ring in rings:
		for x in ring:
			utils.spawn_laser(origin, Vector2(float(x), 1.0))
		await main.get_tree().create_timer(0.10).timeout

	var angle: float = deg_to_rad(-25.0)
	for i in range(8):
		utils.spawn_laser(origin, Vector2.RIGHT.rotated(angle))
		utils.spawn_laser(origin, Vector2.RIGHT.rotated(angle + PI))
		angle += deg_to_rad(28.0)
		await main.get_tree().create_timer(0.06).timeout

	await main.get_tree().create_timer(0.14).timeout

	var to_player: Vector2 = (main.player.global_position - origin).normalized()
	for offset: float in [-18.0, -9.0, 0.0, 9.0, 18.0]:
		utils.spawn_laser(origin, to_player.rotated(deg_to_rad(offset)))

	await main.get_tree().create_timer(0.34).timeout
	utils.finish_alien_attack()

func combo_crown_judgement() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()
	var rect: Rect2 = main.arena_rect_global

	var positions: Array[Vector2] = [
		Vector2(rect.position.x - 110.0, rect.position.y - 90.0),
		Vector2(rect.position.x + rect.size.x * 0.25, rect.position.y - 110.0),
		Vector2(rect.position.x + rect.size.x * 0.50, rect.position.y - 120.0),
		Vector2(rect.position.x + rect.size.x * 0.75, rect.position.y - 110.0),
		Vector2(rect.position.x + rect.size.x + 110.0, rect.position.y - 90.0)
	]

	var guns: Array[Node2D] = []
	for pos in positions:
		var gun := utils.spawn_floating_gun(pos, main.player.global_position)
		if gun != null:
			guns.append(gun)

	await main.get_tree().create_timer(0.22).timeout

	for gun in guns:
		var dir: Vector2 = utils.aim_gun_at_target(gun, main.player.global_position)
		utils.spawn_laser(gun.get_muzzle_position(), dir.rotated(deg_to_rad(-10.0)))
		utils.spawn_laser(gun.get_muzzle_position(), dir)
		utils.spawn_laser(gun.get_muzzle_position(), dir.rotated(deg_to_rad(10.0)))

	await main.get_tree().create_timer(0.18).timeout

	var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
	for offset: float in [-22.0, -11.0, 0.0, 11.0, 22.0]:
		utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(offset)))

	await main.get_tree().create_timer(0.25).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

	utils.finish_alien_attack()

func alien_fire_binary_eclipse() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var angle_a: float = deg_to_rad(-35.0)
	var angle_b: float = deg_to_rad(35.0)

	for i in range(10):
		var dir_a1: Vector2 = Vector2.RIGHT.rotated(angle_a)
		var dir_a2: Vector2 = Vector2.RIGHT.rotated(angle_a + PI)
		var dir_b1: Vector2 = Vector2.RIGHT.rotated(angle_b)
		var dir_b2: Vector2 = Vector2.RIGHT.rotated(angle_b + PI)

		if dir_a1.y > -0.2:
			utils.spawn_laser(origin, dir_a1)
		if dir_a2.y > -0.2:
			utils.spawn_laser(origin, dir_a2)
		if dir_b1.y > -0.2:
			utils.spawn_laser(origin, dir_b1)
		if dir_b2.y > -0.2:
			utils.spawn_laser(origin, dir_b2)

		angle_a += deg_to_rad(24.0)
		angle_b -= deg_to_rad(24.0)

		await main.get_tree().create_timer(0.06).timeout

	await main.get_tree().create_timer(0.14).timeout

	for dir in [
		Vector2(-0.75, 1.0),
		Vector2(-0.45, 1.0),
		Vector2(-0.15, 1.0),
		Vector2(0.15, 1.0),
		Vector2(0.45, 1.0),
		Vector2(0.75, 1.0)
	]:
		utils.spawn_laser(origin, dir)

	await main.get_tree().create_timer(0.32).timeout
	utils.finish_alien_attack()

func combo_celestial_throne() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()
	var rect: Rect2 = main.arena_rect_global
	var center_y: float = rect.get_center().y

	var positions: Array[Vector2] = [
		utils.get_left_gun_pos(center_y - 40.0),
		utils.get_right_gun_pos(center_y - 40.0),
		Vector2(rect.position.x - 110.0, rect.position.y - 90.0),
		Vector2(rect.position.x + rect.size.x + 110.0, rect.position.y - 90.0)
	]

	var guns: Array[Node2D] = []
	for pos in positions:
		var gun := utils.spawn_floating_gun(pos, main.player.global_position)
		if gun != null:
			guns.append(gun)

	await main.get_tree().create_timer(0.20).timeout

	for gun in guns:
		var dir: Vector2 = utils.aim_gun_at_target(gun, main.player.global_position)
		utils.spawn_laser(gun.get_muzzle_position(), dir)

	await main.get_tree().create_timer(0.12).timeout

	var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(-18.0)))
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(-9.0)))
	utils.spawn_laser(boss_origin, to_player)
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(9.0)))
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(18.0)))

	await main.get_tree().create_timer(0.14).timeout

	for gun in guns:
		var dir2: Vector2 = utils.aim_gun_at_target(gun, main.player.global_position)
		utils.spawn_laser(gun.get_muzzle_position(), dir2.rotated(deg_to_rad(-10.0)))
		utils.spawn_laser(gun.get_muzzle_position(), dir2.rotated(deg_to_rad(10.0)))

	await main.get_tree().create_timer(0.26).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

	utils.finish_alien_attack()

func alien_fire_end_of_days() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	# Apertura amplia
	for x in [-0.95, -0.65, -0.35, 0.0, 0.35, 0.65, 0.95]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.14).timeout

	# Segunda ola intermedia
	for x in [-0.8, -0.5, -0.2, 0.2, 0.5, 0.8]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.12).timeout

	# Espiral corta
	var angle: float = deg_to_rad(-30.0)
	for i in range(6):
		utils.spawn_laser(origin, Vector2.RIGHT.rotated(angle))
		utils.spawn_laser(origin, Vector2.RIGHT.rotated(angle + PI))
		angle += deg_to_rad(30.0)
		await main.get_tree().create_timer(0.06).timeout

	await main.get_tree().create_timer(0.12).timeout

	# Juicio final dirigido
	var to_player: Vector2 = (main.player.global_position - origin).normalized()
	for offset: float in [-24.0, -12.0, 0.0, 12.0, 24.0]:
		utils.spawn_laser(origin, to_player.rotated(deg_to_rad(offset)))

	await main.get_tree().create_timer(0.35).timeout
	utils.finish_alien_attack()

func alien_fire_grid_fall() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.20).timeout

	# izquierda
	for x in [-0.75, -0.45]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.28).timeout

	# derecha
	for x in [0.45, 0.75]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.28).timeout

	# centro
	for x in [-0.15, 0.15]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.35).timeout
	utils.finish_alien_attack()

func combo_side_walls() -> void:
	var center_y: float = main.arena_rect_global.get_center().y
	var left_gun_top := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y - 90.0), main.player.global_position)
	var left_gun_bottom := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y + 90.0), main.player.global_position)
	var right_gun_top := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y - 90.0), main.player.global_position)
	var right_gun_bottom := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y + 90.0), main.player.global_position)

	await main.get_tree().create_timer(0.18).timeout

	if left_gun_top != null:
		utils.spawn_laser(left_gun_top.get_muzzle_position(), Vector2(1.0, 0.0))
	if left_gun_bottom != null:
		utils.spawn_laser(left_gun_bottom.get_muzzle_position(), Vector2(1.0, 0.0))
	if right_gun_top != null:
		utils.spawn_laser(right_gun_top.get_muzzle_position(), Vector2(-1.0, 0.0))
	if right_gun_bottom != null:
		utils.spawn_laser(right_gun_bottom.get_muzzle_position(), Vector2(-1.0, 0.0))

	await main.get_tree().create_timer(0.16).timeout

	if left_gun_top != null:
		utils.spawn_laser(left_gun_top.get_muzzle_position(), Vector2(1.0, 0.12))
	if left_gun_bottom != null:
		utils.spawn_laser(left_gun_bottom.get_muzzle_position(), Vector2(1.0, -0.12))
	if right_gun_top != null:
		utils.spawn_laser(right_gun_top.get_muzzle_position(), Vector2(-1.0, 0.12))
	if right_gun_bottom != null:
		utils.spawn_laser(right_gun_bottom.get_muzzle_position(), Vector2(-1.0, -0.12))

	await main.get_tree().create_timer(0.24).timeout

	await utils.remove_floating_gun(left_gun_top)
	await utils.remove_floating_gun(left_gun_bottom)
	await utils.remove_floating_gun(right_gun_top)
	await utils.remove_floating_gun(right_gun_bottom)

	utils.finish_alien_attack()

func combo_side_pincer_then_snipe() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()
	var center_y: float = main.arena_rect_global.get_center().y

	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y), main.player.global_position)

	await main.get_tree().create_timer(0.18).timeout

	if left_gun != null:
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, -0.08))
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, 0.08))

	if right_gun != null:
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, -0.08))
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, 0.08))

	await main.get_tree().create_timer(0.18).timeout

	var to_player: Vector2 = (main.player.global_position - boss_origin).normalized()
	utils.spawn_laser(boss_origin, to_player)
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(-7.0)))
	utils.spawn_laser(boss_origin, to_player.rotated(deg_to_rad(7.0)))

	await main.get_tree().create_timer(0.22).timeout

	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()

func combo_lateral_checkmate() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()
	var center_y: float = main.arena_rect_global.get_center().y

	var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y - 70.0), main.player.global_position)
	var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y + 70.0), main.player.global_position)

	await main.get_tree().create_timer(0.20).timeout

	if left_gun != null:
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, 0.0))
		utils.spawn_laser(left_gun.get_muzzle_position(), Vector2(1.0, 0.18))

	if right_gun != null:
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, 0.0))
		utils.spawn_laser(right_gun.get_muzzle_position(), Vector2(-1.0, -0.18))

	await main.get_tree().create_timer(0.16).timeout

	for dir in [Vector2(-0.20, 1.0), Vector2(0.0, 1.0), Vector2(0.20, 1.0)]:
		utils.spawn_laser(boss_origin, dir)

	await main.get_tree().create_timer(0.24).timeout

	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)
	utils.finish_alien_attack()

func alien_fire_broken_columns() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.20).timeout

	# Primera línea (3 columnas claras)
	for x in [-0.6, 0.0, 0.6]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.28).timeout

	# Segunda línea (2 columnas, deja huecos grandes)
	for x in [-0.4, 0.4]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.28).timeout

	# Tercera línea (otra vez 3, pero desplazadas)
	for x in [-0.6, 0.0, 0.6]:
		utils.spawn_laser(origin, Vector2(x, 1.0))

	await main.get_tree().create_timer(0.35).timeout
	utils.finish_alien_attack()

func combo_side_cross_grid() -> void:
	var center_y: float = main.arena_rect_global.get_center().y

	var left_gun_a := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y - 100.0), main.player.global_position)
	var left_gun_b := utils.spawn_floating_gun(utils.get_left_gun_pos(center_y + 100.0), main.player.global_position)
	var right_gun_a := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y - 100.0), main.player.global_position)
	var right_gun_b := utils.spawn_floating_gun(utils.get_right_gun_pos(center_y + 100.0), main.player.global_position)

	await main.get_tree().create_timer(0.18).timeout

	if left_gun_a != null:
		utils.spawn_laser(left_gun_a.get_muzzle_position(), Vector2(1.0, 0.10))
	if left_gun_b != null:
		utils.spawn_laser(left_gun_b.get_muzzle_position(), Vector2(1.0, -0.10))
	if right_gun_a != null:
		utils.spawn_laser(right_gun_a.get_muzzle_position(), Vector2(-1.0, 0.10))
	if right_gun_b != null:
		utils.spawn_laser(right_gun_b.get_muzzle_position(), Vector2(-1.0, -0.10))

	await main.get_tree().create_timer(0.16).timeout

	if left_gun_a != null:
		utils.spawn_laser(left_gun_a.get_muzzle_position(), Vector2(1.0, -0.10))
	if left_gun_b != null:
		utils.spawn_laser(left_gun_b.get_muzzle_position(), Vector2(1.0, 0.10))
	if right_gun_a != null:
		utils.spawn_laser(right_gun_a.get_muzzle_position(), Vector2(-1.0, -0.10))
	if right_gun_b != null:
		utils.spawn_laser(right_gun_b.get_muzzle_position(), Vector2(-1.0, 0.10))

	await main.get_tree().create_timer(0.22).timeout

	await utils.remove_floating_gun(left_gun_a)
	await utils.remove_floating_gun(left_gun_b)
	await utils.remove_floating_gun(right_gun_a)
	await utils.remove_floating_gun(right_gun_b)

	utils.finish_alien_attack()

func floating_gun_grid_interlaced() -> void:
	var boss_origin: Vector2 = utils.prepare_alien_attack()

	var vertical_guns: Array[Node2D] = []
	var horizontal_guns: Array[Node2D] = []

	var top_positions: Array[Vector2] = [
		utils.get_top_left_gun_pos(),
		utils.get_top_right_gun_pos()
	]

	for pos in top_positions:
		if not utils.is_pos_inside_boss_safe_rect(pos):
			var gun := utils.spawn_floating_gun(pos, Vector2(pos.x, main.arena_rect_global.get_center().y))
			if gun != null:
				vertical_guns.append(gun)

	var row_count: int = 4
	for i in range(row_count):
		var t: float = float(i) / float(row_count - 1)
		var y: float = lerp(
			main.arena_rect_global.position.y + 45.0,
			main.arena_rect_global.position.y + main.arena_rect_global.size.y - 45.0,
			t
		)

		var left_gun := utils.spawn_floating_gun(utils.get_left_gun_pos(y), Vector2(main.arena_rect_global.get_center().x, y))
		var right_gun := utils.spawn_floating_gun(utils.get_right_gun_pos(y), Vector2(main.arena_rect_global.get_center().x, y))

		if left_gun != null:
			horizontal_guns.append(left_gun)
		if right_gun != null:
			horizontal_guns.append(right_gun)

	await main.get_tree().create_timer(0.4).timeout

	for wave in range(3):
		for gun in vertical_guns:
			if gun != null:
				var dir: Vector2 = Vector2.DOWN
				if gun.has_method("aim_direction"):
					gun.aim_direction(dir)
				utils.spawn_laser(gun.get_muzzle_position(), dir)

		utils.spawn_laser(boss_origin, Vector2(0.0, 1.0))

		await main.get_tree().create_timer(0.12).timeout

		for i in range(horizontal_guns.size()):
			var gun: Node2D = horizontal_guns[i]
			if gun == null:
				continue

			var dir: Vector2 = Vector2.RIGHT if gun.global_position.x < main.arena_rect_global.get_center().x else Vector2.LEFT

			if gun.has_method("aim_direction"):
				gun.aim_direction(dir)

			utils.spawn_laser(gun.get_muzzle_position(), dir)
			await main.get_tree().create_timer(0.035).timeout

		await main.get_tree().create_timer(0.16).timeout

	await main.get_tree().create_timer(0.22).timeout

	for gun in vertical_guns:
		await utils.remove_floating_gun(gun)

	for gun in horizontal_guns:
		await utils.remove_floating_gun(gun)

	utils.finish_alien_attack()

func alien_fire_side_swap_fan() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var step: int = 12

	# Importante:
	# izquierda termina en 0 grados (centro vertical)
	# derecha empieza en 0 grados
	# así no se pasan al otro lado
	var start_left: int = -88
	var end_left: int = -8

	var start_right: int = 8
	var end_right: int = 88

	# =========================
	# IZQUIERDA (4 oleadas)
	# =========================
	for wave in range(4):
		var offset: int = wave * 3

		for i in range(start_left + offset, end_left + 1 + offset, step):
			var angle: float = float(i)
			var dir: Vector2 = Vector2.DOWN.rotated(deg_to_rad(angle))
			utils.spawn_laser(origin, dir)

		await main.get_tree().create_timer(0.12).timeout

	# pequeña pausa para forzar el cambio
	await main.get_tree().create_timer(0.18).timeout

	# =========================
	# DERECHA (4 oleadas)
	# =========================
	for wave in range(4):
		var offset: int = wave * -3

		for i in range(start_right + offset, end_right + 1 + offset, step):
			var angle: float = float(i)
			var dir: Vector2 = Vector2.DOWN.rotated(deg_to_rad(angle))
			utils.spawn_laser(origin, dir)

		await main.get_tree().create_timer(0.12).timeout

	await main.get_tree().create_timer(0.30).timeout
	utils.finish_alien_attack()

func alien_fire_snake_wall() -> void:
	var origin: Vector2 = utils.prepare_alien_attack()

	await main.get_tree().create_timer(0.18).timeout

	var lanes: Array[float] = [-0.9, -0.6, -0.3, 0.0, 0.3, 0.6, 0.9]
	var safe_index: int = 2
	var direction: int = 1

	for wave in range(15):
		for i in range(lanes.size()):
			if i == safe_index or i == safe_index + 1:
				continue

			utils.spawn_laser(origin, Vector2(lanes[i], 1.0))

		await main.get_tree().create_timer(0.10).timeout

		safe_index += direction

		if safe_index >= lanes.size() - 2:
			safe_index = lanes.size() - 2
			direction = -1
		elif safe_index <= 0:
			safe_index = 0
			direction = 1

	await main.get_tree().create_timer(0.30).timeout
	utils.finish_alien_attack()
	
func combo_side_lane_grid() -> void:
	var guns: Array[Node2D] = []
	var rows: int = 4

	for i in range(rows):
		var t: float = float(i) / float(rows - 1)
		var y: float = lerp(
			main.arena_rect_global.position.y + 45.0,
			main.arena_rect_global.position.y + main.arena_rect_global.size.y - 45.0,
			t
		)

		var left_gun := utils.spawn_floating_gun(
			utils.get_left_gun_pos(y),
			Vector2(main.arena_rect_global.get_center().x, y)
		)
		var right_gun := utils.spawn_floating_gun(
			utils.get_right_gun_pos(y),
			Vector2(main.arena_rect_global.get_center().x, y)
		)

		if left_gun != null:
			guns.append(left_gun)
		if right_gun != null:
			guns.append(right_gun)

	await main.get_tree().create_timer(0.20).timeout

	for gun in guns:
		if gun == null:
			continue

		var dir: Vector2 = Vector2.RIGHT if gun.global_position.x < main.arena_rect_global.get_center().x else Vector2.LEFT
		if gun.has_method("aim_direction"):
			gun.aim_direction(dir)
		utils.spawn_laser(gun.get_muzzle_position(), dir)

	await main.get_tree().create_timer(0.16).timeout

	for i in range(guns.size()):
		var gun := guns[i]
		if gun == null:
			continue

		var dir: Vector2 = Vector2.RIGHT if gun.global_position.x < main.arena_rect_global.get_center().x else Vector2.LEFT
		utils.spawn_laser(gun.get_muzzle_position(), dir.rotated(deg_to_rad(8.0 if dir.x > 0 else -8.0)))

	await main.get_tree().create_timer(0.24).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

	utils.finish_alien_attack()

func combo_tracking_angle_guns_staggered_stream() -> void:
	var rect: Rect2 = main.arena_rect_global

	var spawn_positions: Array[Vector2] = [
		Vector2(rect.position.x - 95.0, rect.position.y + rect.size.y * 0.22),
		Vector2(rect.position.x + rect.size.x * 0.28, rect.position.y - 95.0),
		Vector2(rect.position.x + rect.size.x + 95.0, rect.position.y + rect.size.y * 0.45),
		Vector2(rect.position.x + rect.size.x * 0.72, rect.position.y - 95.0)
	]

	active_tracking_guns = 0

	for pos in spawn_positions:
		var gun := utils.spawn_floating_gun(pos, main.player.global_position)
		if gun != null:
			active_tracking_guns += 1
			call_deferred("_run_tracking_gun_sequence", gun)

		await main.get_tree().create_timer(0.55).timeout

	while active_tracking_guns > 0:
		await main.get_tree().create_timer(0.05).timeout

	utils.finish_alien_attack()
	
func _run_tracking_gun_sequence(gun: Node2D) -> void:
	if gun == null or not is_instance_valid(gun):
		active_tracking_guns = max(active_tracking_guns - 1, 0)
		return

	# TRACKING
	var track_time: float = 0.50
	var step_time: float = 0.03
	var steps: int = int(track_time / step_time)

	for i in range(steps):
		if gun == null or not is_instance_valid(gun):
			active_tracking_guns = max(active_tracking_guns - 1, 0)
			return
		if main.player == null or not is_instance_valid(main.player):
			active_tracking_guns = max(active_tracking_guns - 1, 0)
			return

		var dir: Vector2 = (main.player.global_position - gun.get_muzzle_position()).normalized()

		if gun.has_method("aim_direction"):
			gun.aim_direction(dir)

		await main.get_tree().create_timer(step_time).timeout

	# LOCK
	if gun == null or not is_instance_valid(gun):
		active_tracking_guns = max(active_tracking_guns - 1, 0)
		return

	var locked_dir: Vector2 = (main.player.global_position - gun.get_muzzle_position()).normalized()

	if gun.has_method("aim_direction"):
		gun.aim_direction(locked_dir)

	await main.get_tree().create_timer(0.28).timeout

	# DISPARO
	var shots: int = 10

	for i in range(shots):
		if gun == null or not is_instance_valid(gun):
			active_tracking_guns = max(active_tracking_guns - 1, 0)
			return

		if gun.has_method("aim_direction"):
			gun.aim_direction(locked_dir)

		for offset in [-3.0, 0.0, 3.0]:
			utils.spawn_laser(
				gun.get_muzzle_position(),
				locked_dir.rotated(deg_to_rad(offset)),
				1000.0
			)

		await main.get_tree().create_timer(0.08).timeout

	if gun != null and is_instance_valid(gun):
		await utils.remove_floating_gun(gun)

	active_tracking_guns = max(active_tracking_guns - 1, 0)

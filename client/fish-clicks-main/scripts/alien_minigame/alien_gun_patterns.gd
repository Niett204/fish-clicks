extends Node
class_name AlienGunPatterns

var main: Node2D = null
var utils: AlienAttackUtils = null

func setup(main_ref: Node2D, utils_ref: AlienAttackUtils) -> void:
	main = main_ref
	utils = utils_ref

func floating_gun_double_side() -> void:
	utils.finish_alien_attack()

	var left_pos := utils.get_left_gun_pos(main.arena_rect_global.get_center().y)
	var right_pos := utils.get_right_gun_pos(main.arena_rect_global.get_center().y)

	var left_gun := utils.spawn_floating_gun(left_pos, main.player.global_position)
	var right_gun := utils.spawn_floating_gun(right_pos, main.player.global_position)

	await main.get_tree().create_timer(0.32).timeout

	if left_gun != null:
		var left_dir: Vector2 = utils.aim_gun_at_target(left_gun, main.player.global_position)
		utils.spawn_laser(left_gun.get_muzzle_position(), left_dir)

	if right_gun != null:
		var right_dir: Vector2 = utils.aim_gun_at_target(right_gun, main.player.global_position)
		utils.spawn_laser(right_gun.get_muzzle_position(), right_dir)

	await main.get_tree().create_timer(0.22).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)

func floating_gun_corners_cross() -> void:
	utils.finish_alien_attack()

	var positions: Array[Vector2] = [
		Vector2(main.arena_rect_global.position.x - 110.0, main.arena_rect_global.position.y - 90.0),
		Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x + 110.0, main.arena_rect_global.position.y - 90.0),
		Vector2(main.arena_rect_global.position.x - 110.0, main.arena_rect_global.position.y + main.arena_rect_global.size.y + 90.0),
		Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x + 110.0, main.arena_rect_global.position.y + main.arena_rect_global.size.y + 90.0)
	]

	var guns: Array[Node2D] = []

	for pos in positions:
		if not utils.is_pos_inside_boss_safe_rect(pos):
			var gun := utils.spawn_floating_gun(pos, main.player.global_position)
			if gun != null:
				guns.append(gun)

	await main.get_tree().create_timer(0.35).timeout

	for gun in guns:
		var dir: Vector2 = utils.aim_gun_at_target(gun, main.player.global_position)
		utils.spawn_laser(gun.get_muzzle_position(), dir)

	await main.get_tree().create_timer(0.24).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

func floating_gun_top_trio() -> void:
	utils.finish_alien_attack()

	var positions: Array[Vector2] = [
		utils.get_top_left_gun_pos(),
		Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x * 0.35, main.arena_rect_global.position.y - 260.0),
		Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x * 0.65, main.arena_rect_global.position.y - 260.0)
	]

	var guns: Array[Node2D] = []

	for pos in positions:
		if not utils.is_pos_inside_boss_safe_rect(pos):
			var gun := utils.spawn_floating_gun(pos, main.player.global_position)
			if gun != null:
				guns.append(gun)

	await main.get_tree().create_timer(0.34).timeout

	for gun in guns:
		if gun != null:
			var dir: Vector2 = utils.aim_gun_at_target(gun, main.player.global_position)
			utils.spawn_laser(gun.get_muzzle_position(), dir)

	await main.get_tree().create_timer(0.22).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

func floating_gun_triple_aimed() -> void:
	utils.finish_alien_attack()

	var positions: Array[Vector2] = [
		utils.get_left_gun_pos(main.arena_rect_global.get_center().y - 90.0),
		utils.get_right_gun_pos(main.arena_rect_global.get_center().y - 90.0),
		utils.get_top_right_gun_pos()
	]

	var guns: Array[Node2D] = []

	for pos in positions:
		if not utils.is_pos_inside_boss_safe_rect(pos):
			var gun := utils.spawn_floating_gun(pos, main.player.global_position)
			if gun != null:
				guns.append(gun)

	await main.get_tree().create_timer(0.34).timeout

	for gun in guns:
		var dir: Vector2 = utils.aim_gun_at_target(gun, main.player.global_position)
		utils.spawn_laser(gun.get_muzzle_position(), dir)
		utils.spawn_laser(gun.get_muzzle_position(), dir.rotated(deg_to_rad(-8.0)))
		utils.spawn_laser(gun.get_muzzle_position(), dir.rotated(deg_to_rad(8.0)))

	await main.get_tree().create_timer(0.24).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

func floating_gun_rain_center() -> void:
	utils.finish_alien_attack()

	var gun := utils.spawn_floating_gun(
		Vector2(main.arena_rect_global.position.x + main.arena_rect_global.size.x * 0.58, main.arena_rect_global.position.y - 250.0),
		main.arena_rect_global.get_center()
	)
	await main.get_tree().create_timer(0.35).timeout

	if gun != null:
		for i in range(8):
			var dir: Vector2 = Vector2(randf_range(-0.12, 0.12), 1.0).normalized()
			if gun.has_method("aim_direction"):
				gun.aim_direction(dir)
			utils.spawn_laser(gun.get_muzzle_position(), dir)
			await main.get_tree().create_timer(0.09).timeout

	await main.get_tree().create_timer(0.2).timeout
	await utils.remove_floating_gun(gun)

func floating_gun_rain_dual() -> void:
	utils.finish_alien_attack()

	var left_gun := utils.spawn_floating_gun(utils.get_top_left_gun_pos(), main.arena_rect_global.get_center())
	var right_gun := utils.spawn_floating_gun(utils.get_top_right_gun_pos(), main.arena_rect_global.get_center())

	await main.get_tree().create_timer(0.35).timeout

	for i in range(6):
		if left_gun != null:
			var left_dir: Vector2 = Vector2(randf_range(-0.08, 0.08), 1.0).normalized()
			if left_gun.has_method("aim_direction"):
				left_gun.aim_direction(left_dir)
			utils.spawn_laser(left_gun.get_muzzle_position(), left_dir)

		await main.get_tree().create_timer(0.08).timeout

		if right_gun != null:
			var right_dir: Vector2 = Vector2(randf_range(-0.08, 0.08), 1.0).normalized()
			if right_gun.has_method("aim_direction"):
				right_gun.aim_direction(right_dir)
			utils.spawn_laser(right_gun.get_muzzle_position(), right_dir)

		await main.get_tree().create_timer(0.08).timeout

	await main.get_tree().create_timer(0.2).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)

func floating_gun_rain_zigzag() -> void:
	utils.finish_alien_attack()

	var left_gun := utils.spawn_floating_gun(utils.get_top_left_gun_pos(), main.arena_rect_global.get_center())
	var right_gun := utils.spawn_floating_gun(utils.get_top_right_gun_pos(), main.arena_rect_global.get_center())

	await main.get_tree().create_timer(0.35).timeout

	for i in range(6):
		if left_gun != null:
			var left_dir: Vector2 = Vector2(0.35, 1.0).normalized()
			if i % 2 == 0:
				left_dir = Vector2(0.18, 1.0).normalized()
			if left_gun.has_method("aim_direction"):
				left_gun.aim_direction(left_dir)
			utils.spawn_laser(left_gun.get_muzzle_position(), left_dir)

		if right_gun != null:
			var right_dir: Vector2 = Vector2(-0.35, 1.0).normalized()
			if i % 2 == 0:
				right_dir = Vector2(-0.18, 1.0).normalized()
			if right_gun.has_method("aim_direction"):
				right_gun.aim_direction(right_dir)
			utils.spawn_laser(right_gun.get_muzzle_position(), right_dir)

		await main.get_tree().create_timer(0.12).timeout

	await main.get_tree().create_timer(0.2).timeout
	await utils.remove_floating_gun(left_gun)
	await utils.remove_floating_gun(right_gun)

func floating_gun_horizontal_rain() -> void:
	utils.finish_alien_attack()

	var lane_count: int = 5
	var guns: Array[Node2D] = []

	for i in range(lane_count):
		var t: float = float(i) / float(lane_count - 1)
		var y: float = lerp(
			main.arena_rect_global.position.y + 30.0,
			main.arena_rect_global.position.y + main.arena_rect_global.size.y - 30.0,
			t
		)

		var use_left: bool = i % 2 == 0
		var pos: Vector2 = utils.get_left_gun_pos(y) if use_left else utils.get_right_gun_pos(y)

		if not utils.is_pos_inside_boss_safe_rect(pos):
			var aim_target := Vector2(main.arena_rect_global.get_center().x, y)
			var gun := utils.spawn_floating_gun(pos, aim_target)
			if gun != null:
				guns.append(gun)

	await main.get_tree().create_timer(0.35).timeout

	for i in range(guns.size()):
		var gun: Node2D = guns[i]
		if gun == null:
			continue

		var dir: Vector2 = Vector2.RIGHT if gun.global_position.x < main.arena_rect_global.get_center().x else Vector2.LEFT

		if gun.has_method("aim_direction"):
			gun.aim_direction(dir)

		utils.spawn_laser(gun.get_muzzle_position(), dir)
		await main.get_tree().create_timer(0.06).timeout

	await main.get_tree().create_timer(0.22).timeout

	for gun in guns:
		await utils.remove_floating_gun(gun)

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

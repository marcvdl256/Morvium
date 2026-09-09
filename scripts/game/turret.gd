extends Node2D
class_name MorviumTurret

signal request_projectile(origin: Vector2, target: Node2D, damage: float, splash: float, turret_type: String)
signal sold(value: int)

var turret_type: String = "mg"
var level: int = 1
var damage: float = 12.0
var fire_rate: float = 6.0
var range_px: float = 420.0
var cost: int = 120
var invested: int = 120
var cooldown: float = 0.0
var target: Node2D
var head_rotation: float = 0.0
var enabled: bool = true

func setup(kind: String) -> void:
	turret_type = kind
	match kind:
		"hmg": damage = 24.0; fire_rate = 4.0; range_px = 480.0; cost = 300
		"sniper": damage = 110.0; fire_rate = 0.7; range_px = 850.0; cost = 450
		"shotgun": damage = 18.0; fire_rate = 1.8; range_px = 280.0; cost = 350
		"rocket": damage = 160.0; fire_rate = 0.45; range_px = 700.0; cost = 750
		_: damage = 12.0; fire_rate = 6.0; range_px = 420.0; cost = 120
	invested = cost
	queue_redraw()

func _process(delta: float) -> void:
	if not enabled:
		return
	cooldown = maxf(0.0, cooldown - delta)
	if not is_instance_valid(target) or target.dead or global_position.distance_to(target.global_position) > range_px:
		target = find_target()
	if is_instance_valid(target):
		head_rotation = global_position.angle_to_point(target.global_position)
		if cooldown <= 0.0:
			cooldown = 1.0 / fire_rate
			fire_at_target()
	queue_redraw()

func find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	if turret_type == "sniper":
		var best_hp := -1.0
		for e in enemies:
			if is_instance_valid(e) and not e.dead and global_position.distance_to(e.global_position) <= range_px and e.health > best_hp:
				best_hp = e.health
				best = e
	else:
		var best_x := INF
		for e in enemies:
			if is_instance_valid(e) and not e.dead and global_position.distance_to(e.global_position) <= range_px and e.global_position.x < best_x:
				best_x = e.global_position.x
				best = e
	return best

func fire_at_target() -> void:
	if not is_instance_valid(target): return
	var splash := 0.0
	if turret_type == "rocket": splash = 140.0 + (level - 1) * 25.0
	if turret_type == "shotgun":
		for i in range(5):
			request_projectile.emit(global_position + Vector2(22, -7).rotated(head_rotation), target, damage, 0.0, "shotgun")
	else:
		request_projectile.emit(global_position + Vector2(22, -7).rotated(head_rotation), target, damage, splash, turret_type)

func get_upgrade_cost() -> int:
	if level >= 3: return -1
	return int(cost * (0.8 if level == 1 else 1.25))

func upgrade() -> void:
	if level >= 3: return
	var upgrade_cost := get_upgrade_cost()
	level += 1
	invested += upgrade_cost
	damage *= 1.35
	fire_rate *= 1.16
	range_px *= 1.08
	queue_redraw()

func sell_value() -> int:
	return int(invested * 0.6)

func _draw() -> void:
	var base_color := Color("3c4446")
	var accent := Color("c67b3b")
	if turret_type == "sniper": accent = Color("7a9368")
	if turret_type == "rocket": accent = Color("9b4a3f")
	if turret_type == "hmg": accent = Color("8a7861")
	if turret_type == "shotgun": accent = Color("a36d4c")
	draw_rect(Rect2(-18, -10, 36, 20), base_color, true)
	draw_circle(Vector2.ZERO, 12, Color("292f31"))
	draw_set_transform(Vector2.ZERO, head_rotation, Vector2.ONE)
	draw_rect(Rect2(0, -6, 34 if turret_type != "sniper" else 48, 12), accent, true)
	if turret_type == "rocket":
		draw_rect(Rect2(2, -12, 26, 8), Color("5d3832"), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in range(level):
		draw_circle(Vector2(-10 + i * 10, 15), 2.5, Color("e8b85c"))

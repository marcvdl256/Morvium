class_name BasicZombie
extends CharacterBody2D

signal zombie_died(zombie: BasicZombie, gold_reward: int)

@export var data: ZombieData
var current_health: float = 1.0
var attack_cooldown: float = 0.0
var target: BuildingModule

func _ready() -> void:
	add_to_group("zombies")
	if data == null:
		push_error("%s has no ZombieData assigned." % name)
		return
	current_health = data.max_health
	queue_redraw()

func _physics_process(delta: float) -> void:
	if data == null:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	if not is_instance_valid(target):
		target = _find_target()

	if not is_instance_valid(target):
		velocity.x = 0.0
		move_and_slide()
		return

	var distance_x := target.global_position.x - global_position.x
	var direction := signf(distance_x)

	if absf(distance_x) > data.attack_range:
		velocity.x = direction * data.movement_speed
		move_and_slide()
	else:
		velocity.x = 0.0
		if attack_cooldown <= 0.0:
			target.take_damage(data.damage)
			attack_cooldown = 1.0 / maxf(data.attack_rate, 0.01)

func _find_target() -> BuildingModule:
	var best: BuildingModule = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("building_modules"):
		if node is BuildingModule:
			var module := node as BuildingModule
			var distance := absf(module.global_position.x - global_position.x)
			if distance < best_distance:
				best = module
				best_distance = distance
	return best

func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	if current_health <= 0.0:
		die()

func die() -> void:
	if is_queued_for_deletion():
		return
	var reward := data.gold_reward if data != null else 0
	zombie_died.emit(self, reward)
	EconomyManager.add_gold(reward)
	queue_free()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-12, -38), Vector2(24, 38)), Color(0.36, 0.34, 0.28), true)
	draw_circle(Vector2(0, -48), 12.0, Color(0.48, 0.50, 0.39))
	draw_line(Vector2(-7, -6), Vector2(-8, 20), Color(0.18, 0.17, 0.16), 6.0)
	draw_line(Vector2(7, -6), Vector2(8, 20), Color(0.18, 0.17, 0.16), 6.0)

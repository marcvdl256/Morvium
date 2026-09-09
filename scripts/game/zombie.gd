extends Node2D
class_name MorviumZombie

signal died(zombie: MorviumZombie, reward: int)
signal reached_tower(damage: float)

var kind: String = "basic"
var max_health: float = 100.0
var health: float = 100.0
var speed: float = 45.0
var attack_damage: float = 15.0
var attack_cooldown: float = 1.2
var reward: int = 10
var armor: float = 0.0
var attack_range: float = 72.0
var target_x: float = 960.0
var hp_scale: float = 1.0
var attack_timer: float = 0.0
var flash_timer: float = 0.0
var death_timer: float = 0.0
var dead: bool = false

func setup(enemy_kind: String, health_multiplier: float = 1.0) -> void:
	kind = enemy_kind
	hp_scale = health_multiplier
	match kind:
		"runner":
			max_health = 65.0
			speed = 90.0
			attack_damage = 10.0
			reward = 12
		"tank":
			max_health = 450.0
			speed = 28.0
			attack_damage = 35.0
			attack_cooldown = 1.5
			reward = 45
		"armored":
			max_health = 300.0
			speed = 35.0
			attack_damage = 25.0
			armor = 0.25
			reward = 35
		"exploder":
			max_health = 150.0
			speed = 45.0
			attack_damage = 130.0
			attack_cooldown = 99.0
			reward = 25
		_:
			max_health = 100.0
			speed = 45.0
			attack_damage = 15.0
			reward = 10
	max_health *= hp_scale
	health = max_health
	queue_redraw()

func _process(delta: float) -> void:
	if dead:
		death_timer -= delta
		modulate.a = clampf(death_timer / 0.35, 0.0, 1.0)
		rotation += delta * 1.5
		position.y += 25.0 * delta
		if death_timer <= 0.0:
			queue_free()
		return
	flash_timer = maxf(0.0, flash_timer - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	if position.x - target_x > attack_range:
		position.x -= speed * delta
		position.y += sin(Time.get_ticks_msec() * 0.01 + position.x * 0.01) * 2.0 * delta
	else:
		if kind == "exploder":
			reached_tower.emit(attack_damage)
			died.emit(self, 0)
			die(false)
		elif attack_timer <= 0.0:
			attack_timer = attack_cooldown
			reached_tower.emit(attack_damage)
	queue_redraw()

func take_damage(amount: float, knockback: float = 0.0) -> void:
	if dead:
		return
	var actual: float = amount * (1.0 - armor)
	health -= actual
	position.x += knockback
	flash_timer = 0.08
	queue_redraw()
	if health <= 0.0:
		die(true)

func die(grant_reward: bool = true) -> void:
	if dead:
		return
	dead = true
	death_timer = 0.35
	if grant_reward:
		died.emit(self, reward)
	queue_redraw()

func _draw() -> void:
	var body: Color = Color("6f7c56")
	var skin: Color = Color("a1a778")
	var dark: Color = Color("202522")
	if kind == "runner":
		body = Color("7b6651")
	elif kind == "tank":
		body = Color("4d5a43")
	elif kind == "armored":
		body = Color("596068")
	elif kind == "exploder":
		body = Color("7a4d3d")
	if flash_timer > 0.0:
		body = Color.WHITE
		skin = Color.WHITE
	var scale_factor: float = 1.0
	if kind == "tank":
		scale_factor = 1.35
	if kind == "runner":
		scale_factor = 0.85
	draw_circle(Vector2(0, -42) * scale_factor, 15.0 * scale_factor, skin)
	draw_rect(Rect2(Vector2(-15, -28) * scale_factor, Vector2(30, 45) * scale_factor), body, true)
	draw_line(Vector2(-8, 14) * scale_factor, Vector2(-13, 38) * scale_factor, dark, 7.0 * scale_factor)
	draw_line(Vector2(8, 14) * scale_factor, Vector2(14, 38) * scale_factor, dark, 7.0 * scale_factor)
	draw_line(Vector2(-13, -18) * scale_factor, Vector2(-31, 1) * scale_factor, skin, 6.0 * scale_factor)
	draw_line(Vector2(13, -18) * scale_factor, Vector2(28, 3) * scale_factor, skin, 6.0 * scale_factor)
	if kind == "armored":
		draw_rect(Rect2(-17, -31, 34, 26), Color("434b54"), true)
		draw_rect(Rect2(-15, -57, 30, 8), Color("343b42"), true)
	if kind == "exploder":
		draw_circle(Vector2(18, -11), 10, Color("b04332"))
		draw_circle(Vector2(18, -11), 4, Color("f4a340"))
	if kind == "tank":
		draw_rect(Rect2(-24, -35, 48, 12), Color("343d31"), true)
	if health < max_health and not dead:
		var ratio: float = clampf(health / max_health, 0.0, 1.0)
		draw_rect(Rect2(-24, -72, 48, 5), Color("2b2424"), true)
		draw_rect(Rect2(-24, -72, 48 * ratio, 5), Color("b44b3e"), true)

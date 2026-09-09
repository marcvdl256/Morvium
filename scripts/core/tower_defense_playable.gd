extends "res://scripts/core/tower_defense_main.gd"

const PlayerCharacterScript = preload("res://scripts/game/player_character.gd")

var player_character: MorviumPlayerCharacter
var starter_turret_created: bool = false

func _ready() -> void:
	super._ready()
	player_character = PlayerCharacterScript.new()
	player_character.name = "PlayerCharacter"
	player_character.position = Vector2(650.0, GROUND_Y - 40.0)
	player_character.ground_y = GROUND_Y - 40.0
	add_child(player_character)
	create_starter_turret()
	show_message("A/D MOVE   W OR SPACE JUMP   S CROUCH   MOUSE AIM   LMB FIRE   R RELOAD")

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(player_character):
		player_character.update_character(delta, not game_over and not paused_game)

func fire_weapon(target_pos: Vector2) -> void:
	if fire_cooldown > 0.0 or reloading:
		return
	if ammo <= 0 and not infinite_ammo:
		begin_reload()
		return

	fire_cooldown = 1.0 / weapon_fire_rate
	shots_fired += 1
	if not infinite_ammo:
		ammo -= 1

	var origin: Vector2 = Vector2(930.0, 760.0)
	if is_instance_valid(player_character):
		player_character.aim_position = target_pos
		origin = player_character.get_muzzle_position()

	var direction: Vector2 = origin.direction_to(target_pos).rotated(rng.randf_range(-weapon_spread, weapon_spread))
	var hit = ray_pick_enemy(origin, direction, 1400.0)
	var end: Vector2 = origin + direction * 1400.0
	if hit != null:
		end = hit.global_position
		var critical: bool = rng.randf() <= 0.05
		var dmg: float = weapon_damage * (2.0 if critical else 1.0)
		hit.take_damage(dmg, 7.0)
		shots_hit += 1
		add_effect(hit.global_position, "hit", 0.16)

	add_tracer(origin, end)
	shake(0.05, 2.5)
	if ammo <= 0 and not infinite_ammo:
		begin_reload()

func create_starter_turret() -> void:
	if starter_turret_created:
		return
	var points: Array[Vector2] = tower.hardpoint_positions()
	if points.is_empty():
		return
	var t = TurretScript.new()
	t.position = tower.global_position + points[0]
	t.setup("mg")
	t.request_projectile.connect(_on_turret_fire)
	add_child(t)
	turrets.append(t)
	occupied_hardpoints[0] = t
	starter_turret_created = true

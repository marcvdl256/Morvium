extends Node2D
class_name MorviumPlayerCharacter

var move_speed: float = 280.0
var jump_speed: float = 620.0
var gravity: float = 1700.0
var min_x: float = 120.0
var max_x: float = 1560.0
var ground_y: float = 840.0
var velocity_y: float = 0.0
var aim_position: Vector2 = Vector2.RIGHT
var walk_time: float = 0.0
var moving: bool = false
var crouching: bool = false
var facing_right: bool = true
var was_jump_pressed: bool = false

func _ready() -> void:
	position.y = ground_y
	queue_redraw()

func update_character(delta: float, enabled: bool = true) -> void:
	if not enabled:
		moving = false
		queue_redraw()
		return

	var axis: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		axis -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		axis += 1.0

	crouching = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	moving = absf(axis) > 0.01 and not crouching
	if moving:
		position.x = clampf(position.x + axis * move_speed * delta, min_x, max_x)
		walk_time += delta * 10.0
		facing_right = axis > 0.0

	var on_ground: bool = position.y >= ground_y - 0.1
	var jump_pressed: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP)
	if jump_pressed and not was_jump_pressed and on_ground and not crouching:
		velocity_y = -jump_speed
	was_jump_pressed = jump_pressed

	velocity_y += gravity * delta
	position.y += velocity_y * delta
	if position.y >= ground_y:
		position.y = ground_y
		velocity_y = 0.0

	aim_position = get_global_mouse_position()
	if aim_position.x != global_position.x:
		facing_right = aim_position.x > global_position.x
	queue_redraw()

func get_muzzle_position() -> Vector2:
	var shoulder := global_position + Vector2(0.0, -56.0 if not crouching else -38.0)
	var direction: Vector2 = shoulder.direction_to(aim_position)
	return shoulder + direction * 54.0

func _draw() -> void:
	var body_color := Color("4f5b43")
	var pants_color := Color("2f3431")
	var skin_color := Color("b2a17c")
	var outline := Color("151918")
	var weapon_color := Color("353a3a")

	var crouch_offset: float = 22.0 if crouching else 0.0
	var bob: float = sin(walk_time) * 2.5 if moving and absf(velocity_y) < 0.1 else 0.0
	var torso_y: float = -58.0 + crouch_offset + bob

	# legs
	var stride: float = sin(walk_time) * 9.0 if moving else 0.0
	draw_line(Vector2(-8, torso_y + 34), Vector2(-12 + stride, -5 + crouch_offset), pants_color, 10.0)
	draw_line(Vector2(8, torso_y + 34), Vector2(12 - stride, -5 + crouch_offset), pants_color, 10.0)
	# torso and head
	draw_rect(Rect2(-18, torso_y, 36, 46), body_color, true)
	draw_rect(Rect2(-18, torso_y, 36, 46), outline, false, 3.0)
	draw_circle(Vector2(0, torso_y - 17), 14.0, skin_color)
	# backpack silhouette
	draw_rect(Rect2(-25 if facing_right else 13, torso_y + 4, 12, 30), Color("3b4035"), true)

	# arms and rifle aim toward mouse
	var shoulder := Vector2(0, torso_y + 12)
	var local_aim: Vector2 = to_local(aim_position)
	var aim_dir: Vector2 = shoulder.direction_to(local_aim)
	if aim_dir == Vector2.ZERO:
		aim_dir = Vector2.RIGHT
	var hand := shoulder + aim_dir * 31.0
	var muzzle := shoulder + aim_dir * 60.0
	draw_line(shoulder, hand, skin_color, 7.0)
	draw_line(shoulder + Vector2(0, 8), hand + aim_dir * 5.0, skin_color, 6.0)
	draw_line(hand - aim_dir * 10.0, muzzle, weapon_color, 9.0)
	draw_line(muzzle - aim_dir * 24.0, muzzle + aim_dir * 8.0, outline, 3.0)

	# simple face direction marker
	draw_circle(Vector2(5 if facing_right else -5, torso_y - 19), 2.0, outline)

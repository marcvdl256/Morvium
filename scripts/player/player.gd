class_name Player
extends CharacterBody2D

@export var move_speed: float = 220.0
@export var gravity: float = 1200.0

func _ready() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-14, -44), Vector2(28, 44)), Color(0.31, 0.38, 0.25), true)
	draw_circle(Vector2(0, -56), 13.0, Color(0.72, 0.55, 0.42))
	draw_line(Vector2(-8, -8), Vector2(-10, 20), Color(0.14, 0.13, 0.12), 7.0)
	draw_line(Vector2(8, -8), Vector2(10, 20), Color(0.14, 0.13, 0.12), 7.0)

class_name BuildingModule
extends StaticBody2D

signal module_destroyed(module: BuildingModule)
signal health_changed(current_health: float, max_health: float)

@export var data: BuildingData
var current_health: float = 1.0
var grid_position: Vector2i = Vector2i.ZERO

func _ready() -> void:
	add_to_group("building_modules")
	if data == null:
		push_error("%s has no BuildingData assigned." % name)
		return
	current_health = data.max_health
	queue_redraw()

func setup_grid_position(value: Vector2i) -> void:
	grid_position = value

func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, get_max_health())
	queue_redraw()
	if current_health <= 0.0:
		module_destroyed.emit(self)
		queue_free()

func repair(amount: float) -> void:
	if amount <= 0.0 or data == null:
		return
	current_health = minf(data.max_health, current_health + amount)
	health_changed.emit(current_health, data.max_health)
	queue_redraw()

func get_max_health() -> float:
	return data.max_health if data != null else 1.0

func get_cost() -> int:
	return data.cost if data != null else 0

func _draw() -> void:
	var size := Vector2(60.0, 60.0)
	draw_rect(Rect2(-size / 2.0, size), Color(0.30, 0.24, 0.18), true)
	draw_rect(Rect2(-size / 2.0, size), Color(0.08, 0.07, 0.06), false, 3.0)
	if data != null and current_health < data.max_health:
		var ratio := clampf(current_health / data.max_health, 0.0, 1.0)
		draw_rect(Rect2(Vector2(-28, -38), Vector2(56, 5)), Color(0.12, 0.12, 0.12), true)
		draw_rect(Rect2(Vector2(-28, -38), Vector2(56 * ratio, 5)), Color(0.70, 0.70, 0.70), true)

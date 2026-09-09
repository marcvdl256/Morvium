extends Node2D
class_name MorviumTower

signal destroyed
signal health_changed(current: float, maximum: float)
signal floor_added(level: int)

var max_health: float = 1000.0
var health: float = 1000.0
var level: int = 1
var max_level: int = 6
var invincible: bool = false
var damage_flash: float = 0.0
var floor_costs := {2: 150, 3: 300, 4: 550, 5: 900, 6: 1400}

func _process(delta: float) -> void:
	damage_flash = maxf(0.0, damage_flash - delta)
	queue_redraw()

func take_damage(amount: float) -> void:
	if invincible: return
	health = maxf(0.0, health - amount)
	damage_flash = 0.14
	health_changed.emit(health, max_health)
	if health <= 0.0:
		destroyed.emit()

func repair(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)
	queue_redraw()

func next_floor_cost() -> int:
	return floor_costs.get(level + 1, -1)

func add_floor() -> void:
	if level >= max_level: return
	level += 1
	floor_added.emit(level)
	queue_redraw()

func hardpoint_positions() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for floor_index in range(level):
		var y: float = -20.0 - float(floor_index) * 72.0
		points.append(Vector2(-58, y))
		points.append(Vector2(58, y))
	return points

func _draw() -> void:
	var metal := Color("343a3b")
	var trim := Color("6b5944")
	if damage_flash > 0.0: metal = Color("74483e")
	draw_rect(Rect2(-82, -12, 164, 28), Color("252b2b"), true)
	for i in range(level):
		var y: float = -66.0 - float(i) * 72.0
		draw_rect(Rect2(-68, y, 136, 62), metal, true)
		draw_rect(Rect2(-74, y - 6, 148, 8), trim, true)
		draw_line(Vector2(-55, y + 8), Vector2(55, y + 50), Color("1f2424"), 5)
		draw_line(Vector2(55, y + 8), Vector2(-55, y + 50), Color("1f2424"), 5)
		draw_circle(Vector2(-58, y - 7), 7, Color("b77a45"))
		draw_circle(Vector2(58, y - 7), 7, Color("b77a45"))
	var ratio: float = clampf(health / max_health, 0.0, 1.0)
	if ratio < 0.75:
		draw_line(Vector2(-48, -40), Vector2(-22, -22), Color("151818"), 4)
	if ratio < 0.5:
		draw_line(Vector2(28, -55), Vector2(8, -30), Color("151818"), 5)
	if ratio < 0.25:
		draw_circle(Vector2(40, -26), 9, Color("1b1d1c"))

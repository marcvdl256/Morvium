extends Node2D
class_name MorviumMine

signal gold_generated(amount: int)
signal upgraded(level: int, rate: float)

var level: int = 1
var production_rates := {1: 3.0, 2: 5.0, 3: 8.0, 4: 12.0, 5: 18.0, 6: 27.0}
var upgrade_costs := {2: 150, 3: 350, 4: 700, 5: 1300, 6: 2200}
var timer: float = 0.0
var gear_rotation: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	gear_rotation += delta * (0.8 + level * 0.1)
	while timer >= 1.0:
		timer -= 1.0
		gold_generated.emit(int(production_rates[level]))
	queue_redraw()

func current_rate() -> float:
	return production_rates[level]

func next_upgrade_cost() -> int:
	return upgrade_costs.get(level + 1, -1)

func upgrade() -> void:
	if level >= 6: return
	level += 1
	upgraded.emit(level, current_rate())
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-88, -48, 176, 64), Color("302d28"), true)
	draw_polygon(PackedVector2Array([Vector2(-98,-48), Vector2(0,-100), Vector2(98,-48)]), PackedColorArray([Color("574939")]))
	draw_rect(Rect2(-34, -45, 68, 61), Color("17191a"), true)
	draw_circle(Vector2(50,-22), 24, Color("4a443a"))
	for i in range(8):
		var a := gear_rotation + i * TAU / 8.0
		draw_line(Vector2(50,-22), Vector2(50,-22) + Vector2.RIGHT.rotated(a) * 31.0, Color("8c744f"), 5.0)
	draw_circle(Vector2(50,-22), 7, Color("c08a45"))
	draw_rect(Rect2(-79, -8, 42, 18), Color("5c4a36"), true)
	draw_circle(Vector2(-69, 13), 8, Color("222626"))
	draw_circle(Vector2(-47, 13), 8, Color("222626"))
	for i in range(level):
		draw_circle(Vector2(-72 + i * 17, -64), 4, Color("d9a94c"))

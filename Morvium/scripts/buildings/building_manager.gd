class_name BuildingManager
extends Node2D

signal module_placed(module: BuildingModule, grid_position: Vector2i)
signal module_removed(grid_position: Vector2i)

@export var cell_size: int = 64
@export var ground_y: float = 600.0
@export var preview_enabled: bool = true
@export var show_grid: bool = true
@export var basic_block_scene: PackedScene

var occupied_cells: Dictionary = {}
var preview_grid_position: Vector2i = Vector2i.ZERO
var preview_valid: bool = false

func _ready() -> void:
	GameManager.build_mode_changed.connect(_on_build_mode_changed)
	_register_existing_modules()
	queue_redraw()

func _process(_delta: float) -> void:
	if GameManager.build_mode:
		preview_grid_position = world_to_grid(get_global_mouse_position())
		preview_valid = can_place(preview_grid_position)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_mode"):
		GameManager.toggle_build_mode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		if GameManager.build_mode:
			GameManager.cancel_build_mode()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("place_module") and GameManager.build_mode:
		try_place_basic_block(preview_grid_position)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_toggle_grid") and GameManager.debug_mode:
		show_grid = not show_grid
		queue_redraw()
		get_viewport().set_input_as_handled()

func world_to_grid(world_position: Vector2) -> Vector2i:
	var gx := floori(world_position.x / float(cell_size))
	var gy := floori((ground_y - world_position.y) / float(cell_size))
	return Vector2i(gx, gy)

func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(
		grid_position.x * cell_size + cell_size * 0.5,
		ground_y - grid_position.y * cell_size - cell_size * 0.5
	)

func can_place(grid_position: Vector2i) -> bool:
	if grid_position.y < 0:
		return false
	if occupied_cells.has(grid_position):
		return false
	# Prototype structural rule: ground blocks are valid, upper blocks require support below.
	if grid_position.y > 0:
		var below := Vector2i(grid_position.x, grid_position.y - 1)
		if not occupied_cells.has(below):
			return false
	if basic_block_scene == null:
		return false
	var cost := _get_basic_block_cost()
	return EconomyManager.can_afford(cost)

func try_place_basic_block(grid_position: Vector2i) -> bool:
	if not can_place(grid_position):
		return false
	var cost := _get_basic_block_cost()
	if not EconomyManager.spend_gold(cost):
		return false
	var module := basic_block_scene.instantiate() as BuildingModule
	if module == null:
		EconomyManager.add_gold(cost)
		push_error("Basic block scene does not instantiate a BuildingModule.")
		return false
	module.position = grid_to_world(grid_position)
	module.setup_grid_position(grid_position)
	add_child(module)
	_register_module(module)
	module_placed.emit(module, grid_position)
	queue_redraw()
	return true

func _register_existing_modules() -> void:
	for child in get_children():
		if child is BuildingModule:
			var module := child as BuildingModule
			if module.grid_position == Vector2i.ZERO:
				module.grid_position = world_to_grid(module.global_position)
			_register_module(module)

func _register_module(module: BuildingModule) -> void:
	occupied_cells[module.grid_position] = module
	if not module.module_destroyed.is_connected(_on_module_destroyed):
		module.module_destroyed.connect(_on_module_destroyed)

func _on_module_destroyed(module: BuildingModule) -> void:
	if occupied_cells.get(module.grid_position) == module:
		occupied_cells.erase(module.grid_position)
		module_removed.emit(module.grid_position)
	queue_redraw()

func _get_basic_block_cost() -> int:
	if basic_block_scene == null:
		return 0
	var temp := basic_block_scene.instantiate() as BuildingModule
	if temp == null:
		return 0
	var cost := temp.get_cost()
	temp.free()
	return cost

func _on_build_mode_changed(_enabled: bool) -> void:
	queue_redraw()

func _draw() -> void:
	if show_grid and GameManager.debug_mode:
		var viewport_rect := get_viewport_rect()
		var columns := ceili(viewport_rect.size.x / float(cell_size))
		for x in range(columns + 1):
			draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, ground_y), Color(1,1,1,0.08), 1.0)
		for y in range(10):
			var py := ground_y - y * cell_size
			draw_line(Vector2(0, py), Vector2(viewport_rect.size.x, py), Color(1,1,1,0.08), 1.0)

	if preview_enabled and GameManager.build_mode:
		var center := grid_to_world(preview_grid_position)
		var rect := Rect2(center - Vector2(cell_size, cell_size) * 0.47, Vector2(cell_size, cell_size) * 0.94)
		var color := Color(0.35, 0.85, 0.45, 0.35) if preview_valid else Color(0.9, 0.25, 0.25, 0.35)
		draw_rect(rect, color, true)
		draw_rect(rect, color.lightened(0.2), false, 2.0)

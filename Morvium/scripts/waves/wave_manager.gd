class_name WaveManager
extends Node

signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)

@export var zombie_scene: PackedScene
@export var base_enemy_count: int = 2
@export var time_between_spawns: float = 0.8
@export var time_between_waves: float = 3.0
@export var auto_start: bool = true
@export var left_spawn_x: float = 80.0
@export var right_spawn_x: float = 1200.0
@export var ground_spawn_y: float = 580.0

var current_wave: int = 0
var alive_enemies: int = 0
var spawning: bool = false

func _ready() -> void:
	if auto_start:
		call_deferred("_start_first_wave")

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.debug_mode:
		return
	if event.is_action_pressed("debug_spawn_zombie"):
		spawn_debug_zombie()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_kill_zombie"):
		kill_one_debug_zombie()
		get_viewport().set_input_as_handled()

func _start_first_wave() -> void:
	await get_tree().create_timer(1.0).timeout
	start_next_wave()

func start_next_wave() -> void:
	if spawning:
		return
	current_wave += 1
	var enemy_count := base_enemy_count + current_wave
	spawning = true
	wave_started.emit(current_wave, enemy_count)

	for i in range(enemy_count):
		_spawn_zombie(i % 2 == 0)
		await get_tree().create_timer(time_between_spawns).timeout

	spawning = false

func _spawn_zombie(from_left: bool) -> void:
	if zombie_scene == null:
		push_error("WaveManager has no zombie_scene assigned.")
		return
	var zombie := zombie_scene.instantiate() as BasicZombie
	if zombie == null:
		push_error("zombie_scene does not instantiate BasicZombie.")
		return

	var hp_multiplier := 1.0 + float(maxi(current_wave - 1, 0)) * 0.08
	if zombie.data != null:
		# Duplicate resource so scaling this zombie does not mutate the shared .tres.
		zombie.data = zombie.data.duplicate()
		zombie.data.max_health *= hp_multiplier

	zombie.global_position = Vector2(left_spawn_x if from_left else right_spawn_x, ground_spawn_y)
	get_tree().current_scene.add_child(zombie)
	alive_enemies += 1
	zombie.zombie_died.connect(_on_zombie_died)

func _on_zombie_died(_zombie: BasicZombie, _reward: int) -> void:
	alive_enemies = maxi(0, alive_enemies - 1)
	if alive_enemies == 0 and not spawning:
		wave_completed.emit(current_wave)
		await get_tree().create_timer(time_between_waves).timeout
		start_next_wave()

func spawn_debug_zombie() -> void:
	_spawn_zombie(true)

func kill_one_debug_zombie() -> void:
	var zombies := get_tree().get_nodes_in_group("zombies")
	if zombies.is_empty():
		return
	var zombie := zombies[0]
	if zombie is BasicZombie:
		(zombie as BasicZombie).die()

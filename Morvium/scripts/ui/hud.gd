class_name HUD
extends CanvasLayer

@onready var gold_label: Label = %GoldLabel
@onready var wave_label: Label = %WaveLabel
@onready var build_label: Label = %BuildLabel
@onready var debug_label: Label = %DebugLabel

func _ready() -> void:
	EconomyManager.gold_changed.connect(_on_gold_changed)
	GameManager.build_mode_changed.connect(_on_build_mode_changed)
	_on_gold_changed(EconomyManager.gold, 0)
	_on_build_mode_changed(GameManager.build_mode)

	var wave_manager := get_tree().get_first_node_in_group("wave_manager") as WaveManager
	if wave_manager != null:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_label.text = "Wave: %d" % wave_manager.current_wave

func _on_gold_changed(current_gold: int, _delta: int) -> void:
	gold_label.text = "Gold: %d" % current_gold

func _on_build_mode_changed(enabled: bool) -> void:
	build_label.text = "Build Mode: %s" % ("ON" if enabled else "OFF")

func _on_wave_started(wave_number: int, _enemy_count: int) -> void:
	wave_label.text = "Wave: %d" % wave_number

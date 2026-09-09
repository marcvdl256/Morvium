extends Node2D

func _ready() -> void:
	# Ensure the initial HUD receives the configured starting value after all nodes exist.
	EconomyManager.gold_changed.emit(EconomyManager.gold, 0)

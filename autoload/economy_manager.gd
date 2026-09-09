extends Node

signal gold_changed(current_gold: int, delta: int)

@export var starting_gold: int = 100
var gold: int = 0

func _ready() -> void:
	reset()

func reset() -> void:
	gold = starting_gold
	gold_changed.emit(gold, 0)

func can_afford(amount: int) -> bool:
	return amount >= 0 and gold >= amount

func spend_gold(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	gold -= amount
	gold_changed.emit(gold, -amount)
	return true

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold, amount)

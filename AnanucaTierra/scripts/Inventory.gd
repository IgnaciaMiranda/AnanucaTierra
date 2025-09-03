extends Node

# Inventario simple
var items := {
	"piedra": 0,
	"tierra": 0,
	"semilla_ananuca": 0,
	"flor_ananuca": 0
}

func add_item(item_name: String, amount: int = 1):
	if items.has(item_name):
		items[item_name] += amount
	else:
		items[item_name] = amount

func remove_item(item_name: String, amount: int = 1):
	if items.has(item_name):
		items[item_name] = max(0, items[item_name] - amount)

func get_count(item_name: String) -> int:
	return items.get(item_name, 0)

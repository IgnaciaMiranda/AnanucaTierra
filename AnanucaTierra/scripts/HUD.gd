extends CanvasLayer

# Referencias a los nodos UI
@onready var lbl_day = $DayLabel
@onready var lbl_season = $SeasonLabel
@onready var lbl_time = $TimeLabel
@onready var lbl_inventory = $InventoryLabel
@onready var lbl_objective = $ObjectiveLabel

# Ejemplo de conexión de señales desde World.gd
# world.connect("day_changed", self, "update_day")
# world.connect("season_changed", self, "update_season")
# world.connect("time_updated", self, "update_time")
# Para inventario y objetivo, llama directamente:
# update_inventory(inventory.items)
# update_objective(flores_florecidas, objetivo)

func update_day(day):
	lbl_day.text = "Día: %d" % day

func update_season(season):
	lbl_season.text = "Estación: %s" % season.capitalize()

func update_time(time):
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	#lbl_time.text = "Hora: %02d:%02d" % [minutes, seconds]

func update_inventory(items: Dictionary):
	var text = "Inventario:\n"
	for k in items.keys():
		text += "%s: %d\n" % [k.capitalize(), items[k]]
	lbl_inventory.text = text

func update_objective(count, goal):
	lbl_objective.text = "Añañucas florecidas: %d / %d" % [count, goal]

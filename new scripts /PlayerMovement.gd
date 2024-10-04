extends Node2D

var player_instance = null
var path = []
var path_index = 0
var current_teleport_probability = 0.0
var direction = 1

@export var TELEPORT_PROBABILITY_INCREMENT = 0.0002
@export var CAMPFIRE_PROBABILITY_INCREMENT = 0.02
@export var CHANGE_DIRECTION_PROBABILITY = 0.5

@onready var probability_bar = $ProbabilityBar
@onready var probability_label = $ProbabilityBar/Label
@onready var tombola_ui = $TombolaUI

func _ready():
    # Připojení signálu z tomboly
    tombola_ui.connect("number_drawn", Callable(self, "_on_tombola_ui_number_drawn"))

func move_along_path():
    if player_instance == null or path.size() == 0:
        return

    # Zvýšení pravděpodobnosti teleportace (Increase teleport probability)
    current_teleport_probability += TELEPORT_PROBABILITY_INCREMENT

    # Aktualizace ukazatele pravděpodobnosti (Update probability bar)
    update_probability_bar()

    # Náhodná šance na teleportaci (Random chance for teleportation)
    if randi() % 100 < current_teleport_probability * 100:
        teleport_player()
    else:
        # Posun hráče na další pozici v cestě (Move player to the next position in the path)
        path_index = (path_index + direction) % path.size()
        if path_index < 0:
            path_index = path.size() - 1
        var next_position = path_tilemap.map_to_local(path[path_index])
        player_instance.position = next_position

func move_player(steps):
    for i in range(steps):
        path_index = (path_index + direction) % path.size()
        if path_index < 0:
            path_index = path.size() - 1
        var next_position = path_tilemap.map_to_local(path[path_index])
        player_instance.position = next_position

        # Zvýšení pravděpodobnosti teleportace (Increase teleport probability)
        current_teleport_probability += TELEPORT_PROBABILITY_INCREMENT
        update_probability_bar()

        # Check if the player is on a campfire tile and increase probability
        var map_position = path_tilemap.local_to_map(player_instance.position)
        if path_tilemap.get_cell_source_id(0, map_position) == CAMPFIRE_TILE_ID:
            current_teleport_probability += CAMPFIRE_PROBABILITY_INCREMENT
            update_probability_bar()

        # Check for teleportation chance
        if randi() % 100 < current_teleport_probability * 100:
            teleport_player()
            break

        await get_tree().create_timer(0.2).timeout

    tombola_ui.enable_button() # Re-enable the button after the movement is completed

func _on_tombola_ui_number_drawn(number):
    move_player(number)

func teleport_player():
    # Teleport hráče na náhodnou pozici na cestě (Teleport player to a random position on the path)
    path_index = randi() % path.size()
    var next_position = path_tilemap.map_to_local(path[path_index])
    player_instance.position = next_position

    # Náhodná šance na změnu směru (Random chance to change direction)
    if randi() % 100 < CHANGE_DIRECTION_PROBABILITY * 100:
        direction *= -1

    # Reset pravděpodobnosti teleportace (Reset teleport probability)
    current_teleport_probability = 0.0
    update_probability_bar()

func update_probability_bar():
    # Aktualizace hodnoty ukazatele pravděpodobnosti (Update probability bar value)
    probability_bar.value = current_teleport_probability
    if probability_label != null:
        probability_label.text = str(round(current_teleport_probability * 10000) / 100.0) + "%"

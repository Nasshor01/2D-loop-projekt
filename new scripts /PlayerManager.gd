extends Node2D

@export var PlayerScene: PackedScene

var player_instance = null

@onready var campfire_tilemap = $PathTileMap

func _ready():
    if Global.player_data.has("position"):
        print("Obnovuji pozici hráče a mapu...")
        player_instance = PlayerScene.instantiate()
        player_instance.position = Global.player_data["position"]
        add_child(player_instance)
    else:
        var timer = Timer.new()
        timer.wait_time = 1.0
        timer.one_shot = true
        timer.connect("timeout", Callable(self, "find_campfire_and_spawn_player"))
        add_child(timer)
        timer.start()

func find_campfire_and_spawn_player():
    print("Starting find_campfire_and_spawn_player")

    # Get all positions of tiles with the campfire ID (CAMPFIRE_TILE_ID) in layer 0
    var campfire_positions = campfire_tilemap.get_used_cells_by_id(0, CAMPFIRE_TILE_ID)
    print("Found campfire positions: ", campfire_positions)

    # If at least one position is found, use the first one
    if campfire_positions.size() > 0:
        # Convert the coordinates to world coordinates
        var campfire_position = campfire_tilemap.map_to_local(campfire_positions[0])
        print("Campfire position found at: ", campfire_position)

        # Create an instance of the player and set its position to the campfire position
        player_instance = PlayerScene.instantiate()
        player_instance.position = campfire_position
        add_child(player_instance)

        print("Player spawned at campfire position: ", campfire_position)
    else:
        print("Campfire tile not found.")

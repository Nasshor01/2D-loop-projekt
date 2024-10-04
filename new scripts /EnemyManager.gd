extends Node2D

@export var SlimeScene: PackedScene

var slime_count = 0
var max_slimes = 5

@onready var path_tilemap = $PathTileMap

func _ready():
    # Přidání časovače pro spawn slima
    var slime_spawn_timer = Timer.new()
    slime_spawn_timer.wait_time = 5.0  # Spawnuje každých 5 sekund
    slime_spawn_timer.one_shot = false
    slime_spawn_timer.connect("timeout", Callable(self, "spawn_slime"))
    add_child(slime_spawn_timer)
    slime_spawn_timer.start()

func spawn_slime():
    if slime_count >= max_slimes:
        print("Max number of slimes reached.")
        return  # Zabrání dalšímu spawnování

    var spawnable_positions = path_tilemap.get_used_cells_by_id(PATH_TILE_ID)
    if spawnable_positions.size() > 0:
        var random_position = spawnable_positions[randi() % spawnable_positions.size()]
        var world_position = path_tilemap.map_to_local(random_position)

        var slime_instance = SlimeScene.instantiate()
        slime_instance.position = world_position
        add_child(slime_instance)

        # Zvýšení počítadla slimeů
        slime_count += 1
        print("Slime spawned at: ", world_position)
    else:
        print("No available positions to spawn slime.")

# Rozhraní pro hru po rozdelení skriptů na moduly

### Global.gd
```
# Global.gd slouží jako singleton pro sdílení dat mezi scénami.
extends Node

var player_data = {}  # Ukládá informace o stavu hráče
var enemy_data = {}   # Ukládá informace o stavu nepřátel
var saved_map_state = null  # Uložený stav mapy, použít při návratu z bitevní scény
```

### MapGeneration.gd
```
extends Node2D

# Velikost gridu (Grid size)
var grid_width = 20
var grid_height = 20

# ID dlaždic (Tile IDs)
const PATH_TILE_ID = 0
const CAMPFIRE_TILE_ID = 1

@onready var path_tilemap = $PathTileMap
@onready var campfire_tilemap = $PathTileMap

# Cesta ke scéně hráče
@export var PlayerScene: PackedScene

# Cesta ke Slime scéně
@export var SlimeScene: PackedScene
var slime_count = 0
var max_slimes = 5

# Cesta, kterou postava sleduje (Path the character follows)
var path = []
var path_index = 0
var player_instance = null

# Pravděpodobnost teleportace (Probability of teleportation)
@export var TELEPORT_PROBABILITY_INCREMENT = 0.0002
@export var CAMPFIRE_PROBABILITY_INCREMENT = 0.02
@export var CHANGE_DIRECTION_PROBABILITY = 0.5

# Aktuální pravděpodobnost teleportace (Current probability of teleportation)
var current_teleport_probability = 0.0

# Směr pohybu (Direction of movement)
var direction = 1

# Ukazatel pravděpodobnosti teleportace (Probability bar)
@onready var probability_bar = $ProbabilityBar
@onready var probability_label = $ProbabilityBar/Label

# Přidání tomboly
@onready var tombola_ui = $TombolaUI

func _ready():
    # Inicializuje generátor a spustí generování smyčky (Initializes generator and starts loop generation)
    if Global.player_data.has("position"):
        print("Obnovuji pozici hráče a mapu...")
        player_instance = PlayerScene.instantiate()
        player_instance.position = Global.player_data["position"]
        add_child(player_instance)
        path = Global.saved_map_state  # Obnovení stavu mapy
    else:
        print("Starting generation...")
        randomize()
        await generate_loop_path()
        print("Generation completed.")

    # Přidání časovače pro spawn hráče po 2 sekundách (Add timer to spawn player after 2 seconds)
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.one_shot = true
    timer.connect("timeout", Callable(self, "find_campfire_and_spawn_player"))
    add_child(timer)
    timer.start()

    # Přidání časovače pro spawn slima
    var slime_spawn_timer = Timer.new()
    slime_spawn_timer.wait_time = 5.0  # Spawnuje každých 5 sekund
    slime_spawn_timer.one_shot = false
    slime_spawn_timer.connect("timeout", Callable(self, "spawn_slime"))
    add_child(slime_spawn_timer)
    slime_spawn_timer.start()

    # Ověření, zda jsou uzly správně inicializovány
    if probability_label == null:
        print("Label not found")
    if probability_bar == null:
        print("ProbabilityBar not found")

    # Připojení signálu z tomboly
    tombola_ui.connect("number_drawn", Callable(self, "_on_tombola_ui_number_drawn"))

func generate_loop_path() -> void:
    # Generuje smyčku cesty v gridu (Generates loop path in the grid)
    if path_tilemap == null:
        print("PathTileMap not found.")
        return
    if campfire_tilemap == null:
        print("CampfireTileMap not found.")
        return

    print("TileMap nodes found.")

    # Inicializace gridu (Initialize grid)
    var map_grid = []
    for i in range(grid_width):
        map_grid.append([])
        for j in range(grid_height):
            map_grid[i].append(0)

    print("Grid initialized.")

    # Startovací pozice (více uprostřed) (Starting position, more centered)
    var start_x = randi() % 5 + 8
    var start_y = randi() % 5 + 8
    var x = start_x
    var y = start_y
    map_grid[x][y] = 1
    campfire_tilemap.set_cell(0, Vector2i(x, y), CAMPFIRE_TILE_ID, Vector2i(0, 0), 0) # pozice Atlas souřadnic ID1

    print("Starting position: ", x, y)

    # Generování smyčky cesty (Generate the loop path)
    var path_stack = [Vector2(x, y)]
    var loop_created = false
    var max_path_length = 50
    var next_x = x
    var next_y = y

    while not loop_created and path_stack.size() > 0:
        var current = path_stack[path_stack.size() - 1]
        x = int(current.x)
        y = int(current.y)

        var valid_directions = get_valid_directions(map_grid, x, y)

        if valid_directions.size() == 0:
            path_stack.pop_back()
            continue

        valid_directions.shuffle() # Zamíchat pro náhodnost (Shuffle to add randomness)
        for direction in valid_directions:
            next_x = x + int(direction.x) * 2
            next_y = y + int(direction.y) * 2

            if is_within_bounds(next_x, next_y) and map_grid[next_x][next_y] == 0 and map_grid[x + int(direction.x)][y + int(direction.y)] == 0:
                if not will_block_loop(map_grid, next_x, next_y):
                    map_grid[next_x][next_y] = 1
                    map_grid[x + int(direction.x)][y + int(direction.y)] = 1
                    path_tilemap.set_cell(0, Vector2i(next_x, next_y), PATH_TILE_ID, Vector2i(0, 1), 0)
                    path_tilemap.set_cell(0, Vector2i(x + int(direction.x), y + int(direction.y)), PATH_TILE_ID, Vector2i(0, 1), 0)
                    path_stack.append(Vector2(next_x, next_y))
                    await get_tree().create_timer(0.1).timeout

                    # Zkontrolovat uzavřenou smyčku nebo pokud je délka cesty větší než max_path_length (Check for closed loop or if path length is greater than max_path_length)
                    if (abs(next_x - start_x) <= 2 and abs(next_y - start_y) <= 2 and path_stack.size() > 10) or path_stack.size() > max_path_length:
                        # Pokusit se připojit zpět k táboráku (Try to connect back to campfire)
                        loop_created = connect_to_campfire(map_grid, path_tilemap, next_x, next_y, start_x, start_y)
                        if loop_created:
                            break
                    break

    print("Path rendering completed.")
    # Zajistit, že nezůstanou žádné slepé cesty (Ensure no dead ends remain)
    remove_dead_ends(map_grid)

    # Uložení cesty do proměnné path (Save path to the path variable)
    path = extract_path_from_grid(map_grid, start_x, start_y)
    return

func get_valid_directions(grid, x, y):
    # Získá platné směry pro rozšíření cesty (Gets valid directions for extending the path)
    var directions = []
    if is_within_bounds(x - 2, y) and grid[x - 2][y] == 0 and grid[x - 1][y] == 0:
        directions.append(Vector2(-1, 0))  # Vlevo (Left)
    if is_within_bounds(x + 2, y) and grid[x + 2][y] == 0 and grid[x + 1][y] == 0:
        directions.append(Vector2(1, 0))  # Vpravo (Right)
    if is_within_bounds(x, y - 2) and grid[x][y - 2] == 0 and grid[x][y - 1] == 0:
        directions.append(Vector2(0, -1))  # Nahoru (Up)
    if is_within_bounds(x, y + 2) and grid[x][y + 2] == 0 and grid[x][y + 1] == 0:
        directions.append(Vector2(0, 1))  # Dolů (Down)
    return directions

func is_within_bounds(x, y):
    # Kontroluje, zda jsou souřadnice uvnitř hranic gridu (Checks if the coordinates are within the grid boundaries)
    return x > 0 and x < grid_width - 1 and y > 0 and y < grid_height - 1

func connect_to_campfire(grid, tilemap, x, y, start_x, start_y):
    # Pokouší se připojit cestu zpět k táboráku (Attempts to connect the path back to the campfire)
    var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
    for direction in directions:
        var next_x = x + int(direction.x)
        var next_y = y + int(direction.y)
        if is_within_bounds(next_x, next_y) and abs(next_x - start_x) <= 1 and abs(next_y - start_y) <= 1:
            grid[next_x][next_y] = 1
            tilemap.set_cell(0, Vector2i(next_x, next_y), PATH_TILE_ID, Vector2i(0, 1), 0)
            return true
    return false

func will_block_loop(grid, x, y):
    # Kontroluje, zda přidání cesty zablokuje smyčku (Checks if adding a path will block the loop)
    var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
    var count = 0
    for direction in directions:
        var nx = x + int(direction.x)
        var ny = y + int(direction.y)
        if is_within_bounds(nx, ny) and grid[nx][ny] == 1:
            count += 1
    return count >= 2

func remove_dead_ends(grid):
    # Odstraňuje slepé cesty z gridu (Removes dead ends from the grid)
    var changes_made = true
    while changes_made:
        changes_made = false
        for x in range(grid_width):
            for y in range(grid_height):
                if grid[x][y] == 1 and count_adjacent_paths(grid, x, y) == 1:
                    grid[x][y] = 0
                    path_tilemap.set_cell(0, Vector2i(x, y), -1)
                    changes_made = true

func count_adjacent_paths(grid, x, y):
    # Počítá sousední cesty (Counts adjacent paths)
    var count = 0
    var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
    for direction in directions:
        var nx = x + int(direction.x)
        var ny = y + int(direction.y)
        if is_within_bounds(nx, ny) and grid[nx][ny] == 1:
            count += 1
    return count

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

    tombola_ui.enable_button() # Enable the button after the player has spawned

func extract_path_from_grid(grid, start_x, start_y):
    # Vytvoří seznam souřadnic cesty začínající od táboráku (Creates a list of path coordinates starting from the campfire)
    var path_coords = []
    var current_position = Vector2(start_x, start_y)
    var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
    var visited = []
    while true:
        path_coords.append(current_position)
        visited.append(current_position)
        var next_position = null
        for direction in directions:
            var nx = current_position.x + direction.x
            var ny = current_position.y + direction.y
            if is_within_bounds(nx, ny) and grid[nx][ny] == 1 and not Vector2(nx, ny) in visited:
                next_position = Vector2(nx, ny)
                break
        if next_position == null:
            break
        current_position = next_position
    return path_coords

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
```

### BaseEnemy.gd
```
extends CharacterBody2D

@export var max_hp = 50
@export var attack = 10
@export var attack_speed = 1.0
@export var move_speed = 100

var hp
var is_moving = false
var start_position = Vector2()

func _ready():
    hp = max_hp
    add_to_group("Enemy")
    $Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
    start_position = global_position

func take_damage(amount: int):
    hp -= amount
    if hp <= 0:
        die()

func die():
    queue_free()

func _on_body_entered(body):
    if body.is_in_group("Player"):
        # Zahájení souboje s hráčem
        Global.player_data["position"] = body.global_position
        Global.enemy_data = {
            "hp": hp,
            "max_hp": max_hp,
            "attack": attack,
            "attack_speed": attack_speed
        }
        get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")
```

### Slime.gd (specifický nepřítel)
```
extends "res://Scripts/BaseEnemy.gd"

@export var max_hp = 30
@export var attack = 5
@export var attack_speed = 1.5
```

### BasePlayer.gd
```
extends CharacterBody2D

@export var max_hp = 100
@export var attack = 35
@export var attack_speed = 1.5
@export var move_speed = 200

var hp
var is_moving = false
var path_positions = []
var current_path_index = 0

func _ready():
    hp = max_hp
    add_to_group("Player")

func _physics_process(delta):
    if is_moving and path_positions.size() > 0:
        move_along_path(delta)

func set_path(new_path, start_index = 0):
    path_positions = new_path
    current_path_index = start_index

func move_along_path(_delta):
    if path_positions.size() == 0:
        return

    var target_position = path_positions[current_path_index]
    var direction_vector = (target_position - global_position).normalized()

    velocity = direction_vector * move_speed
    move_and_slide()

    if global_position.distance_to(target_position) < 10:
        current_path_index = (current_path_index + 1) % path_positions.size()
```

### SpecificPlayer.gd (např. Knight.gd)
```
extends "res://Scripts/BasePlayer.gd"

@export var max_hp = 150
@export var attack = 45
@export var attack_speed = 1.2
```

### BattleScene.gd (upravená verze)
```
extends Control

@export var PlayerScene: PackedScene
@export var EnemyScene: PackedScene

@onready var player_hp_bar = $PlayerHPBar
@onready var enemy_hp_bar = $EnemyHPBar

signal battle_ended(winner)

var player_instance
var enemy_instance

func _ready():
    player_instance = PlayerScene.instantiate()
    enemy_instance = EnemyScene.instantiate()

    add_child(player_instance)
    add_child(enemy_instance)

    player_instance.position = Vector2(100, 200)
    enemy_instance.position = Vector2(300, 200)

    player_hp_bar.max_value = player_instance.max_hp
    player_hp_bar.value = player_instance.hp
    enemy_hp_bar.max_value = enemy_instance.max_hp
    enemy_hp_bar.value = enemy_instance.hp

    start_combat()

func start_combat():
    var player_timer = Timer.new()
    player_timer.wait_time = player_instance.attack_speed
    player_timer.one_shot = false
    player_timer.connect("timeout", Callable(self, "_on_player_attack"))
    add_child(player_timer)
    player_timer.start()

    var enemy_timer = Timer.new()
    enemy_timer.wait_time = enemy_instance.attack_speed
    enemy_timer.one_shot = false
    enemy_timer.connect("timeout", Callable(self, "_on_enemy_attack"))
    add_child(enemy_timer)
    enemy_timer.start()

func _on_player_attack():
    enemy_instance.take_damage(player_instance.attack)
    update_hp_bars()
    if enemy_instance.hp <= 0:
        end_battle("player")

func _on_enemy_attack():
    player_instance.take_damage(enemy_instance.attack)
    update_hp_bars()
    if player_instance.hp <= 0:
        end_battle("enemy")

func update_hp_bars():
    player_hp_bar.value = player_instance.hp
    enemy_hp_bar.value = enemy_instance.hp

func end_battle(winner):
    emit_signal("battle_ended", winner)
    player_instance.queue_free()
    enemy_instance.queue_free()
    $PlayerTimer.stop()
    $EnemyTimer.stop()
    queue_free()  # Uzavření pop-up okna bitvy
```

### TombolaUI.gd
```
extends Control

@onready var tombola = $AnimatedSprite2D
@onready var draw_button = $Button
@onready var result_label = $Label

@export var min_number = 1
@export var max_number = 24

signal number_drawn(number)

func _ready():
    result_label.visible = false
    draw_button.disabled = true
    draw_button.connect("pressed", Callable(self, "_on_draw_button_pressed"))

func enable_button():
    draw_button.disabled = false

func disable_button():
    draw_button.disabled = true

func _on_draw_button_pressed():
    disable_button()
    tombola.play("default")
    result_label.visible = false

    var frame_count = tombola.sprite_frames.get_frame_count("default")
    var fps = tombola.sprite_frames.get_animation_speed("default")
    var animation_duration = frame_count / fps

    await get_tree().create_timer(animation_duration).timeout

    var drawn_number = randi() % (max_number - min_number + 1) + min_number
    result_label.text = str(drawn_number)
    result_label.visible = true
    emit_signal("number_drawn", drawn_number)
    enable_button()
```

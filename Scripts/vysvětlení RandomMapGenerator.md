
---

## Overview

- **Purpose**: Generate a looping path within a grid-based map, spawn a player character, and control their movement along the path with increasing teleportation probabilities.
- **Key Components**:
  - Grid-based path generation.
  - Player instantiation and movement.
  - Teleportation mechanics influenced by probabilities.
  - User Interface elements for displaying teleportation probabilities.
  - Integration with a "tombola" UI that influences player movement.

---

## Script Structure

### Extending Node2D

```gdscript
extends Node2D
```

- The script extends the `Node2D` class, making it a 2D node within the Godot scene tree.

### Variables and Constants

#### Grid Dimensions

```gdscript
var grid_width = 20
var grid_height = 20
```

- Defines the size of the grid map (20x20 tiles).

#### Tile IDs

```gdscript
const PATH_TILE_ID = 0
const CAMPFIRE_TILE_ID = 1
```

- Constants representing the IDs for different types of tiles:
  - `PATH_TILE_ID`: Identifier for path tiles.
  - `CAMPFIRE_TILE_ID`: Identifier for the campfire tile.

#### TileMap Nodes

```gdscript
@onready var path_tilemap = $PathTileMap
@onready var campfire_tilemap = $PathTileMap
```

- References to the `TileMap` nodes in the scene:
  - Both variables currently reference the same `TileMap` node, `$PathTileMap`. This might be intentional if both path and campfire tiles are on the same `TileMap`.

#### Player Scene

```gdscript
@export var PlayerScene: PackedScene
```

- An exported variable that holds a reference to the player character's scene (`PackedScene`). This allows it to be set from the Godot editor.

#### Path and Player Variables

```gdscript
var path = []
var path_index = 0
var player_instance = null
```

- `path`: An array storing the coordinates of the generated path.
- `path_index`: Tracks the player's current position along the path.
- `player_instance`: Holds the instance of the player character once it is spawned.

#### Teleportation Probabilities

```gdscript
@export var TELEPORT_PROBABILITY_INCREMENT = 0.0002
@export var CAMPFIRE_PROBABILITY_INCREMENT = 0.02
@export var CHANGE_DIRECTION_PROBABILITY = 0.5
```

- Variables controlling how the probability of teleportation increases:
  - `TELEPORT_PROBABILITY_INCREMENT`: Increment added to the teleportation probability each step.
  - `CAMPFIRE_PROBABILITY_INCREMENT`: Additional increment when the player is on a campfire tile.
  - `CHANGE_DIRECTION_PROBABILITY`: Probability that the player's movement direction will reverse upon teleportation.

#### Current Teleportation Probability

```gdscript
var current_teleport_probability = 0.0
```

- Tracks the current probability that the player will teleport during movement.

#### Movement Direction

```gdscript
var direction = 1
```

- Controls the direction of the player's movement along the path:
  - `1`: Moves forward along the path.
  - `-1`: Moves backward along the path.

#### UI Elements

```gdscript
@onready var probability_bar = $ProbabilityBar
@onready var probability_label = $ProbabilityBar/Label
@onready var tombola_ui = $TombolaUI
```

- References to UI elements in the scene:
  - `probability_bar`: A progress bar displaying the current teleportation probability.
  - `probability_label`: A label showing the numerical probability percentage.
  - `tombola_ui`: The "tombola" UI node, which interacts with player movement.

---

## Initialization (`_ready` Function)

```gdscript
func _ready():
    # Initializes the random number generator and starts path generation
    print("Starting generation...")
    randomize()
    await generate_loop_path()
    print("Generation completed.")

    # Spawns the player after a delay
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.one_shot = true
    timer.connect("timeout", Callable(self, "find_campfire_and_spawn_player"))
    add_child(timer)
    timer.start()

    # Checks if UI elements are properly initialized
    if probability_label == null:
        print("Label not found")
    if probability_bar == null:
        print("ProbabilityBar not found")

    # Connects the tombola UI signal to the movement function
    tombola_ui.connect("number_drawn", Callable(self, "_on_tombola_ui_number_drawn"))
```

- **Randomization**: Calls `randomize()` to seed the random number generator.
- **Path Generation**: Asynchronously calls `generate_loop_path()` to create the path.
- **Player Spawning**: Sets up a one-shot timer to delay player spawning by 1 second, calling `find_campfire_and_spawn_player()` upon timeout.
- **UI Checks**: Verifies that the probability bar and label are correctly referenced.
- **Signal Connection**: Connects the `number_drawn` signal from the tombola UI to the `_on_tombola_ui_number_drawn()` function, which handles player movement based on numbers drawn.

---

## Path Generation (`generate_loop_path` Function)

```gdscript
func generate_loop_path() -> void:
    # Validates the TileMap nodes
    if path_tilemap == null:
        print("PathTileMap not found.")
        return
    if campfire_tilemap == null:
        print("CampfireTileMap not found.")
        return

    print("TileMap nodes found.")

    # Initializes the grid with zeros
    var map_grid = []
    for i in range(grid_width):
        map_grid.append([])
        for j in range(grid_height):
            map_grid[i].append(0)

    print("Grid initialized.")

    # Sets a starting position near the center
    var start_x = randi() % 5 + 8
    var start_y = randi() % 5 + 8
    var x = start_x
    var y = start_y
    map_grid[x][y] = 1
    campfire_tilemap.set_cell(0, Vector2i(x, y), CAMPFIRE_TILE_ID, Vector2i(0, 0), 0)

    print("Starting position: ", x, y)

    # Initializes variables for path generation
    var path_stack = [Vector2(x, y)]
    var loop_created = false
    var max_path_length = 50
    var next_x = x
    var next_y = y

    # Begins path generation loop
    while not loop_created and path_stack.size() > 0:
        var current = path_stack[path_stack.size() - 1]
        x = int(current.x)
        y = int(current.y)

        var valid_directions = get_valid_directions(map_grid, x, y)

        if valid_directions.size() == 0:
            path_stack.pop_back()
            continue

        valid_directions.shuffle()  # Adds randomness to path direction
        for direction in valid_directions:
            next_x = x + int(direction.x) * 2
            next_y = y + int(direction.y) * 2

            if is_within_bounds(next_x, next_y) and map_grid[next_x][next_y] == 0 and map_grid[x + int(direction.x)][y + int(direction.y)] == 0:
                if not will_block_loop(map_grid, next_x, next_y):
                    # Marks the path in the grid and updates the TileMap
                    map_grid[next_x][next_y] = 1
                    map_grid[x + int(direction.x)][y + int(direction.y)] = 1
                    path_tilemap.set_cell(0, Vector2i(next_x, next_y), PATH_TILE_ID, Vector2i(0, 1), 0)
                    path_tilemap.set_cell(0, Vector2i(x + int(direction.x), y + int(direction.y)), PATH_TILE_ID, Vector2i(0, 1), 0)
                    path_stack.append(Vector2(next_x, next_y))
                    await get_tree().create_timer(0.1).timeout

                    # Checks if the loop is closed or if the maximum path length is reached
                    if (abs(next_x - start_x) <= 2 and abs(next_y - start_y) <= 2 and path_stack.size() > 10) or path_stack.size() > max_path_length:
                        loop_created = connect_to_campfire(map_grid, path_tilemap, next_x, next_y, start_x, start_y)
                        if loop_created:
                            break
                    break

    print("Path rendering completed.")
    # Removes any dead ends from the path
    remove_dead_ends(map_grid)

    # Extracts the path coordinates and saves them to the `path` variable
    path = extract_path_from_grid(map_grid, start_x, start_y)
    return
```

- **Grid Initialization**: Creates a 2D array (`map_grid`) representing the grid, initializing all cells to `0`.
- **Starting Position**: Randomly selects a starting position near the center of the grid and marks it as the campfire tile.
- **Path Generation Loop**:
  - Uses a stack (`path_stack`) to keep track of the path.
  - At each step, it gets valid directions to extend the path.
  - Randomly shuffles directions to add variability.
  - Checks if adding a path in a certain direction is valid (doesn't create loops that block the path).
  - Marks new path cells in both the grid and the `TileMap`.
  - Checks if the loop can be closed back to the campfire or if the maximum path length is reached.
- **Dead End Removal**: Calls `remove_dead_ends()` to clean up the path.
- **Path Extraction**: Calls `extract_path_from_grid()` to get a list of path coordinates starting from the campfire.

### Helper Functions for Path Generation

#### `get_valid_directions`

```gdscript
func get_valid_directions(grid, x, y):
    # Returns valid directions for extending the path from the current position
    var directions = []
    if is_within_bounds(x - 2, y) and grid[x - 2][y] == 0 and grid[x - 1][y] == 0:
        directions.append(Vector2(-1, 0))  # Left
    if is_within_bounds(x + 2, y) and grid[x + 2][y] == 0 and grid[x + 1][y] == 0:
        directions.append(Vector2(1, 0))   # Right
    if is_within_bounds(x, y - 2) and grid[x][y - 2] == 0 and grid[x][y - 1] == 0:
        directions.append(Vector2(0, -1))  # Up
    if is_within_bounds(x, y + 2) and grid[x][y + 2] == 0 and grid[x][y + 1] == 0:
        directions.append(Vector2(0, 1))   # Down
    return directions
```

- **Purpose**: Determines which directions the path can be extended to from the current cell.
- **Mechanism**: Checks two cells ahead to prevent immediate backtracking or creating adjacent paths that could block movement.

#### `is_within_bounds`

```gdscript
func is_within_bounds(x, y):
    # Checks if the coordinates are within the grid boundaries
    return x > 0 and x < grid_width - 1 and y > 0 and y < grid_height - 1
```

- **Purpose**: Ensures that the path does not go outside the grid limits.

#### `connect_to_campfire`

```gdscript
func connect_to_campfire(grid, tilemap, x, y, start_x, start_y):
    # Attempts to connect the current path back to the campfire
    var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
    for direction in directions:
        var next_x = x + int(direction.x)
        var next_y = y + int(direction.y)
        if is_within_bounds(next_x, next_y) and abs(next_x - start_x) <= 1 and abs(next_y - start_y) <= 1:
            grid[next_x][next_y] = 1
            tilemap.set_cell(0, Vector2i(next_x, next_y), PATH_TILE_ID, Vector2i(0, 1), 0)
            return true
    return false
```

- **Purpose**: Tries to close the loop by connecting the current path back to the campfire tile.

#### `will_block_loop`

```gdscript
func will_block_loop(grid, x, y):
    # Checks if adding a path at the specified location will create a blockage
    var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
    var count = 0
    for direction in directions:
        var nx = x + int(direction.x)
        var ny = y + int(direction.y)
        if is_within_bounds(nx, ny) and grid[nx][ny] == 1:
            count += 1
    return count >= 2
```

- **Purpose**: Prevents the creation of path segments that would block the loop by checking if the new cell would have two or more adjacent path cells.

#### `remove_dead_ends`

```gdscript
func remove_dead_ends(grid):
    # Iteratively removes dead ends from the grid
    var changes_made = true
    while changes_made:
        changes_made = false
        for x in range(grid_width):
            for y in range(grid_height):
                if grid[x][y] == 1 and count_adjacent_paths(grid, x, y) == 1:
                    grid[x][y] = 0
                    path_tilemap.set_cell(0, Vector2i(x, y), -1)
                    changes_made = true
```

- **Purpose**: Cleans up the path by removing dead ends, ensuring a continuous loop without any dangling paths.

#### `count_adjacent_paths`

```gdscript
func count_adjacent_paths(grid, x, y):
    # Counts the number of adjacent path cells
    var count = 0
    var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
    for direction in directions:
        var nx = x + int(direction.x)
        var ny = y + int(direction.y)
        if is_within_bounds(nx, ny) and grid[nx][ny] == 1:
            count += 1
    return count
```

- **Purpose**: Helper function for `remove_dead_ends()` to determine if a cell is a dead end (only one adjacent path).

#### `extract_path_from_grid`

```gdscript
func extract_path_from_grid(grid, start_x, start_y):
    # Extracts the path coordinates starting from the campfire
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
```

- **Purpose**: Creates an ordered list of path coordinates by traversing the path starting from the campfire.
- **Mechanism**: Uses depth-first search to traverse the path without revisiting cells.

---

## Player Spawning (`find_campfire_and_spawn_player` Function)

```gdscript
func find_campfire_and_spawn_player():
    print("Starting find_campfire_and_spawn_player")

    # Retrieves the positions of campfire tiles
    var campfire_positions = campfire_tilemap.get_used_cells_by_id(0, CAMPFIRE_TILE_ID)
    print("Found campfire positions: ", campfire_positions)

    # Spawns the player at the campfire position
    if campfire_positions.size() > 0:
        var campfire_position = campfire_tilemap.map_to_local(campfire_positions[0])
        print("Campfire position found at: ", campfire_position)

        player_instance = PlayerScene.instantiate()
        player_instance.position = campfire_position
        add_child(player_instance)

        print("Player spawned at campfire position: ", campfire_position)
    else:
        print("Campfire tile not found.")

    tombola_ui.enable_button()  # Enables the tombola button after player spawn
```

- **Purpose**: Instantiates the player character and places them at the campfire tile.
- **Mechanism**:
  - Searches for tiles with `CAMPFIRE_TILE_ID`.
  - Converts the tilemap coordinates to world coordinates.
  - Instantiates the player scene and adds it as a child node.
  - Enables the tombola UI button to allow user interaction.

---

## Player Movement Mechanics

### Movement Function (`move_player`)

```gdscript
func move_player(steps):
    for i in range(steps):
        path_index = (path_index + direction) % path.size()
        if path_index < 0:
            path_index = path.size() - 1
        var next_position = path_tilemap.map_to_local(path[path_index])
        player_instance.position = next_position

        # Increases teleportation probability
        current_teleport_probability += TELEPORT_PROBABILITY_INCREMENT
        update_probability_bar()

        # Checks if on a campfire tile and increases probability
        var map_position = path_tilemap.local_to_map(player_instance.position)
        if path_tilemap.get_cell_source_id(0, map_position) == CAMPFIRE_TILE_ID:
            current_teleport_probability += CAMPFIRE_PROBABILITY_INCREMENT
            update_probability_bar()

        # Checks for teleportation
        if randi() % 100 < current_teleport_probability * 100:
            teleport_player()
            break

        await get_tree().create_timer(0.2).timeout

    tombola_ui.enable_button()  # Re-enables the tombola button after movement
```

- **Purpose**: Moves the player along the path based on the number of steps determined by the tombola UI.
- **Mechanism**:
  - Updates the player's position along the path array.
  - Increases the teleportation probability with each step.
  - Checks if the player is on a campfire tile to add an additional probability increment.
  - Randomly determines if teleportation occurs based on the current probability.
  - Adds a delay between steps to animate movement.
  - Re-enables the tombola UI button after movement is completed.

### Tombola UI Interaction (`_on_tombola_ui_number_drawn`)

```gdscript
func _on_tombola_ui_number_drawn(number):
    move_player(number)
```

- **Purpose**: Triggered when the tombola UI emits the `number_drawn` signal.
- **Mechanism**: Calls `move_player()` with the drawn number, which moves the player accordingly.

### Teleportation (`teleport_player`)

```gdscript
func teleport_player():
    # Teleports the player to a random position on the path
    path_index = randi() % path.size()
    var next_position = path_tilemap.map_to_local(path[path_index])
    player_instance.position = next_position

    # Random chance to change movement direction
    if randi() % 100 < CHANGE_DIRECTION_PROBABILITY * 100:
        direction *= -1

    # Resets teleportation probability
    current_teleport_probability = 0.0
    update_probability_bar()
```

- **Purpose**: Handles the teleportation of the player to a random location on the path.
- **Mechanism**:
  - Selects a random index in the `path` array and moves the player there.
  - Has a chance to reverse the player's movement direction.
  - Resets the teleportation probability to zero.
  - Updates the probability bar and label.

---

## UI Updates

### Probability Bar Update (`update_probability_bar`)

```gdscript
func update_probability_bar():
    # Updates the probability bar and label with the current probability
    probability_bar.value = current_teleport_probability
    if probability_label != null:
        probability_label.text = str(round(current_teleport_probability * 10000) / 100.0) + "%"
```

- **Purpose**: Reflects changes in the teleportation probability on the UI.
- **Mechanism**:
  - Sets the value of the probability bar to `current_teleport_probability`.
  - Updates the label to display the probability as a percentage with two decimal places.

---

## Summary

- The script creates a looping path on a grid and spawns a player at a campfire tile.
- Player movement is controlled via a tombola UI, which determines the number of steps to move.
- With each movement, the probability of teleportation increases.
- Teleportation mechanics include resetting the probability and possibly changing the movement direction.
- UI elements provide visual feedback on teleportation probabilities.
- The code includes robust path generation and cleanup to ensure a seamless player experience.

---

## Potential Improvements and Considerations

- **TileMap References**: Both `path_tilemap` and `campfire_tilemap` reference `$PathTileMap`. If campfire tiles are on a separate `TileMap`, this should be adjusted.
- **Random Seed**: Calling `randomize()` ensures different random sequences each run. For reproducibility during testing, consider setting a fixed seed.
- **Error Handling**: The code checks for null references to UI elements. Additional error handling could be added for robustness.
- **Optimization**: The path extraction and dead-end removal functions could be optimized for larger grids.
- **User Feedback**: Consider adding animations or effects when teleportation occurs to enhance user experience.

---

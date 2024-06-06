extends Node3D

@export var tile_scene: PackedScene
var path_points = []
var tile_size = Vector3(4, 0, 4)  # Velikost dlaždice
var grid = {}
var directions = [
    Vector3(tile_size.x, 0, 0),  # Right
    Vector3(-tile_size.x, 0, 0),  # Left
    Vector3(0, 0, tile_size.z),  # Forward
    Vector3(0, 0, -tile_size.z)  # Backward
]
var area_size = 50  # Velikost oblasti 50x50 metrů
var max_attempts = 1000  # Maximální počet pokusů

func _ready():
    print("Starting to generate path")
    var success = generate_closed_loop(Vector3(rand_range(-area_size / 2, area_size / 2), 0, rand_range(-area_size / 2, area_size / 2)))
    if success:
        create_path_tiles()
    else:
        print("Failed to generate a path")

func generate_closed_loop(start: Vector3) -> bool:
    print("Generating closed loop")
    path_points.clear()
    grid.clear()
    path_points.append(start)
    grid[vec_to_key(start)] = true

    var current_position = start
    var steps = 0
    while steps < max_attempts:  # Limit to prevent infinite loops
        var next_position = get_next_position(current_position)
        var attempts = 0
        while (not is_valid_position(next_position) or not is_valid_turn(current_position, next_position) or not has_free_neighbors(current_position, next_position)) and attempts < 100:
            next_position = get_next_position(current_position)
            attempts += 1

        if attempts >= 100:
            print("Failed to find a valid next position after 100 attempts at step", steps)
            return false

        path_points.append(next_position)
        grid[vec_to_key(next_position)] = true
        current_position = next_position
        steps += 1
        print("Step", steps, ": Moved to", next_position)

        if count_neighbors(start) == 2 and current_position.distance_to(start) <= tile_size.length():
            print("Closed loop generated successfully after", steps, "steps")
            return true

    return false

func get_next_position(current_position: Vector3) -> Vector3:
    var valid_directions = []
    for direction in directions:
        var next_position = current_position + direction
        if is_valid_position(next_position) and count_neighbors(next_position) == 0:
            valid_directions.append(direction)
    
    if valid_directions.size() == 0:
        return current_position + directions[randi() % directions.size()]

    return current_position + valid_directions[randi() % valid_directions.size()]

func is_valid_position(position: Vector3) -> bool:
    return not grid.has(vec_to_key(position)) and within_bounds(position)

func is_valid_turn(current_position: Vector3, next_position: Vector3) -> bool:
    if path_points.size() < 2:
        return true  # First move is always valid

    var last_direction = (current_position - path_points[path_points.size() - 2]).normalized()
    var new_direction = (next_position - current_position).normalized()
    return last_direction != -new_direction  # Check if the turn is not 180 degrees

func has_free_neighbors(current_position: Vector3, next_position: Vector3) -> bool:
    var free_neighbors = 0
    for direction in directions:
        var neighbor = next_position + direction
        if not grid.has(vec_to_key(neighbor)) and neighbor != current_position:
            free_neighbors += 1
    return free_neighbors == 2

func within_bounds(position: Vector3) -> bool:
    return abs(position.x) <= area_size / 2 and abs(position.z) <= area_size / 2

func vec_to_key(vec: Vector3) -> String:
    return str(vec.x) + "_" + str(vec.y) + "_" + str(vec.z)

func count_neighbors(pos: Vector3) -> int:
    var count = 0
    for direction in directions:
        if grid.has(vec_to_key(pos + direction)):
            count += 1
    return count

func create_path_tiles():
    if path_points.size() == 0:
        print("No path points to create tiles")
        return

    for i in range(path_points.size() - 1):
        var start_point = path_points[i]
        var end_point = path_points[i + 1]
        print("Creating path segment from ", start_point, " to ", end_point)
        create_path_segment(start_point, end_point)

func create_path_segment(start: Vector3, end: Vector3):
    var direction = (end - start).normalized() * tile_size.length()
    var current_position = start

    while current_position.distance_to(start) < start.distance_to(end):
        var tile_instance = tile_scene.instantiate()
        if tile_instance == null:
            print("Failed to instantiate tile_scene")
            return
        tile_instance.transform.origin = current_position
        tile_instance.transform.origin.y = 0  # Udržet dlaždice na zemi
        add_child(tile_instance)
        current_position += direction

    # Add the last tile to ensure full coverage
    var last_tile_instance = tile_scene.instantiate()
    if last_tile_instance == null:
        print("Failed to instantiate last tile")
        return
    last_tile_instance.transform.origin = end
    last_tile_instance.transform.origin.y = 0  # Udržet dlaždice na zemi
    add_child(last_tile_instance)

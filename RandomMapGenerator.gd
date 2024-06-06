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
    while steps < 1000:  # Limit to prevent infinite loops
        var next_position = get_next_position(current_position)
        var attempts = 0
        while (grid.has(vec_to_key(next_position)) or count_neighbors(next_position) > 1 or not within_bounds(next_position)) and attempts < 100:
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

        # Random chance to check if we should try to close the loop
        if steps > 10 and randi() % 10 < 2:  # 20% šance pokusit se uzavřít smyčku po 10 krocích
            if is_path_closed(start):
                print("Closed loop generated successfully after", steps, "steps")
                return true

    # Zkuste uzavřít smyčku po dosažení maximálního počtu kroků
    return is_path_closed(start)

func get_next_position(current_position: Vector3) -> Vector3:
    var valid_directions = []
    for direction in directions:
        var next_position = current_position + direction
        if not grid.has(vec_to_key(next_position)) and count_neighbors(next_position) == 1 and within_bounds(next_position):
            valid_directions.append(direction)
    
    if valid_directions.size() == 0:
        return current_position + directions[randi() % directions.size()]

    return current_position + valid_directions[randi() % valid_directions.size()]

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

func is_path_closed(start: Vector3) -> bool:
    return path_points.size() > 1 and path_points[path_points.size() - 1].distance_to(start) <= tile_size.length()

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

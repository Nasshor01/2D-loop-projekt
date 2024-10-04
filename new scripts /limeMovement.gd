extends CharacterBody2D

const TILE_SIZE = 64
var start_position = Vector2()
var max_distance = 3 * TILE_SIZE
var move_speed = 100
var is_moving = false
var move_direction = Vector2.ZERO

func _ready():
    add_to_group("Enemy")
    $Area2D.connect("body_entered", Callable(self, "_on_body_entered"))

func start_moving():
    is_moving = true
    start_position = global_position
    move_direction = Vector2.RIGHT.rotated(randf_range(0, PI * 2)).normalized()

func _physics_process(delta):
    if is_moving:
        move_along_path(delta)

func move_along_path(delta):
    if global_position.distance_to(start_position) >= max_distance:
        move_direction = (start_position - global_position).normalized()
    else:
        if randf() < 0.01:
            move_direction = Vector2.RIGHT.rotated(randf_range(0, PI * 2)).normalized()
    
    velocity = move_direction * move_speed
    move_and_slide()

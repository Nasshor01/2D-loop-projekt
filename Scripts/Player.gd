extends CharacterBody2D

@export var hp = 100
@export var max_hp = 100
@export var attack_speed = 1.5
@export var attack = 35

var path_positions = []
var current_path_index = 0
var move_speed = 200  # Rychlost pohybu hráče
var is_moving = false
var direction = 1  # Směr pohybu podél cesty (1 nebo -1)

func _ready():
	add_to_group("Player")
	# Nastavení dalších parametrů hráče
	pass

func _physics_process(delta):
	if is_moving and path_positions.size() > 0:
		move_along_path(delta)

func start_moving():
	is_moving = true

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
	
	# Kontrola, zda jsme dosáhli cílové pozice
	if global_position.distance_to(target_position) < 10:
		current_path_index = (current_path_index + direction) % path_positions.size()
		if current_path_index < 0:
			current_path_index = path_positions.size() - 1

func change_direction():
	direction *= -1

extends CharacterBody2D

@export var hp = 50
@export var max_hp = 50
@export var attack_speed = 0.3
@export var attack = 10

var start_position = Vector2()
const TILE_SIZE = 64  # Nastavte podle velikosti vašich dlaždic
var max_distance = 3 * TILE_SIZE
var move_speed = 100
var is_moving = false
var move_direction = Vector2.ZERO

func _ready():
	# Přidejte slima do skupiny "Enemy"
	add_to_group("Enemy")
	# Připojte signál `body_entered` z uzlu `Area2D`
	$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		# Uložte pozici hráče
		Global.player_data["position"] = body.global_position

		# Uložte cestu (pokud ji máte)
		Global.saved_map_state = Global.saved_map_state # Zde nastavte stav mapy

		# Uložte data hráče do Global
		Global.player_data["hp"] = body.hp
		Global.player_data["max_hp"] = body.max_hp
		Global.player_data["attack_speed"] = body.attack_speed
		Global.player_data["attack"] = body.attack

		# Uložte data slima do Global
		Global.enemy_data["hp"] = self.hp
		Global.enemy_data["max_hp"] = self.max_hp
		Global.enemy_data["attack_speed"] = self.attack_speed
		Global.enemy_data["attack"] = self.attack

		# Spusťte bitevní scénu
		get_tree().change_scene_to_file("res://Scenes/battle_scene.tscn")

func _physics_process(delta):
	if is_moving:
		move_along_path(delta)

func start_moving():
	is_moving = true
	start_position = global_position
	move_direction = Vector2.RIGHT.rotated(randf_range(0, PI * 2)).normalized()

func move_along_path(delta):
	# Kontrola vzdálenosti od startovní pozice
	if global_position.distance_to(start_position) >= max_distance:
		# Otočení směru zpět ke startovní pozici
		move_direction = (start_position - global_position).normalized()
	else:
		# Náhodná změna směru pro přirozený pohyb
		if randf() < 0.01:
			move_direction = Vector2.RIGHT.rotated(randf_range(0, PI * 2)).normalized()

	velocity = move_direction * move_speed
	move_and_slide()


func _on_area_2d_body_entered(body):
	pass # Replace with function body.

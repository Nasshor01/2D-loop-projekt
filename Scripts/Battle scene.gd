extends Node2D

var saved_player_position = null
var saved_map_state = null
var player_data = {}
var enemy_data = {}
var player
var enemy
var player_stats
var enemy_stats
@export var PlayerScene: PackedScene
@export var SlimeScene: PackedScene
@onready var player_hp_bar = $PlayerHPBar
@onready var enemy_hp_bar = $EnemyHPBar

func _ready():
	# Initialize the player and enemy from their scenes
	player = PlayerScene.instantiate()
	enemy = SlimeScene.instantiate()
	
	# Add them to the current battle scene
	add_child(player)
	add_child(enemy)
	
	# Load player stats from Global
	player.hp = Global.player_data["hp"]
	player.max_hp = Global.player_data["max_hp"]
	player.attack_speed = Global.player_data["attack_speed"]
	player.attack = Global.player_data["attack"]
	
	# Load enemy stats from Global
	enemy.hp = Global.enemy_data["hp"]
	enemy.max_hp = Global.enemy_data["max_hp"]
	enemy.attack_speed = Global.enemy_data["attack_speed"]
	enemy.attack = Global.enemy_data["attack"]
	
	# Initialize player and enemy stats
	player_stats = {
		"hp": player.hp,
		"max_hp": player.max_hp,
		"attack_speed": player.attack_speed,
		"attack": player.attack
	}

	enemy_stats = {
		"hp": enemy.hp,
		"max_hp": enemy.max_hp,
		"attack_speed": enemy.attack_speed,
		"attack": enemy.attack
	}
	
	print("Player Stats:", player_stats)
	print("Enemy Stats:", enemy_stats)
	
	# Set initial positions for the player and enemy
	player.position = Vector2(100, 200)
	enemy.position = Vector2(300, 200)
	
	# Update health bars
	update_hp_bars()
	
	# Reset Global data
	Global.player_data = null
	Global.enemy_data = null
	
	# Start the battle
	start_combat()

func update_hp_bars():
	player_hp_bar.max_value = player_stats["max_hp"]
	player_hp_bar.value = player_stats["hp"]
	enemy_hp_bar.max_value = enemy_stats["max_hp"]
	enemy_hp_bar.value = enemy_stats["hp"]
	print("Updated HP Bars - Player HP:", player_stats["hp"], "/", player_stats["max_hp"],
		  "Enemy HP:", enemy_stats["hp"], "/", enemy_stats["max_hp"])

func start_combat():
	print("Starting combat...")
	
	# Player attack timer
	var player_timer = Timer.new()
	player_timer.wait_time = player_stats["attack_speed"]
	player_timer.one_shot = false
	player_timer.connect("timeout", Callable(self, "_on_player_attack"))
	add_child(player_timer)
	player_timer.start()
	
	# Enemy attack timer
	var enemy_timer = Timer.new()
	enemy_timer.wait_time = enemy_stats["attack_speed"]
	enemy_timer.one_shot = false
	enemy_timer.connect("timeout", Callable(self, "_on_enemy_attack"))
	add_child(enemy_timer)
	enemy_timer.start()

func _on_player_attack():
	if enemy_stats["hp"] <= 0:
		return
	print("Player attacks!")
	enemy_stats["hp"] -= player_stats["attack"]
	update_hp_bars()
	if enemy_stats["hp"] <= 0:
		await end_battle("player")

func _on_enemy_attack():
	if player_stats["hp"] <= 0:
		return
	print("Enemy attacks!")
	player_stats["hp"] -= enemy_stats["attack"]
	update_hp_bars()
	if player_stats["hp"] <= 0:
		await end_battle("enemy")

func end_battle(winner):
	print("Battle ended. Winner:", winner)
	
	if winner == "player":
		enemy.queue_free()
	else:
		player.queue_free()

	# Uložíme pozici hráče zpět do Global
	if player:
		if Global.player_data == null:
			Global.player_data = {}
		Global.player_data["position"] = player.position

	# Zpoždění před návratem na mapu
	await get_tree().create_timer(2.0).timeout
	print("Returning to the map...")

	# Odstranění battle scény z hlavní scény
	queue_free()

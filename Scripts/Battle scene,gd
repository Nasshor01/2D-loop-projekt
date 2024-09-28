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
	# Vytvořte nové instance hráče a nepřítele
	player = PlayerScene.instantiate()
	enemy = SlimeScene.instantiate()

	# Přidejte je do scény
	add_child(player)
	add_child(enemy)

	# Nastavte jejich statistiky z Global dat
	player.hp = Global.player_data["hp"]
	player.max_hp = Global.player_data["max_hp"]
	player.attack_speed = Global.player_data["attack_speed"]
	player.attack = Global.player_data["attack"]

	enemy.hp = Global.enemy_data["hp"]
	enemy.max_hp = Global.enemy_data["max_hp"]
	enemy.attack_speed = Global.enemy_data["attack_speed"]
	enemy.attack = Global.enemy_data["attack"]

	# Inicializujte player_stats a enemy_stats
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

	# Výpis statistik
	print("Player Stats:", player_stats)
	print("Enemy Stats:", enemy_stats)	

	# Nastavte jejich pozice
	player.position = Vector2(100, 200)
	enemy.position = Vector2(300, 200)

	# Aktualizujte ukazatele zdraví
	update_hp_bars()

	# Resetujte Global data
	Global.player_data = null
	Global.enemy_data = null

	# Zahajte souboj
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
	# Hráčův časovač
	var player_timer = Timer.new()
	player_timer.wait_time = player_stats["attack_speed"]
	player_timer.one_shot = false  # Časovač se bude opakovat
	player_timer.connect("timeout", Callable(self, "_on_player_attack"))
	add_child(player_timer)
	player_timer.start()
	player_timer.name = "PlayerTimer"
	print("Player timer started with wait time:", player_stats["attack_speed"])

	# Nepřítelův časovač
	var enemy_timer = Timer.new()
	enemy_timer.wait_time = enemy_stats["attack_speed"]
	enemy_timer.one_shot = false
	enemy_timer.connect("timeout", Callable(self, "_on_enemy_attack"))
	add_child(enemy_timer)
	enemy_timer.start()
	enemy_timer.name = "EnemyTimer"
	print("Enemy timer started with wait time:", enemy_stats["attack_speed"])

func _on_player_attack():
	print("Entering _on_player_attack()")
	if enemy_stats == null:
		print("Error: enemy_stats is null")
		return
	if not enemy_stats.has("hp"):
		print("Error: enemy_stats does not have 'hp'")
		return
	if enemy_stats["hp"] <= 0:
		print("Enemy is already dead.")
		return  # Nepřítel je již mrtvý
	print("Player attacks!")
	enemy_stats["hp"] -= player_stats["attack"]
	update_hp_bars()
	print("Enemy HP after attack:", enemy_stats["hp"])
	if enemy_stats["hp"] <= 0:
		await end_battle("player")

func _on_enemy_attack():
	print("Entering _on_enemy_attack()")
	if player_stats == null:
		print("Error: player_stats is null")
		return
	if not player_stats.has("hp"):
		print("Error: player_stats does not have 'hp'")
		return
	if player_stats["hp"] <= 0:
		print("Player is already dead.")
		return  # Hráč je již mrtvý
	print("Enemy attacks!")
	player_stats["hp"] -= enemy_stats["attack"]
	update_hp_bars()
	print("Player HP after attack:", player_stats["hp"])
	if player_stats["hp"] <= 0:
		await end_battle("enemy")

func end_battle(winner):
	if winner == "player":
		print("Hráč vyhrál souboj!")
		enemy.queue_free()
	else:
		print("Nepřítel vyhrál souboj!")
		player.queue_free()

	# Zastavte časovače
	if has_node("PlayerTimer"):
		get_node("PlayerTimer").stop()
		get_node("PlayerTimer").queue_free()
	if has_node("EnemyTimer"):
		get_node("EnemyTimer").stop()
		get_node("EnemyTimer").queue_free()

	# Návrat do hlavní scény po krátké prodlevě, ale bez nové generace mapy
	await get_tree().create_timer(2.0).timeout
	print("Returning to main scene without regenerating map...")

	# Pouze změnit zpět na hlavní scénu bez regenerace
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

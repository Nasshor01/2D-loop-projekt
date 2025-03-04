extends Node

signal battle_ended

var player = null
var enemy = null
var player_data = {}
var enemy_data = {}
var saved_map_state = []  # Uložený stav mapy
var saved_player_position = Vector2()  # Uložená pozice hráče

# Uložení stavu mapy
func save_map_state(map_data):
	saved_map_state = map_data.duplicate()

# Načtení stavu mapy
func load_map_state():
	return saved_map_state

# Uložení pozice hráče
func save_player_position(position):
	saved_player_position = position

# Načtení pozice hráče
func load_player_position():
	return saved_player_position

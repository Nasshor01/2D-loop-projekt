extends Control

@onready var player_hp_bar = $PlayerHPBar
@onready var enemy_hp_bar = $EnemyHPBar

func update_hp_bars(player_hp, player_max_hp, enemy_hp, enemy_max_hp):
    player_hp_bar.max_value = player_max_hp
    player_hp_bar.value = player_hp
    enemy_hp_bar.max_value = enemy_max_hp
    enemy_hp_bar.value = enemy_hp
    print("Updated HP Bars - Player HP:", player_hp, "/", player_max_hp, "Enemy HP:", enemy_hp, "/", enemy_max_hp)

extends Node

@export var hp = 50
@export var max_hp = 50
@export var attack_speed = 0.3
@export var attack = 10

func _on_body_entered(body):
    if body.is_in_group("Player"):
        Global.player_data["position"] = body.global_position
        Global.saved_map_state = Global.saved_map_state

        Global.player_data["hp"] = body.hp
        Global.player_data["max_hp"] = body.max_hp
        Global.player_data["attack_speed"] = body.attack_speed
        Global.player_data["attack"] = body.attack

        Global.enemy_data["hp"] = self.hp
        Global.enemy_data["max_hp"] = self.max_hp
        Global.enemy_data["attack_speed"] = self.attack_speed
        Global.enemy_data["attack"] = self.attack

        get_tree().change_scene_to_file("res://Scenes/battle_scene.tscn")

extends Node

@export var PlayerScene: PackedScene
@export var EnemyScene: PackedScene

var player_instance = null
var enemy_instance = null

func _ready():
    print("_ready() called in BattleManager.gd")
    start_battle()

func start_battle():
    print("Starting battle...")

    player_instance = PlayerScene.instantiate()
    enemy_instance = EnemyScene.instantiate()

    add_child(player_instance)
    add_child(enemy_instance)

    player_instance.position = Vector2(100, 200)
    enemy_instance.position = Vector2(300, 200)

    # Initialize combat
    player_instance.connect("attack", self, "_on_player_attack")
    enemy_instance.connect("attack", self, "_on_enemy_attack")

    player_instance.start_attack()
    enemy_instance.start_attack()

func _on_player_attack():
    print("Player attacks enemy")
    enemy_instance.receive_damage(player_instance.attack)

    if enemy_instance.hp <= 0:
        end_battle("player")

func _on_enemy_attack():
    print("Enemy attacks player")
    player_instance.receive_damage(enemy_instance.attack)

    if player_instance.hp <= 0:
        end_battle("enemy")

func end_battle(winner):
    if winner == "player":
        print("Player won the battle!")
        enemy_instance.queue_free()
    else:
        print("Enemy won the battle!")
        player_instance.queue_free()

    # Close battle window without regenerating the map
    await get_tree().create_timer(2.0).timeout
    print("Closing battle popup...")
    get_parent().remove_child(self)

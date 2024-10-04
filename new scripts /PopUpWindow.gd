extends WindowDialog

@export var BattleScene: PackedScene
var battle_instance = null

func _ready():
    print("_ready() called in PopUpWindow.gd")
    start_battle()

func start_battle():
    print("Battle popup window opened")
    battle_instance = BattleScene.instantiate()
    add_child(battle_instance)
    popup_centered()

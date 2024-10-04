extends Node2D

signal attack

@export var hp = 100
@export var max_hp = 100
@export var attack_speed = 1.5
@export var attack = 25

func _ready():
    print("_ready() called in PlayerCombat.gd")

func start_attack():
    print("Player starts attack")
    var attack_timer = Timer.new()
    attack_timer.wait_time = attack_speed
    attack_timer.one_shot = false
    attack_timer.connect("timeout", self, "_on_attack")
    add_child(attack_timer)
    attack_timer.start()

func _on_attack():
    print("Player attacks")
    emit_signal("attack")

func receive_damage(damage):
    hp -= damage
    print("Player receives damage:", damage, "Remaining HP:", hp)

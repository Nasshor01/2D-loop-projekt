extends Node2D

signal attack

@export var hp = 80
@export var max_hp = 80
@export var attack_speed = 2.0
@export var attack = 20

func _ready():
    print("_ready() called in EnemyCombat.gd")

func start_attack():
    print("Enemy starts attack")
    var attack_timer = Timer.new()
    attack_timer.wait_time = attack_speed
    attack_timer.one_shot = false
    attack_timer.connect("timeout", self, "_on_attack")
    add_child(attack_timer)
    attack_timer.start()

func _on_attack():
    print("Enemy attacks")
    emit_signal("attack")

func receive_damage(damage):
    hp -= damage
    print("Enemy receives damage:", damage, "Remaining HP:", hp)

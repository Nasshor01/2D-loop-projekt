extends Control

@onready var tombola = $AnimatedSprite2D
@onready var draw_button = $Button
@onready var result_label = $Label

@export var min_number = 1
@export var max_number = 6

signal number_drawn(number)

func _ready():
	result_label.visible = false
	draw_button.connect("pressed", Callable(self, "_on_draw_button_pressed"))
	tombola.connect("animation_finished", Callable(self, "_on_tombola_animation_finished"))

func _on_draw_button_pressed():
	tombola.play("default")  # Přehrání animace
	result_label.visible = false  # Skryje text během animace

func _on_tombola_animation_finished():
	var drawn_number = randi() % (max_number - min_number + 1) + min_number
	result_label.text = str(drawn_number)
	result_label.visible = true
	emit_signal("number_drawn", drawn_number)

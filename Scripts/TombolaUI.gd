extends Control

@onready var tombola = $AnimatedSprite2D
@onready var draw_button = $Button
@onready var result_label = $Label

@export var min_number = 1
@export var max_number = 24

signal number_drawn(number)

func _ready():
	result_label.visible = false
	draw_button.disabled = true # Disable the button initially
	draw_button.connect("pressed", Callable(self, "_on_draw_button_pressed"))

func enable_button():
	draw_button.disabled = false

func disable_button():
	draw_button.disabled = true

func _on_draw_button_pressed():
	disable_button() # Disable the button immediately after pressing
	tombola.play("default") # Play the animation
	result_label.visible = false # Hide the text during animation

	var frame_count = tombola.sprite_frames.get_frame_count("default")
	var fps = tombola.sprite_frames.get_animation_speed("default")
	var animation_duration = frame_count / fps

	await get_tree().create_timer(animation_duration).timeout
	
	var drawn_number = randi() % (max_number - min_number + 1) + min_number
	result_label.text = str(drawn_number)
	result_label.visible = true
	emit_signal("number_drawn", drawn_number)

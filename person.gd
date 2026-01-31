extends Node2D

var target := Vector2.ZERO
@export_range(0, 10, 0.2, "prefer_slider")
var speed := 3

func walk(position : Vector2) -> void:
	target = position - self.position

func is_walking() -> bool:
	return target != Vector2.ZERO

func _physics_process(delta: float) -> void:
	var diff = target if target.length() < speed else target.normalized() * speed
	position += diff
	target -= diff

	if not $Walk.is_playing() and is_walking():
		$Walk.play("walk")
	elif $Walk.is_playing() and not is_walking():
		$Walk.pause()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Mouse_Left_Click"):
		walk(get_viewport().get_mouse_position())

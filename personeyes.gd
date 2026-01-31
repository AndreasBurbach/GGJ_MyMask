extends Node2D

@export_range(0, 5, 0.1, "prefer_slider")
var eye_move_dist := 2

@onready var eyes_pivot : Node2D = $Pivot
@onready var eyes : Node2D = $Sprite

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dir := get_viewport().get_mouse_position() - eyes_pivot.global_position
	if dir.length() > eye_move_dist:
		dir = dir.normalized() * eye_move_dist
	eyes.position = dir

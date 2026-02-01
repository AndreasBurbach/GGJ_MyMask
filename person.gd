extends CharacterBody2D

@onready var target : Vector2 = position
@export_range(0, 10, 0.2, "prefer_slider")
var speed := 200


func walk(position : Vector2) -> void:
	target = position - $WalkPivot.position
	var dir = target - self.position
	velocity = dir.normalized() * speed


func is_walking() -> bool:
	return target != position

func _physics_process(delta: float) -> void:
	# stop walking when selected
	if not $Container/Person.visible:
		target = position
	var diff = target - position
	if diff != Vector2.ZERO:
		velocity = diff.normalized() * speed 
		if move_and_slide():
			target = position
	if diff.length() < (target - position).length():
		position = target
	#var diff = target if target.length() < speed else target.normalized() * speed * delta
	#position += diff
	#target -= diff

	if not $Walk.is_playing() and is_walking():
		$Walk.play("walk")
	elif $Walk.is_playing() and not is_walking():
		$Walk.pause()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Mouse_Left_Click"):
		walk(position + get_local_mouse_position())

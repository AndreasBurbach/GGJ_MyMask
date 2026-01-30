extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mat = sprite.material as ShaderMaterial
	mat.set_shader_parameter("line_thickness", 2.0)
	pass


@onready var sprite = $Sprite2D
var overlapping_count = 0

func _on_area_entered(_area):
	overlapping_count += 1
	_update_shader()

func _on_area_exited(_area):
	overlapping_count -= 1
	_update_shader()

func _update_shader():
	# Wir greifen auf das Material des Sprites zu
	var mat = sprite.material as ShaderMaterial
	
	if overlapping_count > 0:
		# Setzt den Parameter "line_thickness" im Shader auf 2.0
		mat.set_shader_parameter("line_thickness", 2.0)
	else:
		# Schaltet die Outline wieder aus
		mat.set_shader_parameter("line_thickness", 0.0)

extends Area2D

@onready var sprite = $Sprite2D
@onready var collisionShape = $CollisionShape2D

signal selected(name: String,texture:Texture)
var hovered = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Mouse_Left_Click") and hovered:
		emit_signal("selected", name,sprite.texture)
	pass



func _on_mouse_entered() -> void:
	var mat = sprite.material as ShaderMaterial
	hovered = true
	mat.set_shader_parameter("line_thickness", 1.0)
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	var mat = sprite.material as ShaderMaterial
	hovered = false
	mat.set_shader_parameter("line_thickness", 0.0)
	pass # Replace with function body.
	
	
func update_collision_shape():
	# Sicherstellen, dass beide Nodes existieren und das Sprite ein Bild hat
	if sprite and collisionShape and sprite.texture:
		var size = sprite.texture.get_size() * sprite.scale
		
		# Falls noch kein Shape vorhanden ist, erstelle ein neues Rechteck
		if not collisionShape.shape is RectangleShape2D:
			collisionShape.shape = RectangleShape2D.new()
		
		# Setze die extents (Halbe Breite/Höhe)
		collisionShape.shape.size = size

extends Node

@onready var placeholder = $Placeholder
@onready var coursorObj = $CourserObj

var selectedObj: String
var cursorOffset: Vector2 = Vector2(0,10)

enum Test {
	Mouse
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	coursorObj.hide()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		selectedObj = ""
	var x = Vector2(coursorObj.texture.get_width()/2, coursorObj.texture.get_height() / 2)
	coursorObj.position = get_viewport().get_mouse_position() + x
	pass


func _on_placeholder_selected(name: String) -> void:
	print(name )
	selectedObj = name
	coursorObj.show()
	pass # Replace with function body.

extends Node

@onready var coursorObj = $CourserObj

var selectedObj: Area2D
var cursorOffset: Vector2 = Vector2(0,10)
var name2item: Dictionary[String,Area2D]

enum Test {
	Mouse
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var children = $ItemContainer.get_children()
	for child in children: 
		name2item[child.name] = child 
	coursorObj.hide()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		selectedObj.show() 
		coursorObj.hide()
		#selectedObj = null
	var x = Vector2(coursorObj.texture.get_width()/2, coursorObj.texture.get_height() / 2)
	coursorObj.position = get_viewport().get_mouse_position() + x
	pass


func _on_placeholder_selected(name: String,texture:Texture) -> void:
	print(name )
	selectedObj = name2item[name]
	selectedObj.hide() 
	coursorObj.texture = texture
	coursorObj.show()
	pass # Replace with function body.

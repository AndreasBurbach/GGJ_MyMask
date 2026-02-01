extends Node2D

@export var default:String="Speech bubble"

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	hide()
	$Label.text= default
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_text_for(text:String,seconds:int=1):
	$Label.text = text 
	$ShowTimer.start(seconds)
	show()


func _on_show_timer_timeout() -> void:
	hide()

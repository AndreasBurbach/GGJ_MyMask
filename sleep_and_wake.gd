extends Control

@onready var color_rect = $ColorRect
@export var color:Color
var timer:Timer
var out = true
@export var out_time  = 1.0
@export var hold_time = 1.0 
@export var in_time = 1.0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_rect.color = Color(color,0)
	hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer == null: 
		return
	var progress =  1 - timer.time_left / timer.wait_time
	if !out: 
		progress = 1 - progress
	color_rect.color = Color(color,progress)
	
func start():
	show()
	print("fadout start")
	if out_time == 0:
		_on_out_time_timeout()
		return
	$FadeOut.wait_time = out_time
	$FadeOut.start() 
	timer = $FadeOut
	out = true
	

func _on_fade_out_timeout() -> void:
	if hold_time == 0:
		_on_out_time_timeout()
	$OutTime.wait_time = hold_time
	print("fadeout hold")
	$OutTime.start()
	timer = null

func _on_out_time_timeout() -> void:
	if in_time == 0:
		_on_fade_in_timeout()
		return
	print("fadeint start")
	$FadeIn.wait_time = in_time
	$FadeIn.start()
	timer = $FadeIn 
	out = false


func _on_fade_in_timeout() -> void:
	print("fadein done")
	hide()

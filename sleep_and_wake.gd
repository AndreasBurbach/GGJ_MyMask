extends Node

@onready var color_rect = $ColorRect
@export var color:Color
var timer:Timer
var out = true
@export var out_time  = 3.0
@export var hold_time = 5.0 
@export var in_time = 1.0

@onready var cr = $ColorRect
@export var bubble : TextBubble

var msgs_falling = []
var msgs_sleeping = []
var msgs_waking = []
var msgs_woken = []

signal fadeout
signal fadein
signal hold

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_rect.color = Color(color,0)
	cr.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var alpha
	
	if $FadeOut.time_left > 0:
		alpha = 1- $FadeOut.time_left / $FadeOut.wait_time
	elif $Hold.time_left > 0:
		alpha = 1
	elif $FadeIn.time_left > 0:
		alpha = $FadeIn.time_left / $FadeOut.wait_time
	else:
		return

	color_rect.color = Color(color, alpha)

func start(msgs_falling = [], msgs_sleeping = [], msgs_waking = [], msgs_woken = []):
	self.msgs_falling = msgs_falling if msgs_falling is Array else [msgs_falling]
	self.msgs_sleeping = msgs_sleeping if msgs_sleeping is Array else [msgs_sleeping]
	self.msgs_waking = msgs_waking if msgs_waking is Array else [msgs_waking]
	self.msgs_woken = msgs_woken if msgs_woken is Array else [msgs_woken]

	cr.show()
	print("fadout start")
	$FadeOut.start(out_time)
	
	bubble.show_text_for(msgs_falling)

func _on_fade_out_timeout() -> void:
	await bubble.wait()
	bubble.show_text_for(msgs_sleeping)
	print("fadeout hold")
	$Hold.start(hold_time)
	fadeout.emit()

func _on_hold_timeout() -> void:
	await bubble.wait()
	bubble.show_text_for(msgs_waking)
	print("fadeint start")
	$FadeIn.start(in_time)
	hold.emit()

func _on_fade_in_timeout() -> void:
	await bubble.wait()
	bubble.show_text_for(msgs_woken)
	print("fadein done")
	cr.hide()
	fadein.emit()

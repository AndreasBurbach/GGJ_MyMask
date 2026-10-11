extends Node

@onready var color_rect = $ColorRect
@export var color:Color
var timer:Timer
var out = true
@export var out_time  = 3.0
@export var hold_time = 5.0 
@export var in_time = 1.0

@onready var cr = $ColorRect

func fadeout(seconds : float = 1) -> void:
	cr.show()
	$AnimationPlayer.play(&"fade", -1, 1/seconds)
	await $AnimationPlayer.animation_finished

func fadein(seconds : float = 1) -> void:
	$AnimationPlayer.play(&"fade", -1, -1/seconds, true)
	await $AnimationPlayer.animation_finished
	cr.hide()

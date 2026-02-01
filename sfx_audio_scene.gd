extends Node2D
const extensions = preload("res://scene_extensions.gd")

@onready var sfx_player = $SfxPlayer

@export var PersonFork : AudioStream
@export var StoneLamp : AudioStream
@export var CrashWindow : AudioStream


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_sfx(sound: AudioStream):
	if sound != null:
		sfx_player.stream = sound
		sfx_player.play()

func playSoundByItems(items:Array[extensions.Item]):
	if extensions.Item.Person in items:
		if extensions.Item.Fork in items:
			play_sfx(PersonFork)
			
	if extensions.Item.Lamp in items:
		if extensions.Item.Stone in items:			
			play_sfx(StoneLamp)
		if extensions.Item.Axe in items:			
			play_sfx(StoneLamp)
		if extensions.Item.Hammer in items:
			play_sfx(StoneLamp)
		if extensions.Item.Knive in items:
			play_sfx(StoneLamp)
		if extensions.Item.Fork in items:
			play_sfx(StoneLamp)
		if extensions.Item.Pillow in items:
				play_sfx(StoneLamp)
		if extensions.Item.Blanket in items:
				play_sfx(StoneLamp)
		if extensions.Item.Apple in items:
				play_sfx(StoneLamp)
	
	if extensions.Item.WindowGlas in items:
		if extensions.Item.Stone in items:
			play_sfx(StoneLamp)
		if extensions.Item.Axe in items:
			play_sfx(StoneLamp)
		if extensions.Item.Hammer in items:
			play_sfx(StoneLamp)
				

extends Node2D
@onready var musicPlayer = $MusicPlayer

@export var Awakening: AudioStream
@export var Dream1: AudioStream
@export var Dream2: AudioStream
@export var Dream3: AudioStream
@export var Dream4: AudioStream
@export var Opera: AudioStream
@export var SleepMask: AudioStream
@export var StartMusic: AudioStream
@export var GameOver: AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func play_sfx(sound: AudioStream):
	if sound != null:
		musicPlayer.stream = sound
		musicPlayer.play()

func playStartMusic():
	play_sfx(StartMusic)

func playSleepMask():
	play_sfx(SleepMask)
	
func playOpera():
	play_sfx(Opera)
	
func playAwakening():
	play_sfx(Awakening)
	
func playDream():
	play_sfx([Dream1,Dream2,Dream3,Dream4].pick_random())

func playGameOver():
	play_sfx(GameOver)

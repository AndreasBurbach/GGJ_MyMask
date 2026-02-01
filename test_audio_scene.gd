extends Area2D


# 1. Referenz auf den Player-Node holen
@onready var sfx_player = $SfxPlayer

# 2. Export-Variablen für deine Sound-Dateien erstellen
# Dadurch erscheinen sie im Inspektor rechts als Felder
@export var sound_1 : AudioStream
@export var sound_2 : AudioStream
@export var sound_3 : AudioStream

# 3. Die Funktion zum Wechseln und Abspielen
func play_sfx(welcher_sound: AudioStream):
	if welcher_sound != null:
		sfx_player.stream = welcher_sound # Hier findet der Wechsel statt
		sfx_player.play()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var sound = [sound_1,sound_2,sound_3].pick_random()
	play_sfx(sound)
	
	pass # Replace with function body.

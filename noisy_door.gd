extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var p : float = $Operngesang.get_playback_position()
	$NoteParticles.emitting = (
			p > 0 and p < 6.6 or
			p > 7.7 and p < 14 or
			p > 15.6 and p < 21.6
	)


func _on_button_button_down() -> void:
	print($Operngesang.get_playback_position())

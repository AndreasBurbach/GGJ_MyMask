class_name TextBubble
extends Node2D

@export var default:String="Speech bubble"

var msg_queue = []

signal done

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	hide()
	$Label.text= default

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_text_for(text, seconds : int = 7):
	if text is not Array: text = [text]
	for t in text:
		msg_queue.append([t, seconds])
	if $ShowTimer.is_stopped():
		_on_show_timer_timeout()

func _on_show_timer_timeout() -> void:
	if msg_queue.is_empty():
		done.emit()
		hide()
	else:
		var next = msg_queue.pop_front()
		var text = next[0] as String
		var seconds = next[1] as int
		$Label.text = text
		show()
		if !msg_queue.is_empty() and seconds <= 0:
			seconds = 5
		if seconds > 0:
			$ShowTimer.start(seconds)

func is_done():
	return msg_queue.is_empty()

func wait():
	if is_done(): return
	else: await done

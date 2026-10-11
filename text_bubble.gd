class_name TextBubble
extends Node2D

@export var default:String="Speech bubble"
@export var attach:Node2D
@export var margin:int = 20
const spikeheight = 80

var msg_queue = []

signal done

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	hide()
	$Label.text= default

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !attach: return
	
	global_position = attach.global_position
	
	var rect : Rect2 = $ColorRect.get_global_rect()
	var pivot : Vector2 = rect.get_support(Vector2(1,-1))
	var viewport : Vector2 = get_viewport_rect().size
	
	global_position += Vector2(min(0, viewport.x - pivot.x), max(0,- pivot.y))


func show_text_for(text, seconds : int = 0):
	if text is not Array: text = [text]		
	for t:String in text:
		var s : int = max(2, len(t) * 0.05) if seconds == 0 else seconds
		print(s)

		msg_queue.append([t, s])
	if $ShowTimer.is_stopped():
		_on_show_timer_timeout()
	wait()

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
	return msg_queue.is_empty() && $ShowTimer.is_stopped()

func wait():
	if is_done(): return
	else: await done


func _on_label_resized() -> void:
	$ColorRect.size = $Label.get_rect().size + margin*Vector2(2,2)
	$ColorRect.position = Vector2(-50,-spikeheight-$ColorRect.size.y)
	$Label.position = $ColorRect.position + margin*Vector2(1,1)

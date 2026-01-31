@tool

extends Node2D

@export_range(0, 45, 1, "radians_as_degrees")
var angle := 0.1 * TAU:
	get:
		return angle
	set(val):
		angle = val
		rebuild_lines()
@export_range(0, 500, 1, "or_greater", "prefer_slider")
var width := 200:
	get:
		return width
	set(val):
		width = val
		rebuild_lines()
@export_range(0, 500, 1, "or_greater", "prefer_slider")
var depth := 200:
	get:
		return depth
	set(val):
		depth = val
		rebuild_lines()
@export_range(0, 500, 1, "or_greater", "prefer_slider")
var height := 200:
	get:
		return height
	set(val):
		height = val
		rebuild_lines()

@onready var floor := $Floor
@onready var lwall := $LWall
@onready var rwall := $RWall

func _ready() -> void:
	rebuild_lines()

# Called when the node enters the scene tree for the first time.
func rebuild_lines() -> void:
	var depth := Vector2(depth, 0)
	var width := Vector2(width, 0)
	var height := Vector2(0, -height)

	if not floor or not lwall or not rwall:
		return

	var p := Vector2.ZERO
	floor.clear_points()
	floor.add_point(Vector2.ZERO)
	p += depth.rotated(angle)
	floor.add_point(p)
	p += width.rotated(PI - angle)
	floor.add_point(p)
	p += depth.rotated(PI + angle)
	floor.add_point(p)
	floor.closed = true

	p = Vector2.ZERO
	lwall.clear_points()
	lwall.add_point(p)
	p += height
	lwall.add_point(p)
	p += width.rotated(PI - angle)
	lwall.add_point(p)
	p -= height
	lwall.add_point(p)
	lwall.closed = true

	p = Vector2.ZERO
	rwall.clear_points()
	rwall.add_point(p)
	p += height
	rwall.add_point(p)
	p += depth.rotated(angle)
	rwall.add_point(p)
	p -= height
	rwall.add_point(p)
	rwall.closed = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

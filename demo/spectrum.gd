extends Control
class_name Spectrum

@onready var BAR_COUNT: int = find_parent("Demo").BAR_COUNT

var _smoothed: PackedFloat32Array


func _ready() -> void:
	_smoothed.resize(BAR_COUNT)


func update(smoothed: PackedFloat32Array) -> void:
	if Engine.get_frames_drawn() & 1:
		return
	_smoothed = smoothed
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var bar_w := (w / BAR_COUNT) * 0.8
	var gap := (w / BAR_COUNT) * 0.2

	for i in range(BAR_COUNT):
		var bar_h := _smoothed[i] * h
		var x := i * (bar_w + gap)
		draw_rect(
			Rect2(x, h - bar_h, bar_w, bar_h), Color.from_hsv(i / float(BAR_COUNT) * 0.75, 0.8, 0.9)
		)

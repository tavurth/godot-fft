extends Control
class_name Spectrum

const BAR_WIDTH := 16.0
const BAR_SPACING := 2.0

var _bars: Array[ColorRect] = []
@onready var BAR_COUNT: int = find_parent("Demo").BAR_COUNT


func _ready() -> void:
	for i in range(BAR_COUNT):
		var bar := ColorRect.new()
		bar.color = Color.from_hsv(i / float(BAR_COUNT) * 0.75, 0.8, 0.9)
		bar.size.x = BAR_WIDTH
		add_child(bar)
		_bars.append(bar)


func update(smoothed: PackedFloat32Array) -> void:
	var bar_width := (size.x / BAR_COUNT) * 0.8
	var spacing := (size.x / BAR_COUNT) * 0.2
	var h := size.y

	for i in range(BAR_COUNT):
		var bar_h := smoothed[i] * h
		_bars[i].size = Vector2(bar_width, bar_h)
		_bars[i].position.x = i * (bar_width + spacing)
		_bars[i].position.y = h - bar_h

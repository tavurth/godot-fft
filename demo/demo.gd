extends Control

const FFT_SIZE := 4096
const BAR_COUNT := 256
const SMOOTHING := 0.10
const DB_FLOOR := -90.0

@onready var _player: AudioPlayer = %AudioStreamPlayer
@onready var _spectrum: Spectrum = %Spectrum

var _smoothed: PackedFloat32Array


func _ready() -> void:
	_smoothed.resize(BAR_COUNT)
	_player.play()


func _process(_delta: float) -> void:
	var samples := _player.get_samples(FFT_SIZE)
	if samples.is_empty():
		return

	var spectrum: PackedFloat64Array = FFT.fft(samples)
	var nyquist := FFT_SIZE / 2

	for i in range(BAR_COUNT):
		var lo := int(lerpf(1.0, nyquist, pow(float(i) / BAR_COUNT, 2.0)))
		var hi := maxi(int(lerpf(1.0, nyquist, pow(float(i + 1) / BAR_COUNT, 2.0))), lo + 1)

		var peak := 0.0
		for b in range(lo, mini(hi, nyquist)):
			var re: float = spectrum[b * 2]
			var im: float = spectrum[b * 2 + 1]
			peak = maxf(peak, sqrt(re * re + im * im))

		var db := 20.0 * log(maxf(peak / FFT_SIZE, 1e-6)) / log(10.0)
		var normalized := clampf((db - DB_FLOOR) / -DB_FLOOR, 0.0, 1.0)
		_smoothed[i] = lerpf(_smoothed[i], pow(normalized, 0.5), SMOOTHING)

	_spectrum.update(_smoothed)

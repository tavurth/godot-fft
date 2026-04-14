extends Control

const FFT_SIZE := 2048
const BAR_COUNT := 128
const SMOOTHING := 0.5
const DB_FLOOR := -90.0
const LOG10 := 2.302585092994046
const INV_DB_FLOOR := 1.0 / -DB_FLOOR
const INV_FFT_SIZE := 1.0 / FFT_SIZE

@onready var _player: AudioPlayer = %AudioStreamPlayer
@onready var _spectrum: Spectrum = %Spectrum

var _smoothed: PackedFloat32Array
var _bar_lo: PackedInt32Array  # precomputed bin ranges per bar
var _bar_hi: PackedInt32Array


func _ready() -> void:
	_smoothed.resize(BAR_COUNT)
	_precompute_bin_ranges()
	_player.play()


func _precompute_bin_ranges() -> void:
	var nyquist := FFT_SIZE >> 1
	_bar_lo.resize(BAR_COUNT)
	_bar_hi.resize(BAR_COUNT)
	for i in range(BAR_COUNT):
		var lo := int(lerpf(1.0, nyquist, pow(float(i) / BAR_COUNT, 2.0)))
		var hi := maxi(int(lerpf(1.0, nyquist, pow(float(i + 1) / BAR_COUNT, 2.0))), lo + 1)
		_bar_lo[i] = lo
		_bar_hi[i] = mini(hi, nyquist)


func _process(_delta: float) -> void:
	var samples := _player.get_samples(FFT_SIZE)
	if samples.is_empty():
		return

	var spectrum: PackedFloat64Array = FFT.fft(samples)

	for i in range(BAR_COUNT):
		var peak_sq := 0.0
		for b in range(_bar_lo[i], _bar_hi[i]):
			var re: float = spectrum[b * 2]
			var im: float = spectrum[b * 2 + 1]
			peak_sq = maxf(peak_sq, re * re + im * im)

		var db := 20.0 * log(maxf(sqrt(peak_sq) * INV_FFT_SIZE, 1e-6)) / LOG10
		var normalized := clampf((db - DB_FLOOR) * INV_DB_FLOOR, 0.0, 1.0)
		_smoothed[i] = lerpf(_smoothed[i], pow(normalized, 0.5), SMOOTHING)

	_spectrum.update(_smoothed)

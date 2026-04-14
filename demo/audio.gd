extends AudioStreamPlayer
class_name AudioPlayer

var _samples: PackedFloat32Array
var _sample_rate: float
var _channels: int


func _ready() -> void:
	_sample_rate = AudioServer.get_mix_rate()
	_decode_stream()


func _decode_stream() -> void:
	var bytes: PackedByteArray = stream.data
	_channels = 2 if stream.stereo else 1
	# bytes / 2 bytes-per-sample / channels = mono sample count
	_samples.resize(bytes.size() / 2 / _channels)
	for i in range(_samples.size()):
		# step by channels to read only left channel
		_samples[i] = bytes.decode_s16(i * _channels * 2) / 32768.0


func get_samples(count: int) -> Array:
	var latency := AudioServer.get_output_latency() + AudioServer.get_time_since_last_mix()
	var offset := maxi(int((get_playback_position() - latency) * _sample_rate), 0)

	# don't wrap — return empty so spectrum goes dark during silence
	if offset + count * _channels > _samples.size():
		return []

	var out: Array = []
	out.resize(count)
	for i in range(count):
		out[i] = _samples[offset + i]
	return out

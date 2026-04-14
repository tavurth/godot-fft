extends SceneTree

const FFT = preload("Fft.gd")


func _init():
	var result = FFT.fft([1, 1, 1, 1, 0, 0, 0, 0])
	print(FFT.pretty(result))

	result = FFT.ifft(FFT.fft([1, 1, 1, 1, 0, 0, 0, 0]))
	print(FFT.pretty(result))

	_speed_test(1024, 100)
	quit()


func _speed_test(size: int, iterations: int) -> void:
	var input := []
	input.resize(size)
	for i in range(size):
		input[i] = sin(2.0 * PI * i / size)

	var packed := FFT.to_packed(input)
	var start := Time.get_ticks_usec()
	for _i in range(iterations):
		FFT.fft(packed.duplicate())
	var elapsed := Time.get_ticks_usec() - start

	print(
		(
			"fft(%d) x%d: %d us total, %.1f us/call"
			% [size, iterations, elapsed, elapsed / float(iterations)]
		)
	)

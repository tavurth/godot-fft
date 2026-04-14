extends SceneTree

const FFT = preload("Fft.gd")


func _init():
	var result = FFT.fft([1, 1, 1, 1, 0, 0, 0, 0])
	print(result)

	result = FFT.ifft(FFT.fft([1, 1, 1, 1, 0, 0, 0, 0]))
	print(result)

	quit()

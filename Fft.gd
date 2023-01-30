# complex fast fourier transform and inverse from
# http://rosettacode.org/wiki/Fast_Fourier_transform#C.2B.2B

# basic complex number arithmetic from
# http://rosettacode.org/wiki/Fast_Fourier_transform#Scala

extends Node

const Complex = preload("Complex.gd")

static func ensure_complex(maybe_complexes: Array) -> Array:
	var to_return = []

	for item in maybe_complexes:
		if not item is Complex:
			item = Complex.new(item)

		to_return.append(item)

	return to_return


static func conjugate(amplitudes: Array) -> Array:
	# conjugate if imaginary part is not 0
	for i in range(0, len(amplitudes)):
		if amplitudes[i] is Complex:
			amplitudes[i].im = -amplitudes[i].im

	return amplitudes


static func keyed(amplitudes: Array, key: String) -> Array:
	var to_return = []

	for item in amplitudes:
		if not item is Complex:
			item = Complex.new(item)

		to_return.append(item[key])

	return to_return


static func reals(amplitudes: Array) -> Array:
	return keyed(amplitudes, "re")


static func imags(amplitudes: Array) -> Array:
	return keyed(amplitudes, "im")


static func ifft(amplitudes: Array) -> Array:
	var N = len(amplitudes)
	var iN = 1.0 / N

	conjugate(amplitudes)

	# apply fourier transform
	amplitudes = fft(amplitudes)

	conjugate(amplitudes)

	for i in range(0, N):
		if not amplitudes[i] is Complex:
			continue

		# scale
		amplitudes[i].re *= iN
		amplitudes[i].im *= iN

	return amplitudes


static func fft(amplitudes: Array) -> Array:
	var N = len(amplitudes)
	if N <= 1:
		return amplitudes

	var hN = N / 2
	var even = []
	var odd = []

	# Divide
	even.resize(hN)
	odd.resize(hN)

	for i in range(0, hN):
		even[i] = amplitudes[i * 2]
		odd[i] = amplitudes[i * 2 + 1]

	# And conquer
	even = fft(even)
	odd = fft(odd)

	var a := -2.0 * PI

	for k in range(0, hN):
		if not even[k] is Complex:
			even[k] = Complex.new(even[k], 0)

		if not odd[k] is Complex:
			odd[k] = Complex.new(odd[k], 0)

		var p = k / float(N)
		var t = Complex.new(0, a * p)

		t.cexp(t).mul(odd[k], t)

		amplitudes[k] = even[k].add(t, odd[k])
		amplitudes[k + hN] = even[k].sub(t, even[k])

	return amplitudes

# test code
# print( cfft([1,1,1,1,0,0,0,0]) )
# print( icfft(cfft([1,1,1,1,0,0,0,0])) )

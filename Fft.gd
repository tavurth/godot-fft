# Fast Fourier Transform - iterative Cooley-Tukey radix-2 DIT
# Input/output: PackedFloat64Array interleaved [re0, im0, re1, im1, ...]
# http://rosettacode.org/wiki/Fast_Fourier_transform#C.2B.2B

extends Node

static var _twiddles: Dictionary = {}

static var _mutex := Mutex.new()


static func _twiddle_table(n: int) -> PackedFloat64Array:
	if _twiddles.has(n):
		return _twiddles[n]

	_mutex.lock()
	# double-check after acquiring — another thread may have beaten us
	if not _twiddles.has(n):
		var table := PackedFloat64Array()
		table.resize(n)
		var a := -2.0 * PI / n
		for k in range(n / 2):
			table[k * 2] = cos(a * k)
			table[k * 2 + 1] = sin(a * k)
		_twiddles[n] = table
	_mutex.unlock()

	return _twiddles[n]


static func _bit_reverse_permute(data: PackedFloat64Array, n: int) -> void:
	var bits := int(log(n) / log(2))

	for i in range(n):
		var j := 0
		var x := i
		for _b in range(bits):
			j = (j << 1) | (x & 1)
			x >>= 1
		if j > i:
			var re_i := data[i * 2]
			var im_i := data[i * 2 + 1]
			data[i * 2] = data[j * 2]
			data[i * 2 + 1] = data[j * 2 + 1]
			data[j * 2] = re_i
			data[j * 2 + 1] = im_i


static func to_packed(reals: Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(reals.size() * 2)
	for i in range(reals.size()):
		out[i * 2] = float(reals[i])
		out[i * 2 + 1] = 0.0
	return out


static func to_reals(data: PackedFloat64Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(data.size() / 2)
	for i in range(out.size()):
		out[i] = data[i * 2]
	return out


static func pretty(data: PackedFloat64Array) -> String:
	var parts := PackedStringArray()
	for i in range(data.size() / 2):
		var re := data[i * 2]
		var im := data[i * 2 + 1]
		if not re:
			parts.append("%s j" % absf(im))
		elif im < 0:
			parts.append("%s %s j" % [re, im])
		else:
			parts.append("%s + %s j" % [re, im])
	return "[%s]" % ", ".join(parts)


static func fft(data) -> PackedFloat64Array:
	var packed: PackedFloat64Array = data if data is PackedFloat64Array else to_packed(data)
	var n := packed.size() / 2
	assert(n > 0 and (n & (n - 1)) == 0, "FFT size must be power of 2")

	_bit_reverse_permute(packed, n)

	var twiddles := _twiddle_table(n)
	var half_m := 1

	while half_m < n:
		var m := half_m * 2
		var stride := n / m

		for k in range(0, n, m):
			for j in range(half_m):
				var t_idx := j * stride * 2
				var wr := twiddles[t_idx]
				var wi := twiddles[t_idx + 1]

				var u_idx := (k + j) * 2
				var v_idx := (k + j + half_m) * 2

				var ur := packed[u_idx]
				var ui := packed[u_idx + 1]
				var vr := packed[v_idx]
				var vi := packed[v_idx + 1]

				var tr := wr * vr - wi * vi
				var ti := wr * vi + wi * vr

				packed[u_idx] = ur + tr
				packed[u_idx + 1] = ui + ti
				packed[v_idx] = ur - tr
				packed[v_idx + 1] = ui - ti

		half_m = m

	return packed


static func ifft(data) -> PackedFloat64Array:
	var packed: PackedFloat64Array = data if data is PackedFloat64Array else to_packed(data)
	var n := packed.size() / 2

	for i in range(n):
		packed[i * 2 + 1] = -packed[i * 2 + 1]

	fft(packed)

	var inv_n := 1.0 / n
	for i in range(n):
		packed[i * 2] = packed[i * 2] * inv_n
		packed[i * 2 + 1] = -packed[i * 2 + 1] * inv_n

	return packed

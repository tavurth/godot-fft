# Fast Fourier Transform: iterative Cooley-Tukey radix-2 DIT
# Input/output: PackedFloat64Array interleaved [re0, im0, re1, im1, ...]
# http://rosettacode.org/wiki/Fast_Fourier_transform#C.2B.2B

extends Node

var _twiddles: Dictionary = {}
var _rev_tables: Dictionary = {}
var _mutex := Mutex.new()


func _build_tables(n: int) -> void:
	var bits := 0
	var tmp := n
	while tmp > 1:
		bits += 1
		tmp >>= 1

	var rev := PackedInt32Array()
	rev.resize(n)
	for i in range(n):
		var j := 0
		var x := i
		for _b in range(bits):
			j = (j << 1) | (x & 1)
			x >>= 1
		rev[i] = j

	var half := n >> 1
	var twiddle := PackedFloat64Array()
	twiddle.resize(n)
	var a := -2.0 * PI / n
	for k in range(half):
		twiddle[k * 2] = cos(a * k)
		twiddle[k * 2 + 1] = sin(a * k)

	_twiddles[n] = twiddle
	_rev_tables[n] = rev


func _ensure_tables(n: int) -> void:
	if _twiddles.has(n):
		return
	_mutex.lock()
	if not _twiddles.has(n):  # re-check after acquiring, another thread may have built it
		_build_tables(n)
	_mutex.unlock()


func _bit_reverse_permute(data: PackedFloat64Array, n: int, rev: PackedInt32Array) -> void:
	for i in range(n):
		var j := rev[i]
		if j <= i:
			continue
		var ri := i * 2
		var rj := j * 2
		var re := data[ri]
		var im := data[ri + 1]
		data[ri] = data[rj]
		data[ri + 1] = data[rj + 1]
		data[rj] = re
		data[rj + 1] = im


func to_packed(reals: Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(reals.size() * 2)
	for i in range(reals.size()):
		out[i * 2] = float(reals[i])
		out[i * 2 + 1] = 0.0
	return out


func to_reals(data: PackedFloat64Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(data.size() >> 1)
	for i in range(out.size()):
		out[i] = data[i * 2]
	return out


func pretty(data: PackedFloat64Array) -> String:
	var parts := PackedStringArray()
	for i in range(data.size() >> 1):
		var re := data[i * 2]
		var im := data[i * 2 + 1]
		if not re:
			parts.append("%s j" % absf(im))
		elif im < 0:
			parts.append("%s %s j" % [re, im])
		else:
			parts.append("%s + %s j" % [re, im])
	return "[%s]" % ", ".join(parts)


func fft(data) -> PackedFloat64Array:
	var packed: PackedFloat64Array = data if data is PackedFloat64Array else to_packed(data)
	var n := packed.size() >> 1
	assert(n > 0 and (n & (n - 1)) == 0, "FFT size must be power of 2")

	_ensure_tables(n)
	_bit_reverse_permute(packed, n, _rev_tables[n])

	var twiddles: PackedFloat64Array = _twiddles[n]
	var half_m := 1
	var stage := 1  # stride = n >> stage, since m = 2^stage

	while half_m < n:
		var stride := n >> stage

		for k in range(0, n, half_m << 1):
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

				var tw_r := wr * vr - wi * vi
				var tw_i := wr * vi + wi * vr

				packed[u_idx] = ur + tw_r
				packed[u_idx + 1] = ui + tw_i
				packed[v_idx] = ur - tw_r
				packed[v_idx + 1] = ui - tw_i

		half_m <<= 1
		stage += 1

	return packed


func ifft(data) -> PackedFloat64Array:
	var packed: PackedFloat64Array = data if data is PackedFloat64Array else to_packed(data)
	var n := packed.size() >> 1

	for i in range(n):
		packed[i * 2 + 1] = -packed[i * 2 + 1]

	packed = fft(packed)

	var inv_n := 1.0 / n
	for i in range(n):
		packed[i * 2] *= inv_n
		packed[i * 2 + 1] = -packed[i * 2 + 1] * inv_n

	return packed

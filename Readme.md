![img](https://github.com/user-attachments/assets/50138c52-8833-4807-abe6-79773c4d1f1f)

[![img](https://awesome.re/mentioned-badge.svg)](https://github.com/godotengine/awesome-godot)
![img](https://img.shields.io/github/license/tavurth/godot-simple-fps-camera.svg)
![img](https://img.shields.io/github/repo-size/tavurth/godot-simple-fps-camera.svg)
![img](https://img.shields.io/github/languages/code-size/tavurth/godot-simple-fps-camera.svg)

# Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
3. [Notes](#notes)
4. [Performance](#performance)
5. [Reference](#reference)

# Installation

1. Install addon
2. Enable plugin from project settings

The singleton `FFT` is autoloaded at project start.

# Usage

Input can be a plain `Array` of floats or a `PackedFloat64Array` (interleaved `[re0, im0, re1, im1, ...]`).
Output is always `PackedFloat64Array`.

```gdscript
var result = FFT.fft([1, 1, 1, 1, 0, 0, 0, 0])
print(FFT.pretty(result))

var recovered = FFT.ifft(FFT.fft([1, 1, 1, 1, 0, 0, 0, 0]))
print(FFT.to_reals(recovered))
```

# Notes

`fft` and `ifft` modify the input `PackedFloat64Array` in-place for speed.
Pass a duplicate if you need the original preserved:

```gdscript
var result = FFT.fft(my_packed.duplicate())
```

Thread safe. Twiddle factor cache uses a mutex on first population per size, after which reads are lock-free. Callers must ensure input arrays are not shared across threads.

```gdscript
var _thread := Thread.new()
var _terminated := false
var _mutex := Mutex.new()
var _data: PackedFloat64Array

func _ready() -> void:
    _thread.start(_thread_runner)

func _exit_tree() -> void:
    _terminated = true
    _thread.wait_to_finish()

func _thread_runner() -> void:
    while not _terminated:
        OS.delay_msec(100)
        _mutex.lock()
        FFT.fft(_data)
        _mutex.unlock()

func _process(_delta: float) -> void:
    if not _mutex.try_lock():
        return
    print(FFT.pretty(_data))
    _mutex.unlock()
```

# Performance

```shell
fft(1024) x100: 127399 us total, 1274.0 us/call
```

12x faster than the original recursive implementation, using iterative Cooley-Tukey
with precomputed twiddle factors and `PackedFloat64Array` for zero-allocation butterflies.

For per-frame use at 60fps, N<=256 is recommended.

# Demo

A real-time audio spectrum visualizer is included in `/demo`.

<img width="688" height="464" alt="Screenshot 2026-04-14 at 16 47 59" src="https://github.com/user-attachments/assets/87ecbcb0-f5dc-48f0-8db9-5d8e24f2fe08" />

It demonstrates FFT-based frequency analysis of a playing audio stream, rendered as a bar spectrum with log-spaced frequency bins and dB scaling.

## How it works

- `AudioPlayer` decodes the WAV stream to a mono PCM buffer and slices a sample window aligned to the current playback position, compensating for hardware output latency
- `demo.gd` runs the FFT each frame, maps bins to log-spaced frequency bands, converts magnitude to dB, and smooths the result over time
- `Spectrum` renders the smoothed values as colored bars scaled to the control's size

## Running the demo

1. Open `/demo/demo.tscn`
2. Assign a WAV file (PCM, any sample rate) to the `AudioStreamPlayer` node
3. Run the scene

## Tuning

| Constant    | Location  | Effect                                                                           |
|-------------|-----------|----------------------------------------------------------------------------------|
| `DB_FLOOR`  | `demo.gd` | Sensitivity: lower values (-60) show more, higher (-20) gate quiet signals       |
| `SMOOTHING` | `demo.gd` | Temporal smoothing: lower is snappier, higher is silkier                         |
| `FFT_SIZE`  | `demo.gd` | Frequency resolution vs. CPU cost: must be power of 2, ≤256 recommended at 60fps |
| `BAR_COUNT` | `demo.gd` | Number of frequency bands displayed                                              |

# Reference

## Public methods

### `FFT.fft(data: Array | PackedFloat64Array) -> PackedFloat64Array`

Forward transformation from data-space into frequency-space.

### `FFT.ifft(data: Array | PackedFloat64Array) -> PackedFloat64Array`

Reverse transformation from frequency-space into data-space.

### `FFT.to_packed(reals: Array) -> PackedFloat64Array`

Converts a real-valued `Array` to interleaved complex `PackedFloat64Array`.

### `FFT.to_reals(data: PackedFloat64Array) -> PackedFloat64Array`

Extracts the real components from an interleaved complex array.

### `FFT.pretty(data: PackedFloat64Array) -> String`

Returns a human-readable string of complex values for debugging.

<a href="https://www.buymeacoffee.com/tavurth" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

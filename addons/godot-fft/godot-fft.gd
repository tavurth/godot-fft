@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("FFT", "res://addons/godot-fft/Fft.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("FFT")

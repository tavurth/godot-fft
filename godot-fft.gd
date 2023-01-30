@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("FFT", "res://addons/godot-fft/Fft.gd")


func _exit_tree():
	remove_autoload_singleton("FFT")

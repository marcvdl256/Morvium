extends Node

signal build_mode_changed(enabled: bool)
signal debug_mode_changed(enabled: bool)

var build_mode: bool = false:
	set(value):
		if build_mode == value:
			return
		build_mode = value
		build_mode_changed.emit(build_mode)

var debug_mode: bool = true:
	set(value):
		if debug_mode == value:
			return
		debug_mode = value
		debug_mode_changed.emit(debug_mode)

func toggle_build_mode() -> void:
	build_mode = not build_mode

func cancel_build_mode() -> void:
	build_mode = false

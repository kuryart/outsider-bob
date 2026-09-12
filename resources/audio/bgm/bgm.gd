class_name BGM extends Resource

## The main stream — plays on loop.
@export var stream: AudioStream
## Optional one-shot intro played before the main loop begins.
@export var intro_stream: AudioStream
@export_range(-80.0, 6.0) var volume_db = 0.0
@export_range(-0.01, 4.0) var pitch_scale = 1.0

var bus = "BGM"

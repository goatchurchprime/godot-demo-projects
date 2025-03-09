extends Node3D

@onready var capture : AudioEffectCapture = AudioServer.get_bus_effect(1, 0)
@onready var generatorplayback : AudioStreamGeneratorPlayback
@onready var sample_hz = $SoundSource/AudioStreamPlayer3D.stream.mix_rate
var pulse_hz = 440.0 # The frequency of the sound wave.
var phase = 0.0

func _ready():
	sample_hz = 22050
	$SoundSource/AudioStreamPlayer3D.stream.mix_rate = sample_hz
	$SoundSource/AudioStreamPlayer3D.play()
	generatorplayback = $SoundSource/AudioStreamPlayer3D.get_stream_playback()
	$Display2D.position = DisplayServer.window_get_size()/2
	print($Display2D/PolygonLeft.polygon)

func fill_buffer():
	var increment = pulse_hz / sample_hz
	var to_fill = generatorplayback.get_frames_available()
	while to_fill > 0:
		var s = sin(phase * TAU)
		#s = (1 if s > 0 else -1)
		generatorplayback.push_frame(Vector2.ONE*s) # Audio frames are stereo.
		phase = fmod(phase + increment, 1.0)
		to_fill -= 1

var capturedbuffer = PackedVector2Array()
func _process(delta):
	fill_buffer()
	while true:
		var lcapturedbuffer = capture.get_buffer(44100/pulse_hz)
		if lcapturedbuffer:
			capturedbuffer = lcapturedbuffer
		else:
			break
	
func getrms():
	var ssum = Vector2()
	for a in capturedbuffer:
		ssum += a*a
	return ssum/len(capturedbuffer)

func measureincoming(r, nsamples, simulated):
	var polygonleft = PackedVector2Array()
	var polygonright = PackedVector2Array()

	var spcap = Spcap.new()
	var panning_strength = 1.0
	var cached_global_panning_strength = 0.5
	var tightness = cached_global_panning_strength * 2.0 * panning_strength;

	for i in range(nsamples):
		var vec = Vector3(cos(i*TAU/nsamples), 0.5, sin(i*TAU/nsamples))
		$SoundSource.position = vec*r
		await get_tree().create_timer(0.06).timeout
		var rms = spcap.calculate(r, vec, tightness) if simulated else getrms()
		var vec2 = Vector2(vec.x, vec.z)
		polygonleft.append(vec2*sqrt(rms.x))
		polygonright.append(vec2*sqrt(rms.y))

	$Display2D/PolygonLeft.polygon = polygonleft
	$Display2D/PolygonRight.polygon = polygonright
	

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		measureincoming(3, 100, false)
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		for i in range(21):
			$SoundSource.position.z = 4*(i/10.0 - 1)
			await get_tree().create_timer(0.06).timeout
			var rms = getrms()
			print($SoundSource.position, rms, rms.length())
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		measureincoming(3, 100, true)


##########
class Spcap:
	var speaker_directions = [ ]
	var speaker_count = 2
	var directions = [ ]
	var effective_number_of_speakers = [ ]
	var squared_gains = [ ]
	func _init():
		speaker_directions.append(Vector3(-1.0, 0.0, -1.0).normalized())
		speaker_directions.append(Vector3(1.0, 0.0, -1.0).normalized())
		for speaker_num in range(speaker_count):
			directions.append(Vector3())
			effective_number_of_speakers.append(0)
			squared_gains.append(0)
			
		for speaker_num in range(speaker_count):
			directions[speaker_num] = speaker_directions[speaker_num];
			for other_speaker_num in range(speaker_count):
				#prints(speaker_num, other_speaker_num, directions[speaker_num], directions[other_speaker_num])
				effective_number_of_speakers[speaker_num] += 0.5 * (1.0 + directions[speaker_num].dot(directions[other_speaker_num]))
		print(effective_number_of_speakers)
	
	func calculate(r, source_direction, tightness):
		var volumes = [ 0, 0 ]
		var sum_squared_gains = 0.0;
		var unit_size = 10.0
		var CMP_EPSILON = 0.00001
		var multiplier = linear_to_db(1.0 / ((r / unit_size) + CMP_EPSILON));
		for speaker_num in range(speaker_count):
			var initial_gain = 0.5 * pow(1.0 + directions[speaker_num].dot(source_direction), tightness) / effective_number_of_speakers[speaker_num]
			squared_gains[speaker_num] = initial_gain * initial_gain
			sum_squared_gains += squared_gains[speaker_num]
		for speaker_num in range(speaker_count):
			volumes[speaker_num] = sqrt(squared_gains[speaker_num] / sum_squared_gains)
		return Vector2(volumes[0], volumes[1])*multiplier

extends VBoxContainer

@export var analyzername = "spectrum1"
@export var bus_name = "Master"

var spectrumanalyzer : AudioEffectSpectrumAnalyzer
var spectrumanalyzerinstance : AudioEffectSpectrumAnalyzerInstance
var bus_idx = -1
var effect_idx = -1

var fft_size = 256
var mix_rate = 44100
var fft_count = 1
var fft_freqstep = 1
var pts : PackedVector2Array = PackedVector2Array()

var audio_data : PackedVector2Array = PackedVector2Array()
var audio_sample_size = 100
var audio_sample_image: Image
var audio_sample_texture: ImageTexture

func refresh_analyzer_instance():
	bus_idx = AudioServer.bus_count - 1
	while bus_idx >= 0 and bus_name != AudioServer.get_bus_name(bus_idx):
		bus_idx -= 1
	
	effect_idx = AudioServer.get_bus_effect_count(bus_idx) - 1
	if effect_idx >= 0 and is_instance_of(AudioServer.get_bus_effect(bus_idx, effect_idx), AudioEffectSpectrumAnalyzer):
		AudioServer.remove_bus_effect(bus_idx, effect_idx)
	
	effect_idx = AudioServer.get_bus_effect_count(bus_idx)
	spectrumanalyzer = AudioEffectSpectrumAnalyzer.new()
	spectrumanalyzer.fft_size = $HBoxFFT/FFTSize.selected
	spectrumanalyzer.buffer_length = int($HBoxFFT/BufferLength.get_item_text($HBoxFFT/BufferLength.selected))
	AudioServer.add_bus_effect(bus_idx, spectrumanalyzer)
	effect_idx = AudioServer.get_bus_effect_count(bus_idx) - 1
	print(AudioServer.get_bus_effect(bus_idx, effect_idx))

	spectrumanalyzer = AudioServer.get_bus_effect(bus_idx, effect_idx)
	spectrumanalyzerinstance = AudioServer.get_bus_effect_instance(bus_idx, effect_idx, 0)

	fft_size = [256, 512, 1024, 2048, 4096][spectrumanalyzer.fft_size];
	mix_rate = AudioServer.get_mix_rate();
	fft_count = (spectrumanalyzer.buffer_length / (float(fft_size) / mix_rate)) + 1;
	fft_freqstep = (mix_rate * 0.5) / fft_size
	prints(spectrumanalyzerinstance, "fft_size", fft_size, "fft history size", fft_count, " fft_freqstep ", fft_freqstep)

	pts.resize(100)
	for i in range(len(pts)):
		pts[i] = Vector2((i+1.5)*fft_freqstep, 0.0)
	$ColorRect/Scaler.scale.x = $ColorRect.size.x / pts[-1].x
	prints("sssss", $ColorRect/Scaler.scale, pts[-1])
	print($ColorRect/Scaler.scale)
	
	audio_data.resize(audio_sample_size)
	audio_sample_image = Image.create_from_data(audio_sample_size, 1, false, Image.FORMAT_RGF, audio_data.to_byte_array())
	audio_sample_texture = ImageTexture.create_from_image(audio_sample_image)
	$ColorRect.material.set_shader_parameter(&"audiosample", audio_sample_texture)


func _ready():
	$ColorRect/Scaler.scale = Vector2($ColorRect.size.x, -$ColorRect.size.y)
	$ColorRect/Scaler.position.y = $ColorRect.size.y
	refresh_analyzer_instance()

# https://gamedev.stackexchange.com/questions/212546/how-to-make-a-multi-value-slider-in-godot

var ampscale = 1.0
func _process(delta):
	var mode = AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX if $HBoxFFT/MaxAvg.selected == 0 else AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	for i in range(len(pts)):
		var hz = pts[i].x
		var vs = spectrumanalyzerinstance.get_magnitude_for_frequency_range(hz, hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
		pts[i].y = vs.length()

	$ColorRect/Scaler/Line2D.points = pts

	var i0 = int($HBoxVolume/Index0.value)
	for i in range(audio_sample_size):
		var hz = (i+i0+0.5)*fft_freqstep
		audio_data[i] = spectrumanalyzerinstance.get_magnitude_for_frequency_range(hz, hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)

	audio_sample_image.set_data(audio_sample_size, 1, false, Image.FORMAT_RGF, audio_data.to_byte_array())
	audio_sample_texture.update(audio_sample_image)


func _on_h_slider_value_changed(value, extra_arg_0):
	#get_magnitude_for_frequency_range(p_begin, p_end)
	var pos = clamp(int(value * fft_size / (mix_rate * 0.5)), 0, fft_size-1)
	$VBoxSingleRange.get_node("HBoxLo" if extra_arg_0 == 0 else "HBoxHi").get_node("Label").text = "%d Hz: %d" % [value, pos]

	# fftpos = freqhz * fft_size / (mix_rate * 0.5);
	# freqhz = fftpos * (mix_rate * 0.5) / fft_size

func _on_volume_h_slider_value_changed(value):
	$HBoxVolume/Label.text = "%.2f dB" % linear_to_db(value)
	ampscale = value
	print(ampscale)
	$ColorRect.material.set_shader_parameter(&"mfac", 1.0/ampscale)


func _on_index_0_value_changed(value):
	$HBoxVolume/HzRange.text = "%d - %d Hz" % [int(($HBoxVolume/Index0.value + 0.5)*fft_freqstep), int(($HBoxVolume/Index0.value + audio_sample_size - 0.5)*fft_freqstep)]

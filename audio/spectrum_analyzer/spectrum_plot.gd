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
	prints(spectrumanalyzerinstance, "fft_size", fft_size, "fft history size", fft_count)

func _ready():
	refresh_analyzer_instance()
	$ColorRect/Scaler.scale = Vector2($ColorRect.size.x, -$ColorRect.size.y)
	$ColorRect/Scaler.position.y = $ColorRect.size.y

# https://gamedev.stackexchange.com/questions/212546/how-to-make-a-multi-value-slider-in-godot

var freqscale = 1.0
func _process(delta):
	var pts : PackedVector2Array = PackedVector2Array()
	pts.resize(60)
	var maxvs = 0.0001
	var mode = AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX if $HBoxFFT/MaxAvg.selected == 0 else AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	for i in range(60):
		var hz = i*50.0 + 25
		var vs = spectrumanalyzerinstance.get_magnitude_for_frequency_range(hz-25, hz+25, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
		maxvs = max(maxvs, vs.x)
		pts[i] = Vector2((i+0.5)/60, vs.x/freqscale)
	freqscale = maxvs
	$ColorRect/Scaler/Line2D.points = pts

func _on_h_slider_value_changed(value, extra_arg_0):
	#get_magnitude_for_frequency_range(p_begin, p_end)
	var pos = clamp(int(value * fft_size / (mix_rate * 0.5)), 0, fft_size-1)
	$VBoxSingleRange.get_node("HBoxLo" if extra_arg_0 == 0 else "HBoxHi").get_node("Label").text = "%d Hz: %d" % [value, pos]

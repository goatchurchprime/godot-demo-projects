extends Control

var effect: AudioEffect
var recording: AudioStreamWAV

var stereo := true
var mix_rate := 44100  # This is the default mix rate on recordings.
var format := AudioStreamWAV.FORMAT_16_BITS  # This is the default format on recordings.

var audiostreamplaybackmicrophone = null
const chunksize = 1000
var chunks = [ ]
var isrecording = false

func _ready() -> void:
	var idx := AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0)
	if ClassDB.can_instantiate("AudioStreamPlaybackMicrophone"):
		print("Instantiating AudioStreamPlaybackMicrophone")
		audiostreamplaybackmicrophone = ClassDB.instantiate("AudioStreamPlaybackMicrophone")
		audiostreamplaybackmicrophone.start_microphone()
		$AudioStreamMicButton.button_pressed = true
	else:
		$AudioStreamMicButton.disabled = true

func _process(delta):
	while audiostreamplaybackmicrophone and audiostreamplaybackmicrophone.is_microphone_playing():
		var chunk = audiostreamplaybackmicrophone.get_microphone_buffer(chunksize)
		if not chunk:
			break
		#print(chunk[100])
		if isrecording and $AudioStreamMicButton.button_pressed:
			chunks.append(chunk)

func _on_record_button_pressed() -> void:
	if isrecording:
		if audiostreamplaybackmicrophone and $AudioStreamMicButton.button_pressed:
			recording = AudioStreamWAV.new()
			recording.set_mix_rate(mix_rate)
			recording.set_format(format)
			recording.set_stereo(stereo)
			assert (format == 1)
			assert (stereo)
			var data = PackedByteArray()
			data.resize(4*len(chunks)*chunksize)
			for j in range(len(chunks)):
				for i in range(chunksize):
					var k = 4*(j*chunksize + i)
					var frame = chunks[j][i]
					var fl = int(frame.x*32767)
					var fr = int(frame.y*32767)
					data[k] = (fl & 255)
					data[k+1] = ((fl >> 8) & 255)
					data[k+2] = (fr & 255)
					data[k+3] = ((fr >> 8) & 255)
			recording.data = data
			$AudioStreamMicButton.disabled = false
		else:
			recording = effect.get_recording()
			effect.set_recording_active(false)
			recording.set_mix_rate(mix_rate)
			recording.set_format(format)
			recording.set_stereo(stereo)
		$PlayButton.disabled = false
		$SaveButton.disabled = false
		$RecordButton.text = "Record"
		$Status.text = ""
		isrecording = false

	else:
		$PlayButton.disabled = true
		$SaveButton.disabled = true
		$RecordButton.text = "Stop"
		$Status.text = "Status: Recording..."
		if audiostreamplaybackmicrophone and $AudioStreamMicButton.button_pressed:
			while audiostreamplaybackmicrophone.get_microphone_buffer(100):
				pass
			$AudioStreamMicButton.disabled = true
		else:
			effect.set_recording_active(true)
			$AudioStreamRecord.play()

		chunks = [ ]
		isrecording = true

func _on_play_button_pressed() -> void:
	print_rich("\n[b]Playing recording:[/b] %s" % recording)
	print_rich("[b]Format:[/b] %s" % ("8-bit uncompressed" if recording.format == 0 else "16-bit uncompressed" if recording.format == 1 else "IMA ADPCM compressed"))
	print_rich("[b]Mix rate:[/b] %s Hz" % recording.mix_rate)
	print_rich("[b]Stereo:[/b] %s" % ("Yes" if recording.stereo else "No"))
	var data := recording.get_data()
	print_rich("[b]Size:[/b] %s bytes" % data.size())
	$AudioStreamPlayer.stream = recording
	$AudioStreamPlayer.play()


func _on_play_music_pressed() -> void:
	if $AudioStreamPlayer2.playing:
		$AudioStreamPlayer2.stop()
		$PlayMusic.text = "Play Music"
	else:
		$AudioStreamPlayer2.play()
		$PlayMusic.text = "Stop Music"


func _on_save_button_pressed() -> void:
	var save_path: String = $SaveButton/Filename.text
	recording.save_to_wav(save_path)
	$Status.text = "Status: Saved WAV file to: %s\n(%s)" % [save_path, ProjectSettings.globalize_path(save_path)]


func _on_mix_rate_option_button_item_selected(index: int) -> void:
	match index:
		0:
			mix_rate = 11025
		1:
			mix_rate = 16000
		2:
			mix_rate = 22050
		3:
			mix_rate = 32000
		4:
			mix_rate = 44100
		5:
			mix_rate = 48000
	if recording != null:
		recording.set_mix_rate(mix_rate)


func _on_format_option_button_item_selected(index: int) -> void:
	match index:
		0:
			format = AudioStreamWAV.FORMAT_8_BITS
		1:
			format = AudioStreamWAV.FORMAT_16_BITS
		2:
			format = AudioStreamWAV.FORMAT_IMA_ADPCM
	if recording != null:
		recording.set_format(format)


func _on_stereo_check_button_toggled(button_pressed: bool) -> void:
	stereo = button_pressed
	if recording != null:
		recording.set_stereo(stereo)


func _on_open_user_folder_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))

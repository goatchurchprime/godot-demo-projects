extends HBoxContainer

var soundstreams = [ ]

@onready var polyplayback : AudioStreamPlaybackPolyphonic = $AudioStreamPlayer.get_stream_playback()

func _ready():
	var dname = "res://sounds/"
	for fname in ResourceLoader.list_directory(dname):
		var fnameabs = dname + fname
		if fname.ends_with(".wav"):
			soundstreams.append(AudioStreamWAV.load_from_file(fnameabs))
		elif fname.ends_with(".mp3"):
			soundstreams.append(AudioStreamMP3.load_from_file(fnameabs))
		elif fname.ends_with(".ogg"):
			soundstreams.append(AudioStreamOggVorbis.load_from_file(fnameabs))
		else:
			print("unknown sound file: ", fname)
			continue
		$SoundChoice.add_item("%d: %s" % [len(soundstreams)-1, fname])

func _on_play_button_pressed():
	var streamid = polyplayback.play_stream(soundstreams[$SoundChoice.selected])  # play_stream(stream: AudioStream, from_offset: float = 0, volume_db: float = 0, pitch_scale: float = 1.0, playback_type: AudioServer.PlaybackType = 0, bus: StringName = &"Master")
	var streamcancel = Button.new()
	streamcancel.tooltip_text = str(streamid)
	streamcancel.text = str($SoundChoice.selected)
	streamcancel.pressed.connect(func(): polyplayback.stop_stream(streamid); streamcancel.queue_free())
	$HBoxPoly.add_child(streamcancel)

func _process(delta):
	for streamcancel in $HBoxPoly.get_children():
		if not polyplayback.is_stream_playing(int(streamcancel.tooltip_text)):
			streamcancel.queue_free()
	

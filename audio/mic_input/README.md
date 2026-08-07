This example demonstrates how to read microphone audio input data using the
[AudioServer.get_input_frames(frames: int) -> PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_audioserver.html#class-audioserver-method-get-input-frames) function from https://github.com/godotengine/godot/pull/113288

The Microphone is turned on at startup. To change the Input Device
you must to turn it off first.

Play the music to test the speakers are working.

Play the sinusoidal tone (on another device) to see how the sound waves interact if you have
a stereo microphone.

Since an important use case of this feature is Voice over IP (VoIP) this demo
includes a time delay playback buffer with a changeable lag length when you click on `Stream Input To Output`.
The actual playback buffer aims for the target delay by either pausing or speeding up the playback stream.
An `AudioEffectPitchShift` is used to lower the pitch of the playback to compensate
for the speedup.

If you have recorded a short section of audio you can
toggle the `Loop Recording Input` button so you don't have to keep
voicing sounds into the microphone.

Language: GDScript

Renderer: Compatibility

Version: 4.7

## Screenshots
<img width="731" height="509" alt="Screenshot From 2026-08-07 20-02-46" src="https://github.com/user-attachments/assets/074c83f1-dbb3-4abd-af6f-b28c31499385" />

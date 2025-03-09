extends Node2D

func _process(delta):
	$Listener.rotation_degrees += delta*30  # print($Listener/AudioListener2D.is_current())

extends Control

func _ready() -> void:
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	gamestate.player_list_changed.connect(refresh_lobby)
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).replace("\\", "/").split("/")
		$Connect/Name.text = desktop_path[desktop_path.size() - 2]

	$Connect/Name.text = $NetworkGateway.PlayerConnections.LocalPlayer.playername()

# Deprecated
func _on_host_pressed() -> void:
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	var player_name: String = $Connect/Name.text
	gamestate.host_game(player_name)
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Server (%s)" % $Connect/Name.text
	refresh_lobby()


# Deprecated
func _on_join_pressed() -> void:
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	var ip: String = $Connect/IPAddress.text
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return

	$Connect/ErrorLabel.text = ""
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true

	var player_name: String = $Connect/Name.text
	gamestate.join_game(ip, player_name)
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Client (%s)" % $Connect/Name.text


func _on_connection_success() -> void:
	$Connect.hide()
	$Players.show()


func _on_connection_failed() -> void:
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended() -> void:
	show()
	$Connect.show()
	$Players.hide()

	$NetworkGateway.selectandtrigger_networkoption($NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.NETWORK_OFF)
	$Connect/HostButton.disabled = true
	$Connect/JoinButton.disabled = true

#	$Connect/Host.disabled = false
#	$Connect/Join.disabled = false



func _on_game_error(errtxt: String) -> void:
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false



func refresh_lobby() -> void:
	var players := gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(gamestate.player_name + " (you)")
	for p: String in players:
		$Players/List.add_item(p)

	$Players/Start.disabled = not multiplayer.is_server()


func _on_start_pressed() -> void:
	gamestate.begin_game()


func _on_find_public_ip_pressed() -> void:
	OS.shell_open("https://icanhazip.com/")

func _on_enter_plaza_pressed():
	$NetworkGateway.MQTTsignalling.Roomnametext.text = $Connect/LobbyName.text
	$NetworkGateway.PlayerConnections.LocalPlayer.setplayername($Connect/Name.text)
	$NetworkGateway.selectandtrigger_networkoption($NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_NECESSARY_MANUALCHANGE)
	$NetworkGateway.set_vox_on()
	$Connect/HostButton.disabled = false
	$Connect/JoinButton.disabled = false

func _on_network_gateway_xclientstatusesupdate():
	print("xx ", $NetworkGateway.MQTTsignalling.xclientstatuses)
	$Connect/OpenhostList.clear()
	for s in $NetworkGateway.MQTTsignalling.xclientopenservers:
		if $NetworkGateway.MQTTsignalling.xclienttreeitems[s].get_child_count() == 0:
			$Connect/OpenhostList.add_item($NetworkGateway.MQTTsignalling.xclienttreeitems[s].get_text(1) + " " + s)

func _on_host_button_pressed():
	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""
	var player_name: String = $Connect/Name.text
	gamestate.player_name = player_name
	$NetworkGateway.selectandtrigger_networkoption($NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_SERVER)
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Server (%s)" % $Connect/Name.text
	refresh_lobby()

func _on_join_button_pressed():
	var ks = $Connect/OpenhostList.get_selected_items()
	var k = (0 if len(ks) == 0 else ks[0])
	if k >= $Connect/OpenhostList.get_item_count():
		printerr("No host to connected to")
		return
	var ss = $Connect/OpenhostList.get_item_text(k)
	var s = ss.rsplit(" ")[-1]
	prints("ss ", s, ss)
	$NetworkGateway.MQTTsignalling.Roomplayertree.set_selected($NetworkGateway.MQTTsignalling.xclienttreeitems[s], 0)
	var player_name: String = $Connect/Name.text
	gamestate.player_name = player_name
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Client (%s)" % $Connect/Name.text
	$NetworkGateway.selectandtrigger_networkoption($NetworkGateway.NETWORK_OPTIONS_MQTT_WEBRTC.AS_CLIENT)

extends Node

var is_owned: bool = false
var steam_app_id: int = 480 # Test game app id
var steam_id: int = 0
var steam_username: String = ""

var lobby_id = 0
var lobby_max_members = 10

# NOTE: this has not been tested in a Steam dedicated server setup.

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")
var multiplayer_peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
#var _players_spawn_node
var _hosted_lobby_id = 0

const LOBBY_NAME = "BADGAME1"
const LOBBY_MODE = "CoOP"

func _init():
	print("Init Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))

func _process(delta):
	Steam.run_callbacks()
	
func initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam Initialize?: %s " % initialize_response)
	
	if initialize_response['status'] > 0:
		print("Failed to init Steam! Shutting down. %s" % initialize_response)
		get_tree().quit()
		
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	print("steam_id %s" % steam_id)
	
	if is_owned == false:
		print("User does not own game!")
		get_tree().quit()

func _ready():
	print("steam network load")

	Steam.lobby_created.connect(_on_lobby_created.bind())

func become_host():
	print("Starting host!")
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, SteamManager.lobby_max_members)

func join_as_client(lobby_id):
	print("Joining lobby %s" % lobby_id)
	
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	# Use Steam APIs to join lobby
	Steam.joinLobby(int(lobby_id))

func _on_lobby_created(connect: int, lobby_id):
	print("On lobby created")
	if connect == 1:
		_hosted_lobby_id = lobby_id
		print("Created lobby: %s" % _hosted_lobby_id)
		
		Steam.setLobbyJoinable(_hosted_lobby_id, true)
		
		Steam.setLobbyData(_hosted_lobby_id, "name", LOBBY_NAME)
		Steam.setLobbyData(_hosted_lobby_id, "mode", LOBBY_MODE)
		
		_create_host()

func _create_host():
	var error =  multiplayer_peer.create_host(0, [])
	
	if error == OK:
		multiplayer.set_multiplayer_peer(multiplayer_peer)
		if not OS.has_feature("dedicated_server"):
			_add_player_to_game(1)
	else:
		print("Error creating host: " + str(error))

func _add_host():
	print("add_host")
	_add_player_to_game(1)

func _on_lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	print("on lobby joined")
	if response == 1:
		var id = Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():
			print("connecting to socket...")
			connect_socket(id)
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		print(FAIL_REASON)

func connect_socket(steam_id : int):
	var error = multiplayer_peer.create_client(steam_id, 0, [])
	print("Client connect error: " + str(error))
	multiplayer.set_multiplayer_peer(multiplayer_peer)

func list_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# NOTE: If you are using the test app id, you will need to apply a filter on your game name
	# Otherwise, it may not show up in the lobby list of your clients
	Steam.addRequestLobbyListStringFilter("name", LOBBY_NAME, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)

	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	var game_node = get_tree().get_root().get_node("Game")
	var player_spawn_node = game_node.get_node("Players")
	player_spawn_node.add_child(player_to_add, true)
	
func _del_player(id: int):
	print("Player %s left the game!" % id)
	var game_node = get_tree().get_root().get_node("Game")
	var player_spawn_node = game_node.get_node("Players")
	if not player_spawn_node.has_node(str(id)):
		return
	player_spawn_node.get_node(str(id)).queue_free()




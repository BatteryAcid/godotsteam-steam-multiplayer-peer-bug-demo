extends Node

var score = 0

@onready var score_label = $ScoreLabel

func add_point():
	score += 1
	score_label.text = "You collected " + str(score) + " coins."

func become_host():
	print("Become host pressed")
	_remove_single_player()
	%SteamUI.hide()
	%MultiplayerHUD.hide()
	SteamManager.become_host()
	#MultiplayerManager.become_host()

# not supported for this demo
func join_as_player_2():
	print("Join as player 2")
	_remove_single_player()
	%MultiplayerHUD.hide()
	#MultiplayerManager.join_as_player_2()

func use_steam():
	print("use steam")
	%SteamUI.show()
	%MultiplayerHUD.hide()
	MultiplayerManager.multiplayer_mode_enabled = true
	MultiplayerManager.host_mode_enabled = true
	SteamManager.initialize_steam()
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func list_steam_lobbies():
	print("List Steam lobbies")
	SteamManager.list_lobbies()

func join_lobby(lobby_id = 0):
	print("Joining lobby %s" % lobby_id)
	_remove_single_player()
	%MultiplayerHUD.hide()
	%SteamUI.hide()
	SteamManager.join_as_client(lobby_id)

func _on_lobby_match_list(lobbies: Array):
	print("On lobby match list")
	
	for lobby_child in $"../SteamUI/Panel/ScrollContainer/LobbyList".get_children():
		lobby_child.queue_free()
		
	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
		
		if lobby_name != "":
			var lobby_mode: String = Steam.getLobbyData(lobby, "mode")
			
			var lobby_button: Button = Button.new()
			lobby_button.set_text(lobby_name + " | " + lobby_mode)
			lobby_button.set_size(Vector2(100, 30))
			lobby_button.add_theme_font_size_override("font_size", 8)
			
			var fv = FontVariation.new()
			fv.set_base_font(load("res://assets/fonts/PixelOperator8.ttf"))
			lobby_button.add_theme_font_override("font", fv)
			lobby_button.set_name("lobby_%s" % lobby)
			lobby_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			lobby_button.connect("pressed", Callable(self, "join_lobby").bind(lobby))
			
			$"../SteamUI/Panel/ScrollContainer/LobbyList".add_child(lobby_button)
			
func _remove_single_player():
	print("Remove single player")
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	player_to_remove.queue_free()
	
	
	
	

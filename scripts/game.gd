class_name Game extends Node3D

@onready var menu_background = $MenuBackground
@onready var GUI = $PuttingHUD
@onready var level_select = $LevelSelect
@onready var multiplayer_menu = $MultiplayerMenu
@onready var multiplayer_spawner = $MultiplayerSpawner
@onready var round_timer = $RoundTimer
@onready var scoreboard = $Scoreboard

var player : Golfball

var players_won : int

func _ready():
	active_game(false)
	
	level_select.change_level_signal.connect(change_level_receiver)
	level_select.golfball_left.connect(golfball_left)
	level_select.levels_found.connect(add_levels_to_spawn_list)
	
	level_select.game_won.connect(game_win_receiver)
	level_select.last_level.connect(last_level)
	
	multiplayer_menu.player_added.connect(set_player)
	multiplayer_menu.is_singleplayer.connect(select_singleplayer)
	multiplayer_menu.is_multiplayer.connect(select_multiplayer)

func update_gui_receiver():
	update_gui.rpc()

func change_level_receiver(path, level_name):
	change_level.rpc(path, level_name)

@rpc("any_peer", "call_local", "reliable")
func update_gui():
	scoreboard.update()
	GUI.update_text(player.putts)

@rpc("authority", "call_local")
func change_level(path, level_name):
	if menu_background:
		menu_background.queue_free()
		menu_background = null
	player.disable()
	update_gui.rpc()
	level_select.change_level(path, level_name)
	ready_player()
	round_timer.start_timer()
	active_game(true)

func game_win_receiver(peer_id):
	game_win.rpc(peer_id)

@rpc("any_peer", "call_local")
func game_win(peer_id):
	players_won += 1
	round_timer.stop_timer()
	
	if peer_id == player.get_multiplayer_authority():
		player.disable()
		update_gui.rpc()
	
	if players_won == get_tree().get_nodes_in_group("players").size():
		print("ALL PLAYERS HAVE WON")
		next_level.rpc()

@rpc("authority", "call_local")
func next_level():
	level_select.next_hole()
	ready_player()

func last_level():
	if multiplayer.is_server():
		active_game(false)

@rpc("authority", "call_local")
func end_game():
	round_timer.stop_timer()
	player.disable()
	update_gui.rpc()
	level_select.end_game()

func active_game(game_active):
	if game_active:
		GUI.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		level_select.visible = false
	else:
		GUI.visible = false
		level_select.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func golfball_left(peer_id):
	if player.get_multiplayer_authority() == peer_id:
		player.move_back()

func set_player(player):
	if not self.player:
		self.player = player
		player.putted.connect(update_gui_receiver)

func select_singleplayer():
	multiplayer_menu.queue_free()
	multiplayer_menu = null
	level_select.activate()

func select_multiplayer():
	if multiplayer.is_server():
		level_select.activate()

func add_levels_to_spawn_list(level_paths):
	if level_paths is Array:
		for level in level_paths:
			multiplayer_spawner.add_spawnable_scene(level)

func timeout():
	end_game.rpc()

func ready_player():
	player.enable()
	player.move_to(level_select.get_current_spawn_location_pos())
	players_won = 0

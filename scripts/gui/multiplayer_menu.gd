class_name MultiplayerMenu extends Control

@export var player_scene : PackedScene

@onready var name_line_edit = $NameSelectionContainer/NameLineEdit
@onready var ip_line_edit = $MultiplayerContainer/IPLineEdit

@onready var name_selection_container = $NameSelectionContainer
@onready var singleplayer_multiplayer_container = $SingleplayerMultiplayerContainer
@onready var multiplayer_container = $MultiplayerContainer

var username : String

const PORT = 1984
const MAX_PLAYERS = 8

var enet_peer = ENetMultiplayerPeer.new()
var peer = ENetMultiplayerPeer.new()

signal player_added

signal is_multiplayer
signal is_singleplayer

func _on_host_pressed():
	hide()
	enet_peer.create_server(PORT, MAX_PLAYERS)
	#enet_peer.set_bind_ip("0.0.0.0")
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(player_disconnected)
	add_player(multiplayer.get_unique_id())
	is_multiplayer.emit()

func _on_join_pressed():
	hide()
	enet_peer.create_client(ip_line_edit.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	add_player(multiplayer.get_unique_id())
	is_multiplayer.emit()

func add_player(peer_id):
	print("Player connected")
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.username = username
	get_tree().current_scene.add_child(player)
	player_added.emit(player)

@rpc("authority")
func player_disconnected(peer_id):
	for player in get_tree().get_nodes_in_group("players"):
		if player.get_multiplayer_authority() == peer_id:
			player.queue_free()

func _on_singleplayer_button_pressed():
	is_singleplayer.emit()
	# Host authority defaults to 1, but opens no server
	add_player(1)

func _on_multiplayer_button_pressed():
	singleplayer_multiplayer_container.queue_free()
	multiplayer_container.visible = true

func _on_name_confirm_button_pressed():
	username = str(name_line_edit.text)
	name_selection_container.queue_free()
	name_selection_container = null
	singleplayer_multiplayer_container.visible = true

class_name GolfballAudioPlayer extends Node3D

const VOLUME_OFFSET = -15

@onready var golfball_rigidbody = $".."/Golfball

@export_dir var sounds_path
@onready var audio_players = []

var audio = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize_sounds(sounds_path)
	get_audio_players()
	golfball_rigidbody.body_entered.connect(play_audio)

func initialize_sounds(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		while true:
			var tmp = dir.get_next()
			if tmp != "":
				var sound_key = tmp.capitalize()
				var sounds_path = dir.get_current_dir() + "/" + tmp
				audio[sound_key] = FileFetcher.get_sounds_in_path(sounds_path)
			else:
				dir.list_dir_end()
				break

func play_audio(body):
	#Play sound only for player
	if not golfball_rigidbody.get_parent().is_multiplayer_authority():
		return
	
	var audio_clips = get_body_material(body)
	# If body has corresponding audio
	if not audio_clips:
		return
	
	var tmp_audio_player = get_inactive_audio_player()
	# No free audio player, return!
	if not tmp_audio_player:
		return
	
	set_audio(tmp_audio_player, audio_clips)
	set_audio_player_volume(tmp_audio_player)
	tmp_audio_player.play()

func get_audio_players():
	audio_players.clear()
	for child in get_children():
		if child is AudioStreamPlayer:
			audio_players.append(child)

func get_inactive_audio_player():
	for audio_player in audio_players:
		if not audio_player.playing:
			return audio_player

func get_body_material(body):
	for group in body.get_groups():
		if audio.has(group):
			return audio[group]
	return null

func set_audio(audio_player, audio_clips):
	audio_player.stream = audio_clips[randi()%audio_clips.size()]

func set_audio_player_volume(audio_player):
	var velocity_magnitude = abs(golfball_rigidbody.linear_velocity.length())
	var golfball_max_strength = golfball_rigidbody.get_parent().MAX_STRENGTH
	audio_player.volume_db = velocity_magnitude - golfball_max_strength
	audio_player.volume_db = min(audio_player.volume_db, 0)
	print(audio_player.volume_db)

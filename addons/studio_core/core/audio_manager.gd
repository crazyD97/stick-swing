extends Node
## Music and sound effects on their own buses, with a pool of SFX players.
##
##   AudioManager.play_sfx("jump")                    # name from sfx_library, or a res:// path
##   AudioManager.play_music("res://assets/audio/music/theme.wav")
##   AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, 0.5)  # linear 0..1
##
## Every Button in the game plays the "click" sound automatically.

const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const SFX_POOL_SIZE: int = 8
const MUSIC_FADE_TIME: float = 0.6

## Short names for common sounds. Games can add their own with register_sfx().
var sfx_library: Dictionary = {
	"click": "res://assets/audio/sfx/click.wav",
	"jump": "res://assets/audio/sfx/jump.wav",
	"coin": "res://assets/audio/sfx/coin.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"win": "res://assets/audio/sfx/win.wav",
	"lose": "res://assets/audio/sfx/lose.wav",
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _music: AudioStreamPlayer
var _current_music_path: String = ""
var _cache: Dictionary = {}
var _warned: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	for i: int in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	add_child(_music)
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	# Release streams so quitting does not report leaked audio resources.
	_music.stop()
	_music.stream = null
	for player: AudioStreamPlayer in _sfx_players:
		player.stop()
		player.stream = null
	_cache.clear()


func register_sfx(sfx_name: String, path: String) -> void:
	sfx_library[sfx_name] = path


func play_sfx(sfx: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _load(sfx_library.get(sfx, sfx))
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func play_music(path: String, fade: bool = true) -> void:
	if path == _current_music_path and _music.playing:
		return
	var stream: AudioStream = _load(path)
	if stream == null:
		return
	_make_looping(stream)
	_current_music_path = path
	if fade and _music.playing:
		var out := create_tween()
		out.tween_property(_music, "volume_db", -40.0, MUSIC_FADE_TIME)
		await out.finished
	_music.stream = stream
	_music.volume_db = -40.0 if fade else 0.0
	_music.play()
	if fade:
		create_tween().tween_property(_music, "volume_db", 0.0, MUSIC_FADE_TIME)


func stop_music() -> void:
	_current_music_path = ""
	_music.stop()


func is_music_playing() -> bool:
	return _music.playing


## Volume as linear 0..1. 0 mutes the bus.
func set_bus_volume(bus: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.0)


func get_bus_volume(bus: StringName) -> float:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func _ensure_bus(bus: StringName) -> void:
	if AudioServer.get_bus_index(bus) >= 0:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, &"Master")


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		if not _warned.has(path):
			_warned[path] = true
			push_warning("AudioManager: sound not found: %s" % path)
		return null
	var stream := load(path) as AudioStream
	_cache[path] = stream
	return stream


func _make_looping(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("no_click_sound"):
		(node as BaseButton).pressed.connect(play_sfx.bind("click"))

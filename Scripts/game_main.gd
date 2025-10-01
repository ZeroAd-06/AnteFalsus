# game.gd
extends Node3D

@onready var music_player = $MusicPlayer

# 游戏内的当前时间（秒）
var song_position_sec: float = 0.0
# 歌曲是否正在播放
var is_playing: bool = false
# 地面轨道对应的x轴坐标
const TRACKS_X = [-2.85, -1.6, -0.525, 0.525, 1.6, 2.85]
# 地面轨道对应的y轴坐标
const TRACKS_Y = [0.4, 0.025, 0.025, 0.025, 0.025, 0.4]
# 地面轨道对应的z轴旋转
const TRACKS_ROTATION = [30, 0, 0, 0, 0, 30]
# Note下落的距离（z轴）
const NOTE_SPAWN_Z = -50.0
# Note流速，单位：游戏单位/秒
const NOTE_SPEED = 20.0
# 预加载Note场景
const NOTE_SCENE = preload("res://Scenes/note.tscn")


# 临时存放谱面数据
# 格式：[额定击打时间（秒）, 所在轨道（1-6）]
var chart_data = [
	[5.0, 0],
	[6.5, 4],
	[7.0, 3],
	[8.25, 4],
	[12.5, 5]
]
var next_note_index = 0

func _ready():
	# 游戏开始时调用
	start_song()

func start_song():
	is_playing = true
	music_player.play()

func _process(delta):
	if not is_playing:
		return
	
	# 从AudioStreamPlayer获取权威时间，这是最精准的
	song_position_sec = music_player.get_playback_position()
	
	# --- Note 生成逻辑 ---
	# 检查是否还有未生成的note
	if next_note_index < chart_data.size():
		var next_note = chart_data[next_note_index]
		var note_time = next_note[0]
		
		# 计算Note应该在何时生成
		# 它需要 (NOTE_SPAWN_Z / NOTE_SPEED) 秒来下落
		var spawn_lead_time = abs(NOTE_SPAWN_Z) / NOTE_SPEED
		
		# 如果当前时间已经进入了note的生成窗口期
		if song_position_sec >= note_time - spawn_lead_time:
			spawn_note(note_time, next_note[1])
			next_note_index += 1

func spawn_note(time, track):
	var note_instance = NOTE_SCENE.instantiate()
	
	# 设置note的属性
	note_instance.target_time = time
	note_instance.track = track
	note_instance.note_spawn_time = song_position_sec
	note_instance.note_spawn_z = NOTE_SPAWN_Z
	
	# 设置note的初始位置及旋转
	note_instance.position.x = TRACKS_X[track]
	note_instance.position.y = TRACKS_Y[track]
	note_instance.position.z = NOTE_SPAWN_Z
	note_instance.rotation.z = TRACKS_ROTATION[track]
	
	# 把它添加到场景树中
	add_child(note_instance)

# game.gd
extends Node3D

@onready var music_player = $MusicPlayer
@onready var score_display = $ScoreDisplay
@onready var sky_cursor = $SkyCursor
var currently_active_arc = null

# 游戏内的当前时间（秒）
var song_position_sec: float = 0.0
# 歌曲是否正在播放
var is_playing: bool = false
# 分数
var scores = 0
# 判定窗口
const JUDGE_WINDOW_EXACT_PLUS = 0.025
const JUDGE_WINDOW_EXACT = 0.050
const JUDGE_WINDOW_NEAR = 0.125
const JUDGE_WINDOW_BREAK = 0.300 # 用于处理过早按键
# Slide Note 判定的滑动距离阈值 (游戏单位)
const SLIDE_JUDGE_THRESHOLD = 0.8
# 地面轨道对应的x轴坐标
const TRACKS_X = [-2.85, -1.6, -0.525, 0.525, 1.6, 2.85]
# 地面轨道对应的y轴坐标
const TRACKS_Y = [0.4, 0.025, 0.025, 0.025, 0.025, 0.4]
# 地面轨道对应的z轴旋转
const TRACKS_ROTATION = [-30, 0, 0, 0, 0, 30]
# 地面轨道对应的x轴缩放
const TRACKS_SCALE = [1.5, 1, 1, 1, 1, 1.5]
# Note下落的距离（z轴）
const NOTE_SPAWN_Z = -50.0
# Note流速，单位：游戏单位/秒
const NOTE_SPEED = 40.0
# 预加载JudgementDisplay场景
const JUDGEMENT_DISPLAY_SCENE = preload("res://Scenes/judgement_display.tscn")
# 预加载Note场景
const NOTE_SCENE = preload("res://Scenes/note.tscn")
# 预加载 ArcNote 场景
const ARC_NOTE_SCENE = preload("res://Scenes/arc_note.tscn")
# 预加载 SlideNote 场景
const SLIDE_NOTE_SCENE = preload("res://Scenes/slide_note.tscn")


# 临时存放谱面数据
# ============================================================================
# =            Asu no Yozora Shoukaihan - Chart by AI                      =
# ============================================================================

# ----------------------------------------------------------------------------
# [GROUND] chart_data: Tap Notes
# ----------------------------------------------------------------------------
var chart_data = [
	# 00:01 - 00:11 (Intro) - Following the main beats, simple and sparse.
	[1.229, 0], [1.878, 4], [2.527, 5], [3.175, 2], [3.824, 3], [4.473, 3], [5.121, 5], [5.770, 2], [6.419, 5], [7.067, 5], [7.716, 4], [8.202, 2], [8.527, 1], [9.013, 3], [9.500, 2], [10.310, 4], [10.797, 4], [11.121, 3], [11.446, 1],

	# 00:11 - 00:27 (Verse 1) - Rhythm becomes more consistent.
	[11.770, 1], [12.256, 3], [12.581, 4], [12.905, 4], [13.391, 5], [13.716, 5], [14.202, 5], [14.689, 4], [15.013, 4], [15.500, 3], [16.148, 0], [16.473, 0], [16.797, 0], [17.283, 3], [17.608, 4], [18.094, 5], [18.419, 5], [19.067, 5], [19.716, 5], [20.364, 4], [20.851, 2], [21.337, 2], [21.662, 3], [21.824, 3],

	# 00:27 - 00:35 (Pre-Chorus) - Building tension, faster taps.
	[27.337, 0], [27.986, 2], [28.635, 3], [28.959, 4], [29.283, 5], [29.932, 5], [30.256, 5], [31.229, 5], [31.554, 4], [32.527, 5], [33.175, 5], [33.824, 5], [34.148, 4], [34.473, 3],

	# 00:35 - 00:53 (Chorus 1) - Strong beats to anchor the player during complex sky patterns.
	[35.121, 1], [35.770, 3], [36.256, 5], [36.743, 5], [37.067, 5], [37.716, 5], [38.202, 4], [38.851, 2], [39.337, 3], [39.662, 4], [40.148, 5], [40.635, 5], [40.959, 5], [41.446, 5], [41.932, 4], [42.256, 3], [42.581, 2], [42.905, 0], [43.391, 4], [43.716, 5], [44.040, 5], [44.527, 4], [44.851, 3], [45.337, 4], [46.148, 5], [46.635, 5], [47.121, 4], [47.446, 3], [47.932, 2], [48.094, 2], [48.581, 4], [49.229, 5], [49.716, 5], [50.202, 5], [50.527, 5], [51.013, 4], [51.337, 3], [51.824, 3], [52.310, 0], [52.635, 0], [52.959, 0],

	# 00:53 - 01:23 (Verse 2 & Buildup) - Return to simpler patterns.
	[53.283, 1], [53.770, 4], [54.419, 5], [54.743, 5], [55.229, 5], [56.527, 2], [56.851, 1], [57.175, 2], [57.824, 4], [58.473, 4], [59.770, 4], [60.094, 3], [60.743, 5], [61.716, 5], [62.040, 4], [62.364, 3], [63.013, 2], [63.662, 4], [63.986, 5], [64.310, 5], [64.959, 5], [65.283, 5], [65.608, 4], [66.094, 3], [66.905, 0], [67.229, 1], [67.554, 2], [68.202, 4], [68.851, 5], [69.175, 5], [69.500, 5], [70.148, 4], [70.473, 3], [70.797, 3], [71.283, 1], [72.094, 2], [72.419, 4], [72.743, 5], [73.391, 5], [74.040, 4], [74.364, 3], [74.689, 4], [75.337, 5], [75.986, 4]
]


# ----------------------------------------------------------------------------
# [SKY] arc_chart_data: Arc Notes
# Format: [ StartTime, EndTime, [ [Time, Left, Right, "linear"], ... ] ]
# ----------------------------------------------------------------------------
var arc_chart_data = [
	# 00:11 - 00:27 (Verse 1) - Gentle, wide arc following the vocals.
	[11.5, 27.0, [
		[11.5, -2.0, 2.0, "linear"],
		[14.0, 0.0, 3.5, "linear"],
		[17.0, -3.5, -0.5, "linear"],
		[20.0, 1.0, 3.0, "linear"],
		[22.0, -3.0, -1.0, "linear"],
		[25.0, -1.0, 1.0, "linear"],
		[27.0, -3.5, 3.5, "linear"]
	]],

	# 00:27 - 00:53 (Chorus 1) - Intense, fast-moving, and sharply changing width.
	[27.3, 53.0, [
		[27.3, -3.5, 3.5, "linear"],
		[28.9, -1.0, 1.0, "linear"],
		[29.9, -3.0, 3.0, "linear"],
		[30.2, -3.0, -1.0, "linear"],
		[31.2, 1.0, 3.0, "linear"],
		[32.5, -3.5, 3.5, "linear"],
		[33.1, -1.5, 1.5, "linear"],
		[34.4, -3.5, -1.5, "linear"],
		[35.1, -3.5, 3.5, "linear"], # Width snap for chorus drop
		[35.11, -1.0, 1.0, "linear"],
		[36.2, 1.5, 3.5, "linear"],
		[37.7, -3.5, -1.5, "linear"],
		[39.3, -0.5, 0.5, "linear"],
		[40.1, -3.5, -2.0, "linear"],
		[40.9, 2.0, 3.5, "linear"],
		[42.5, -2.0, 2.0, "linear"],
		[44.0, -3.5, -2.5, "linear"],
		[44.01, 3.0, 3.5, "linear"], # Very sharp position and width change
		[45.3, -3.5, -3.0, "linear"],
		[47.4, 0.0, 2.0, "linear"],
		[49.2, -2.0, 0.0, "linear"],
		[50.5, -3.5, 3.5, "linear"],
		[51.8, -1.0, 1.0, "linear"],
		[53.0, -0.5, 0.5, "linear"]
	]],

	# 00:53 - 01:18 (Verse 2 & Buildup) - Slower movement with some tricky narrow sections.
	[53.2, 76.0, [
		[53.2, -3.0, 3.0, "linear"],
		[55.7, -1.5, 0.0, "linear"],
		[58.4, 0.0, 1.5, "linear"],
		[60.9, -3.5, -1.0, "linear"],
		[63.6, 1.0, 3.5, "linear"],
		[66.0, -1.0, 1.0, "linear"],
		[68.2, -3.5, 0.5, "linear"],
		[68.21, 0.5, 3.5, "linear"], # Width snap
		[70.7, -2.5, 2.5, "linear"],
		[72.7, -0.5, 0.5, "linear"],
		[74.6, -3.5, 3.5, "linear"],
		[76.0, 0.0, 0.0, "linear"] # Contract to center point for ending
	]]
]


# ----------------------------------------------------------------------------
# [SKY] slide_chart_data: Slide Notes
# Format: [Time, X, Width, Direction(-1 Left, 1 Right)]
# ----------------------------------------------------------------------------
var slide_chart_data = [
	# 00:11 - 00:27 (Verse 1) - Slides to introduce the mechanic.
	[11.2, -1.5, 1.5, 1], # Lead-in slide
	[17.4, -2.0, 2.0, 1],
	[17.7, 0.0, 2.0, -1],
	[26.7, -3.0, 2.0, 1], # Lead-out slide
	[26.85, 0.0, 2.0, 1],
	[27.0, 3.0, 2.0, 1],

	# 00:27 - 00:53 (Chorus 1) - High density, crossing slides.
	[29.5, 0.0, 3.0, -1], [29.7, 0.0, 3.0, 1],
	[30.5, -2.0, 1.5, 1],
	[31.5, 2.0, 1.5, -1],
	[33.5, 0.0, 3.0, 1], [33.65, 0.0, 3.0, -1], [33.8, 0.0, 3.0, 1],
	[34.7, -2.5, 1.5, 1],
	[35.4, 0.0, 2.0, -1], [35.6, 0.0, 2.0, 1],
	[38.0, -2.5, 2.0, 1], [38.2, -2.5, 2.0, -1],
	[39.5, 0.0, 1.0, -1], [39.6, 0.0, 1.0, 1],
	[41.1, 2.75, 1.5, -1],
	[41.25, -2.75, 1.5, 1],
	[44.2, -3.25, 1.0, 1], [44.4, 3.25, 1.0, -1], # Slides right after the snap
	[46.4, 1.0, 1.5, -1], [46.6, 1.0, 1.5, 1],
	[48.8, -1.0, 1.5, 1], [49.0, -1.0, 1.5, -1],
	[51.0, 2.0, 3.0, -1], [51.2, -2.0, 3.0, 1],

	# 00:53 - 01:18 (Verse 2 & Buildup) - Rhythmic slides, some requiring quick reactions.
	[54.0, 0.0, 4.0, 1],
	[54.2, 0.0, 4.0, -1],
	[59.0, -0.75, 1.0, 1],
	[59.2, 0.75, 1.0, -1],
	[67.8, -1.5, 5.0, 1], # A wide slide during a position change
	[68.5, 2.0, 3.0, -1],
	[71.0, 0.0, 5.0, -1],
	[71.2, 0.0, 5.0, 1],
	[73.0, 0.0, 1.0, 1], [73.2, 0.0, 1.0, -1], [73.4, 0.0, 1.0, 1], [73.6, 0.0, 1.0, -1], # Final flurry
	[75.5, -3.0, 2.0, 1], # Slides into the final hold
	[75.75, 3.0, 2.0, -1]
]
var next_slide_index = 0
var next_note_index = 0
var next_arc_index = 0
var active_slide_note = null

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
	
	# --- Arc Note 生成逻辑 ---
	if next_arc_index < arc_chart_data.size():
		var next_arc_data = arc_chart_data[next_arc_index]
		var arc_start_time = next_arc_data[0]
		
		# Arc 的生成时机是它的 "最远端" 快要进入视野时
		# 我们用 Arc 的结束时间来计算
		var arc_end_time = next_arc_data[1]
		var z_length_of_arc = (arc_end_time - arc_start_time) * NOTE_SPEED
		var spawn_lead_time = (abs(NOTE_SPAWN_Z) + z_length_of_arc) / NOTE_SPEED
		if song_position_sec >= arc_start_time - spawn_lead_time:
			spawn_arc(next_arc_data)
			next_arc_index += 1
	
	# --- Slide Note 生成逻辑 ---
	if next_slide_index < slide_chart_data.size():
		var next_slide = slide_chart_data[next_slide_index]
		var note_time = next_slide[0]
		var spawn_lead_time = abs(NOTE_SPAWN_Z) / NOTE_SPEED
		
		if song_position_sec >= note_time - spawn_lead_time:
			spawn_slide(next_slide)
			next_slide_index += 1

	
	# --- Arc 连续判定逻辑 ---
	# 首先，检查是否有新的 Arc 变成了 "当前活跃" 的
	# 注意：这里的实现比较简单，实际项目中你可能需要把所有arc存起来再查找
	if currently_active_arc == null:
		for node in get_children():
			if node is ArcNote and song_position_sec >= node.start_time and song_position_sec <= node.end_time:
				currently_active_arc = node
				break
	
	# 如果有活跃的 Arc，进行判定
	if currently_active_arc:
		# 检查 Arc 是否已经结束
		if song_position_sec > currently_active_arc.end_time:
			print("Arc completed!")
			currently_active_arc = null
		else:
			# 获取当前时间点，Arc要求的左右边界
			var boundaries = currently_active_arc.get_boundaries_at_time(song_position_sec)
			var cursor_x = sky_cursor.position.x
			
			# 开始判定！
			if cursor_x >= boundaries.x and cursor_x <= boundaries.y:
				# 在区间内
				# print("Arc: EXACT+") # 频繁打印会卡，先注释掉
				# 可以在这里持续加分
				scores += (100000000.0 / 723.0 * delta) # 假设一秒60帧，分数均摊
				score_display.scores = int(scores)
				currently_active_arc.change_mesh_color(Color(1.0, 0.5, 1.0, 0.3))
			else:
				# 在区间外
				currently_active_arc.change_mesh_color(Color(1.0, 0, 0, 0.3))
	# --- Slide Note 判定逻辑 ---
	# 1. 检查是否有新的 Slide Note 进入判定窗口
	if active_slide_note == null:
		for node in get_children():
			# 找到一个还未被判定的 Slide Note
			if node is SlideNote and not node.was_judged:
				var time_diff = abs(node.target_time - song_position_sec)
				# 使用与 Near 相同的判定窗口
				if time_diff <= JUDGE_WINDOW_NEAR:
					# 新增：获取 Note 的左右边界
					var note_x = node.position.x
					# 注意：node.scale.x 可能为负数（用于翻转），所以要用 abs()
					var note_half_width = abs(node.scale.x) / 2.0 
					var note_left_bound = note_x - note_half_width
					var note_right_bound = note_x + note_half_width
					# 新增：检查光标是否在 Note 的范围内
					if sky_cursor.position.x >= note_left_bound and sky_cursor.position.x <= note_right_bound:
						# 只有当时间和空间都正确时，才激活 Note
						active_slide_note = node
						active_slide_note.enter_judge_window(sky_cursor.position.x)
						break # 找到一个就够了，跳出循环

	
	# 2. 如果存在一个活跃的 Slide Note，则持续进行判定
	if active_slide_note:
		var is_finished = active_slide_note.judge_slide(sky_cursor.position.x)
		
		# 如果判定已完成，或者 Note 已经错过了判定窗口，则清空
		var time_diff_from_target = song_position_sec - active_slide_note.target_time
		if is_finished or time_diff_from_target > JUDGE_WINDOW_NEAR:
			active_slide_note = null




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
	note_instance.scale.x = TRACKS_SCALE[track]
	note_instance.rotation_degrees.z = TRACKS_ROTATION[track]
	
	# 把它添加到场景树中
	add_child(note_instance)

func spawn_arc(arc_data):
	var arc_instance = ARC_NOTE_SCENE.instantiate()
	
	# 传递必要的信息
	arc_instance.note_speed = NOTE_SPEED
	arc_instance.start_time = arc_data[0]
	arc_instance.end_time = arc_data[1]
	arc_instance.key_points = arc_data[2]
	
	# 计算初始位置
	# 这里的逻辑是关键：我们计算出在生成的这一刻，Arc的起点应该在哪个Z坐标
	# 这样它才能在正确的start_time到达判定线
	var time_until_start = arc_instance.start_time - song_position_sec
	arc_instance.position = Vector3(0, 0.675, -time_until_start * NOTE_SPEED)
	
	# 先把它添加到场景树中
	add_child(arc_instance)

func spawn_slide(slide_data):
	var slide_instance = SLIDE_NOTE_SCENE.instantiate()
	# 1. 传递基础信息
	slide_instance.target_time = slide_data[0]
	slide_instance.direction = slide_data[3] # 脚本内部依然需要知道方向
	slide_instance.note_speed = NOTE_SPEED
	# 2. 设置 Note 的宽度和方向
	# slide_data[2] 是谱面中定义的宽度
	# slide_data[3] 是方向 (-1 或 1)
	slide_instance.scale.x = slide_data[2] * slide_data[3]
	# 3. 设置 Note 的位置
	# Y 轴位置和 Z 轴位置的逻辑保持不变
	slide_instance.position.x = slide_data[1]
	var time_until_hit = slide_instance.target_time - song_position_sec
	slide_instance.position.y = 0.675 
	slide_instance.position.z = -time_until_hit * NOTE_SPEED
	add_child(slide_instance)


func add_score(judgement: String, position: Vector3):
	var base_score = 100000000 / 723 # 假设总物量是723
	match judgement:
		"Exact+":
			scores += base_score + 1
		"Exact":
			scores += base_score
		"Near":
			scores += base_score * 0.4
		"Break":
			# Break 不加分
			pass
	score_display.scores = int(scores)
	# --- 生成判定文本特效 ---
	var judgement_instance = JUDGEMENT_DISPLAY_SCENE.instantiate()
	
	# 设置实例的初始位置
	judgement_instance.position = position
	
	# 根据判定结果选择文本和颜色
	var display_text = judgement
	var display_color = Color.WHITE
	match judgement:
		"Exact+":
			display_color = Color.CYAN
		"Exact":
			display_color = Color.DARK_BLUE
		"Near":
			display_color = Color.LEMON_CHIFFON
	add_child(judgement_instance)
	judgement_instance.show_judgement(judgement, display_color)



func _input(event):
	# 检查所有轨道的输入
	for i in range(0, 6):
		if event.is_action_pressed("ground_track_" + str(i) + "_press"):
			judge_press(i)
func judge_press(track_num):
	var press_time = song_position_sec
	var best_note_to_hit = null
	var best_note_diff = JUDGE_WINDOW_BREAK # 设置一个最大可接受的误差
	# 遍历当前场景中所有的Note子节点
	for node in get_children():
		if node is Node3D and node.has_method("get_is_note"): # 创建一个get_is_note来识别Note
			# 检查轨道是否匹配
			if node.track == track_num:
				var diff = abs(node.target_time - press_time)
				if diff < best_note_diff:
					best_note_diff = diff
					best_note_to_hit = node
	
	# 如果找到了一个可以判定的Note
	if best_note_to_hit:
		var diff = best_note_to_hit.target_time - press_time
		var hit_position = Vector3(TRACKS_X[track_num], TRACKS_Y[track_num] + 0.3, -0.5)
		if abs(diff) <= JUDGE_WINDOW_EXACT_PLUS:
			print("Exact+! 误差:", diff * 1000, "ms")
			add_score("Exact+", hit_position)
		elif abs(diff) <= JUDGE_WINDOW_EXACT:
			print("Exact! 误差:", diff * 1000, "ms")
			add_score("Exact", hit_position)
		elif abs(diff) <= JUDGE_WINDOW_NEAR:
			print("Near! 误差:", diff * 1000, "ms")
			add_score("Near", hit_position)
		else:
			print("Break! (Too Early)")
			add_score("Break", hit_position)
		
		# 销毁被击中的Note
		best_note_to_hit.queue_free()
		# 更新分数
		score_display.scores = int(scores)


func _unhandled_input(event):
	# "ui_cancel" 在 Godot 中默认绑定到了 Escape 键
	if event.is_action_pressed("ui_cancel"):
		# 检查当前鼠标是什么模式
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# 如果是锁定模式，就把它改回可见模式
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			# 如果是可见模式，就再把它锁定回去
			# 这在测试时很方便，可以随时锁定/解锁鼠标
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

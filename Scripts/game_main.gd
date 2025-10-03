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
# 预加载Note场景
const NOTE_SCENE = preload("res://Scenes/note.tscn")
# 预加载 ArcNote 场景
const ARC_NOTE_SCENE = preload("res://Scenes/arc_note.tscn")
# 预加载 SlideNote 场景
const SLIDE_NOTE_SCENE = preload("res://Scenes/slide_note.tscn")


# 临时存放谱面数据
# chart_data, arc_chart_data, 和 slide_chart_data 的完整演示谱面
# ============================================================================
# =                          DEMONSTRATION CHART                             =
# ============================================================================
# ============================================================================
# =                     DEMONSTRATION CHART (REVISED v2)                     =
# ============================================================================

# ----------------------------------------------------------------------------
# [GROUND] chart_data: Tap Notes (No changes needed)
# ----------------------------------------------------------------------------
var chart_data = [
	[1.350, 2], [2.698, 3], [4.046, 2], [5.394, 3], [6.069, 1], [6.743, 4], [8.091, 2], [9.439, 3], [10.788, 1],
	[12.136, 0], [12.473, 5], [13.147, 1], [13.821, 4], [14.496, 2], [15.170, 3], [15.844, 1], [16.518, 4], [17.192, 2], 
	[17.529, 3], [17.866, 1], [18.203, 4], [18.541, 0], [18.878, 5], [19.215, 2], [19.552, 3], [19.889, 1], [20.226, 4], 
	[20.563, 2], [20.900, 3], [21.237, 1], [21.574, 4],
	[22.923, 2], [23.260, 3], [23.934, 1], [24.271, 4], [24.608, 0], [25.282, 5], [25.619, 2], [25.956, 3], [26.630, 0], 
	[26.967, 5], [27.305, 1], [27.979, 4], [28.316, 2], [28.653, 3], [29.327, 1], [29.664, 4], [30.001, 0], [30.675, 5], 
	[31.012, 1], [31.349, 4], [32.024, 2], [32.361, 3], [32.698, 0], [33.372, 5], [33.709, 2], [34.046, 3], [34.720, 1], 
	[35.057, 4], [35.394, 0], [36.069, 5], [36.406, 2], [36.743, 3], [37.417, 1], [37.754, 4], [38.091, 0], [38.765, 5], 
	[39.102, 1], [39.439, 4], [40.114, 2], [40.451, 3], [40.788, 0], [41.462, 5], [41.799, 1], [42.136, 4], [42.810, 2], [43.147, 3],
	[44.496, 0], [44.833, 5], [45.338, 1], [45.507, 4], [45.844, 2], [46.181, 3], [46.687, 0], [46.855, 1], [47.192, 5], 
	[47.529, 4], [48.035, 2], [48.203, 3], [48.541, 0], [48.878, 1], [49.046, 5], [49.383, 4], [49.552, 2], [49.889, 3], 
	[50.226, 0], [50.732, 1], [50.900, 2], [51.237, 5], [51.574, 4], [52.080, 0], [52.248, 1], [52.585, 2], [52.923, 3], 
	[53.428, 5], [53.597, 4], [53.934, 0], [54.271, 1], [54.439, 2], [54.776, 5], [54.945, 4], [55.282, 0], [55.282, 3], 
	[55.619, 1], [56.125, 2], [56.293, 3], [56.630, 1], [56.630, 4], 
	[56.967, 0], [57.473, 5], [57.642, 4], [57.810, 5], [57.979, 4], [58.316, 1], [58.821, 2], [58.990, 3], [59.327, 0], 
	[59.664, 1], [59.833, 2], [60.170, 5], [60.338, 4], [60.675, 3], [61.012, 0],
	[61.518, 1], [61.687, 4], [62.024, 2], [62.361, 3], [62.698, 0], [62.866, 5], [63.372, 0], [63.372, 5], 
	[63.709, 2], [64.215, 3], [64.383, 1], [64.720, 4], [65.057, 2], [65.226, 3], [65.563, 1], [65.732, 4], [66.069, 0], 
	[66.406, 2], [66.406, 3], 
	[66.911, 1], [67.080, 4], [67.417, 0], [67.754, 1], [67.754, 4], 
	[68.260, 2], [68.428, 3], [68.765, 0], [69.102, 1], [69.102, 5], 
	[69.608, 2], [69.776, 3], [70.114, 1], [70.451, 4], [70.619, 2], [70.956, 3], [71.125, 1], [71.462, 4], [71.799, 0], [71.799, 5], 
	[72.305, 1], [72.473, 4], [72.810, 2], [73.147, 0], [73.147, 3], 
	[73.653, 1], [73.821, 5], [74.158, 2], [74.496, 1], [74.496, 4], 
	[75.001, 0], [75.170, 5], [75.507, 2], [75.844, 3], [76.012, 1], [76.349, 4], [76.518, 0], [76.855, 5], [77.192, 1], [77.192, 4], 
	[77.698, 0], [77.866, 5], [78.203, 2], [78.541, 0], [78.541, 3], 
	[79.046, 1], [79.215, 4], [79.552, 2], [79.889, 0], [79.889, 5], 
	[80.394, 1], [80.563, 4], [80.900, 2], [81.237, 3], [81.406, 0], [81.743, 5], [81.911, 1], [82.248, 4], [82.585, 2], [82.585, 3], 
	[83.091, 0], [83.260, 5], [83.597, 1], [83.934, 2], [83.934, 4], 
	[84.439, 0], [84.608, 5], [84.945, 1], [85.282, 0], [85.282, 3], 
	[85.788, 2], [85.956, 4], [86.293, 1],
	[87.642, 3], [87.979, 2], [88.653, 4], [88.990, 1], [89.327, 3], [90.001, 5], [90.338, 0], [90.675, 4], [91.349, 1], 
	[91.687, 3], [92.024, 2], [92.698, 4], [93.035, 1], [93.372, 5], [94.046, 0], [94.383, 2], [94.720, 3], [95.394, 1], 
	[95.732, 4], [96.069, 0], [96.743, 5], [97.080, 2], [97.417, 3], [97.585, 1], [97.923, 4], [98.091, 0], [98.428, 5], 
	[98.765, 2], [99.439, 3], [99.776, 1], [100.114, 4], [100.788, 0], [101.125, 5], [101.462, 2], [102.136, 3], [102.473, 1], 
	[102.810, 4], [103.484, 0], [103.821, 5], [104.158, 2], [104.833, 3], [105.170, 1], [105.507, 4], [106.181, 0], [106.518, 5], 
	[106.855, 1], [107.529, 4], [107.866, 2], [108.203, 3], [108.372, 0], [108.709, 5], [108.878, 1], [109.215, 4],
	[110.563, 2], [111.911, 3], [114.608, 1], [115.956, 4], [117.305, 0], [119.496, 5], [120.001, 2], [121.349, 3], [122.698, 1], 
	[124.720, 4], [125.394, 0], [126.743, 5], [128.091, 2],
	[130.788, 1], [131.125, 4], [131.462, 0], [131.799, 5], [132.136, 1], [132.473, 4], [132.810, 2], [132.979, 3], [133.484, 0], 
	[133.821, 1], [134.158, 2], [134.496, 3], [134.664, 4], [135.001, 5], [135.338, 0], [135.507, 1], [135.844, 2], [136.181, 3], 
	[136.406, 4], [136.630, 5], [136.855, 0], [137.192, 1], [137.529, 2], [137.866, 3], [138.203, 4], [138.372, 5], [138.541, 0], 
	[138.878, 1], [139.046, 2], [139.215, 3], [139.383, 4], [139.552, 5], [139.889, 0], [140.057, 1], [140.394, 2], [140.563, 3], 
	[140.900, 4], [141.237, 5], [141.574, 0], [141.911, 1], [142.248, 2], [142.585, 3], [142.923, 4], [143.260, 5], [143.597, 0], 
	[143.934, 1], [144.271, 2], [144.608, 3], [144.945, 4], [145.282, 5], [145.619, 0], [145.956, 1], [146.293, 2], [146.630, 3], 
	[146.967, 4], [147.305, 5], [147.642, 0], [147.979, 1], [148.316, 2], [148.653, 3], [148.990, 4], [149.327, 5], [149.664, 0], 
	[150.001, 1], [150.338, 2], [150.675, 3], [151.012, 4],
	[152.024, 0], [152.361, 1], [152.698, 2], [152.698, 3],
	[153.203, 5], [153.372, 4], [153.709, 0], [154.046, 1], [154.046, 5],
	[154.552, 2], [154.720, 3], [155.057, 0], [155.394, 2], [155.394, 4],
	[155.900, 1], [156.069, 5], [156.406, 0], [156.743, 2], [156.911, 3], [157.248, 1], [157.417, 4], [157.754, 0], [158.091, 2], [158.091, 5],
	[158.597, 1], [158.765, 4], [159.102, 2], [159.439, 0], [159.439, 3],
	[159.945, 1], [160.114, 5], [160.451, 2], [160.788, 1], [160.788, 4],
	[161.293, 0], [161.462, 5], [161.799, 2], [162.136, 3], [162.305, 1], [162.642, 4], [162.810, 0], [163.147, 5], [163.484, 1], [163.484, 4],
	[163.990, 0], [164.158, 5], [164.496, 2], [164.833, 0], [164.833, 3],
	[165.338, 1], [165.507, 4], [165.844, 2], [166.181, 0], [166.181, 5],
	[166.687, 1], [166.855, 4], [167.192, 2], [167.529, 3], [167.698, 0], [168.035, 5], [168.203, 1], [168.541, 4], [168.878, 2], [168.878, 3],
	[169.383, 0], [169.552, 5], [169.889, 1], [170.226, 2], [170.226, 4],
	[170.732, 0], [170.900, 5], [171.237, 1], [171.574, 0], [171.574, 3],
	[172.080, 2], [172.248, 4], [172.585, 1], [173.934, 3], [174.271, 2], [174.608, 4], [174.945, 1], [175.282, 3], [175.788, 5], 
	[176.293, 0], [176.630, 4], [176.967, 1], [177.305, 3], [177.642, 2], [177.979, 4], [178.484, 1], [178.990, 5], [179.327, 0], 
	[179.664, 2], [180.001, 3], [180.338, 1], [180.675, 4], [181.181, 0], [181.687, 5], [182.024, 2], [182.361, 3], [182.698, 1], 
	[183.035, 4], [183.372, 0], [183.878, 5], [184.383, 1], [184.552, 2], [184.720, 3], [185.057, 4], [185.394, 5], [185.732, 0], 
	[186.069, 1], [186.406, 2], [186.574, 3], [186.911, 4], [187.080, 5], [187.417, 0], [187.754, 1], [188.091, 2], [188.428, 3], 
	[188.765, 4], [189.102, 5], [189.271, 0], [189.608, 1], [189.776, 2], [190.114, 3], [190.451, 4], [190.788, 5], [191.125, 0], 
	[191.462, 1], [191.799, 2], [191.967, 3], [192.305, 4], [192.473, 5], [192.810, 0], [193.147, 1], [193.484, 2], [193.821, 3], 
	[194.158, 4], [194.496, 5], [194.664, 0], [195.001, 1], [195.170, 2], [195.507, 0], [195.507, 5]
]

# ----------------------------------------------------------------------------
# [SKY] arc_chart_data: Arc Notes (## REVISED ## - Enhanced & Fixed)
# ----------------------------------------------------------------------------
var arc_chart_data = [
	# 00:00 - 00:11 (引子) - 更具动态的开场
	[2.5, 11.0, [
		[2.5, -1.0, 1.0, "linear"], [4.0, -2.5, -1.5, "linear"],
		[6.0, 1.5, 2.5, "linear"], [8.0, -0.5, 0.5, "linear"],
		[11.0, -3.0, 3.0, "linear"]
	]],
	# 00:12 - 00:22 (构建) - 快速收缩，制造紧张感
	[15.0, 21.8, [
		[15.0, -3.6, 3.6, "linear"], [18.0, -2.5, 2.5, "linear"],
		[20.0, -0.5, 0.5, "linear"], [21.8, 0.0, 0.0, "linear"] # 最终汇聚于一点
	]],
	# 00:22 - 00:44 (副歌 1) - 狂野的Z字形移动和宽度变化
	[22.8, 43.5, [
		[22.8, -1.0, 1.0, "linear"], [24.0, -3.6, 0.0, "linear"],
		[26.0, 0.0, 3.6, "linear"], [29.0, -3.6, 3.6, "linear"],
		[32.0, -0.5, 0.5, "linear"], [35.0, -2.0, 3.6, "linear"],
		[38.0, -3.6, 2.0, "linear"], [41.0, -0.5, 0.5, "linear"],
		[43.5, -3.6, 3.6, "linear"]
	]],
	# 00:44 - 01:06 (主歌 1) - 缓慢但宽阔的左右摇摆
	[45.0, 60.0, [
		[45.0, -3.6, -1.0, "linear"], [52.5, 1.0, 3.6, "linear"],
		[60.0, -3.6, -1.0, "linear"]
	]],
	# 01:06 - 01:27 (前副歌 & 桥段) - 配合情感爆发的急剧扩张
	[61.5, 72.0, [
		[61.5, -0.2, 0.2, "linear"], [66.0, -2.5, 2.5, "linear"],
		[69.0, -1.0, 1.0, "linear"], [72.0, -3.6, 3.6, "linear"]
	]],
	# 01:27 - 01:48 (副歌 2) - 更复杂的波浪形移动
	[73.0, 86.5, [
		[73.0, -3.6, 3.6, "linear"], [75.0, -3.6, -1.6, "linear"],
		[77.0, 1.6, 3.6, "linear"], [79.0, -1.0, 1.0, "linear"],
		[81.0, 1.6, 3.6, "linear"], [83.0, -3.6, -1.6, "linear"],
		[85.0, -0.5, 0.5, "linear"], [86.5, -3.6, 3.6, "linear"]
	]],
	# 02:10 - 02:31 (实验性过场) - 更加破碎和快速的短Arc
	[110.0, 113.5, [[110.0, -3.0, -1.0, "linear"], [111.75, 1.0, 3.0, "linear"], [113.5, -1.0, 1.0, "linear"]]],
	[115.0, 118.5, [[115.0, 1.0, 3.0, "linear"], [116.75, -3.0, -1.0, "linear"], [118.5, -1.0, 1.0, "linear"]]],
	[120.0, 129.0, [
		[120.0, -0.5, 0.5, "linear"], [122.0, -3.6, 3.6, "linear"],
		[124.0, -0.5, 0.5, "linear"], [126.0, -3.6, 3.6, "linear"],
		[129.0, -1.5, 1.5, "linear"]
	]],
	# ## MERGED & ENHANCED ## 02:32 - 02:53 (最终构建) - 合并为一条高速穿梭Arc
	[131.0, 151.5, [
		[131.0, -3.6, -1.6, "linear"], [134.0, 1.6, 3.6, "linear"],
		[137.0, -1.0, 1.0, "linear"], [140.0, -3.6, 0.0, "linear"],
		[143.0, 0.0, 3.6, "linear"], [146.0, -3.6, 3.6, "linear"],
		[149.0, -0.5, 0.5, "linear"], [151.5, -3.6, 3.6, "linear"]
	]],
	# 02:54 - 03:21 (最终副歌) - 终曲，最华丽的动态Arc
	[152.5, 195.5, [
		[152.5, -3.6, 3.6, "linear"], [157.5, -1.0, 1.0, "linear"],
		[162.5, -3.6, 0.0, "linear"], [165.0, 0.0, 3.6, "linear"],
		[172.5, -3.6, 3.6, "linear"], [177.5, -0.5, 0.5, "linear"],
		[182.5, -2.0, 2.0, "linear"], [187.5, -3.6, 3.6, "linear"],
		[190.0, -3.6, -2.0, "linear"], [192.5, 2.0, 3.6, "linear"],
		[195.5, -3.6, 3.6, "linear"]
	]]
]


# ----------------------------------------------------------------------------
# [SKY] slide_chart_data: Slide Notes (## REVISED ## - Positions fixed)
# ----------------------------------------------------------------------------
var slide_chart_data = [
	[17.360, -2.0, 2.0, -1], [17.698, 2.0, 2.0, 1],
	[18.372, -2.0, 2.0, -1], [18.709, 2.0, 2.0, 1],
	[21.300, 0.0, 1.0, 1], [21.450, 0.0, 1.0, -1], [21.600, 0.0, 1.0, 1],
	[24.945, -2.0, 1.8, 1], [25.113, 2.0, 1.8, -1],
	[29.495, 2.0, 1.8, 1], [29.832, -2.0, 1.8, -1],
	[34.380, 2.5, 1.8, 1], [34.548, -2.5, 1.8, -1],
	[39.270, 2.0, 1.8, 1], [39.607, -2.0, 1.8, -1],
	[41.630, 0.0, 2.5, -1], [41.970, 0.0, 2.5, 1],
	[74.327, 2.5, 1.8, 1], [74.664, -2.5, 1.8, -1],
	[78.709, 2.5, 1.8, 1], [79.383, -2.5, 1.8, -1],
	[83.428, 2.5, 1.8, 1], [83.765, -2.5, 1.8, -1],
	[85.450, -2.0, 2.5, 1], [85.800, 2.0, 2.5, -1],
	# ## POSITIONS CORRECTED ## slides moved inside their parent Arcs
	[110.899, -2.0, 1.5, 1], [112.585, 2.0, 1.5, -1],
	[115.899, 2.0, 1.5, 1], [117.585, -2.0, 1.5, -1],
	[121.0, 0.0, 2.0, 1], [121.5, 0.0, 2.0, -1], [123.0, 0.0, 2.0, 1], [123.5, 0.0, 2.0, -1],
	[125.0, 0.0, 2.0, -1], [125.5, 0.0, 2.0, 1], [127.5, 0.0, 2.0, -1], [128.5, 0.0, 2.0, 1],
	[157.079, 0.0, 2.0, 1], [157.585, 0.0, 2.0, -1], 
	[162.473, -2.0, 2.0, 1], [162.979, 2.0, 2.0, -1],
	[167.360, 2.5, 2.0, 1], [167.866, -2.5, 2.0, -1],
	[171.743, 0.0, 2.5, 1], [171.911, 0.0, 2.5, -1],
	[177.473, 0.0, 2.2, -1], [177.810, 0.0, 2.2, 1], [178.147, 0.0, 2.2, -1], [178.653, 0.0, 2.2, 1],
	[188.933, 0.0, 3.0, -1], [189.439, 0.0, 3.0, 1],
	[190.9, -2.8, 1.5, 1], [191.5, -2.8, 1.5, -1],
	[193.3, 2.8, 1.5, -1], [193.9, 2.8, 1.5, 1]
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
			else:
				# 在区间外
				pass
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


func add_score(judgement: String):
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
		if abs(diff) <= JUDGE_WINDOW_EXACT_PLUS:
			print("Exact+! 误差:", diff * 1000, "ms")
			add_score("Exact+")
		elif abs(diff) <= JUDGE_WINDOW_EXACT:
			print("Exact! 误差:", diff * 1000, "ms")
			add_score("Exact")
		elif abs(diff) <= JUDGE_WINDOW_NEAR:
			print("Near! 误差:", diff * 1000, "ms")
			add_score("Near")
		
		# 销毁被击中的Note
		best_note_to_hit.queue_free()
		# 更新分数
		score_display.scores = int(scores)
	else:
		# 如果按键时附近没有Note，也可以判定为过早的Break
		print("Break! (Too Early or Missed)")
		add_score("Break")


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

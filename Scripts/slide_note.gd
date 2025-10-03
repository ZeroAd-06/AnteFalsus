# slide_note.gd
class_name SlideNote
extends Node3D

@onready var mesh_instance = $MeshInstance3D

# --- 核心属性 ---
var target_time: float
var direction: int # -1 for left, 1 for right
var width: float
var note_speed: float

# --- 判定状态 ---
var is_in_judge_window: bool = false # 是否处于判定窗口
var initial_cursor_x: float = 0.0      # 进入判定窗口时光标的初始位置
var was_judged: bool = false           # 是否已经被判定过了，防止重复判定

func _ready():
	
	# 给它一个独特的颜色
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 1.0, 0.7)
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat

func _process(delta):
	# 如果已经被判定，就不再移动
	if was_judged:
		return

	# 移动逻辑
	position.z += note_speed * delta

	# 过期自动销毁
	var current_time = get_parent().song_position_sec
	if current_time > target_time + 0.2: # 错过后0.2秒销毁
		if not was_judged:
			print("Slide Missed!")
			# 可以在这里更新UI，显示MISS
		queue_free()

# 当 Note 进入判定窗口时，由 game_main 调用
func enter_judge_window(cursor_x_pos: float):
	if was_judged: return
	is_in_judge_window = true
	initial_cursor_x = cursor_x_pos
	print("Slide note at time %f entered judge window." % target_time)
# 在判定窗口的每一帧，由 game_main 调用
func judge_slide(cursor_x_pos: float) -> bool:
	if was_judged or not is_in_judge_window:
		return false # 返回 false 表示判定未完成
	var delta_x = cursor_x_pos - initial_cursor_x
	var move_direction = sign(delta_x)
	# 检查滑动距离是否足够
	if abs(delta_x) >= get_parent().SLIDE_JUDGE_THRESHOLD:
		if move_direction == direction:
			# 方向正确
			print("Slide: Exact+!")
			get_parent().add_score("Exact+", global_position) # 让 game_main 处理加分
		else:
			# 方向错误
			print("Slide: Break (Wrong Direction)!")
			get_parent().add_score("Break", global_position)
		
		# 标记为已判定并准备消失
		was_judged = true
		# 可以在这里触发一个击中特效
		queue_free() # 立即消失
		return true # 返回 true 表示判定已完成
	return false

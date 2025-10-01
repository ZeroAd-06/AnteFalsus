# sky_cursor.gd
extends Node3D

# 光标的移动范围，晚点我们会从 game_main.gd 获取精确值
var min_x: float = -3.5
var max_x: float = 3.5

# 屏幕宽度，用于计算鼠标位置比例
var viewport_width: float

func _ready():
	# 获取屏幕（视口）的宽度
	viewport_width = get_viewport().get_visible_rect().size.x
	# 捕获鼠标，让它在游戏窗口内自由移动
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# 我们只关心鼠标移动事件
	if event is InputEventMouseMotion:
		# event.relative.x 是鼠标这一帧的横向移动量
		# 我们累加这个移动量，然后限制范围
		var new_x = position.x + (event.relative.x / viewport_width) * (max_x - min_x)
		
		# 使用clamp函数将x坐标限制在min_x和max_x之间
		position.x = clamp(new_x, min_x, max_x)

# 提供一个接口，让外部可以查询光标当前在总范围内的百分比（0.0到1.0）
func get_cursor_position_percent() -> float:
	# 使用inverse_lerp安全地计算百分比
	return inverse_lerp(min_x, max_x, position.x)

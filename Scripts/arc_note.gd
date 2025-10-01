# arc_note.gd
class_name ArcNote

extends Node3D

@onready var mesh_instance = $ArcMesh

# 从 game_main.gd 获取的常量
var note_speed: float

# Arc 自身的属性
var start_time: float
var end_time: float
var key_points: Array # [ [时间点, 左边界, 右边界,插值], ... ]

# 当节点进入场景树时，Godot会自动调用这个函数
# 这是执行初始化的完美时机
func _ready():
	generate_mesh()

# 一个帮助函数，把歌曲时间转换为相对于 Arc 起始点的 Z 坐标
func time_to_z(time: float) -> float:
	return -(time - start_time) * note_speed

# 核心！生成网格的函数
func generate_mesh():
	# 增加一个安全检查，如果 mesh_instance 因为某些原因还是不存在，就提前退出
	if not is_instance_valid(mesh_instance):
		print("ArcMesh node not found inside ArcNote scene!")
		return

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(key_points.size() - 1):
		var p1 = key_points[i]
		var p2 = key_points[i + 1]

		var p1_time = p1[0]
		var p1_left_x = p1[1]
		var p1_right_x = p1[2]

		var p2_time = p2[0]
		var p2_left_x = p2[1]
		var p2_right_x = p2[2]

		var v1 = Vector3(p1_left_x, 0.0, time_to_z(p1_time))
		var v2 = Vector3(p1_right_x, 0.0, time_to_z(p1_time))
		var v3 = Vector3(p2_left_x, 0.0, time_to_z(p2_time))
		var v4 = Vector3(p2_right_x, 0.0, time_to_z(p2_time))

		surface_tool.add_vertex(v1)
		surface_tool.add_vertex(v2)
		surface_tool.add_vertex(v3)
		
		surface_tool.add_vertex(v3)
		surface_tool.add_vertex(v2)
		surface_tool.add_vertex(v4)

	surface_tool.generate_normals()
	
	var array_mesh = surface_tool.commit()
	
	mesh_instance.mesh = array_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 1.0, 0.7)
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED 

# 根据歌曲时间，计算出当前光标应该在的左右边界
func get_boundaries_at_time(time: float) -> Vector2:
	# 如果时间超出了 Arc 的范围，返回一个无效值
	if time < start_time or time > end_time:
		return Vector2.ZERO # 或者其他表示无效的标记
	# 找到当前时间所在的区间
	for i in range(key_points.size() - 1):
		var p1 = key_points[i]
		var p2 = key_points[i+1]
		if time >= p1[0] and time <= p2[0]:
			# 找到了！p1 和 p2 就是我们要插值的两个点
			var t = inverse_lerp(p1[0], p2[0], time) # 计算插值因子 (0-1)
			
			var current_left_x = lerp(p1[1], p2[1], t)
			var current_right_x = lerp(p1[2], p2[2], t)
			
			return Vector2(current_left_x, current_right_x)
	
	return Vector2.ZERO # 理论上不会到这里

func _process(delta):
	position.z += note_speed * delta
	print(position.z)

	var current_time = get_parent().song_position_sec
	
	if current_time > end_time + 2.0:
		queue_free()

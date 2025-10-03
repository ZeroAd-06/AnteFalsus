# note.gd
class_name Note
extends Node3D

# 这个Note应该被击中的时间（秒）
var target_time: float = 0.0
# 这个Note所在的轨道
var track: int = 1

# Note的父节点(Game.gd)会设置这些值
# 我们从 Game.gd 引用流速和起始位置
var note_spawn_time # 会被Game.gd传入
var note_spawn_z # 会被Game.gd传入

func _process(delta):
	# 从单例或者父节点获取当前歌曲时间
	# 为了简单，我们先假设能直接拿到
	var current_time = get_parent().song_position_sec

	# 计算Note当前应该在的Z轴位置
	# 核心公式：位置 = (剩余时间 / 总时间) * 总距离
	var time_to_hit = target_time - current_time
	var new_z = note_spawn_z * (time_to_hit / (target_time - note_spawn_time))
	
	# 更新自己的位置
	position.z = new_z
	
	# 如果Note已经飘过判定线太远，就销毁自己
	if new_z > 5.0: # 5.0 是一个容错值
		print("Break! (Missed)")
		get_parent().add_score("Break")
		queue_free()

func get_is_note():
	return true

# judgement_display.gd
extends Label3D

# 动画持续时间（秒）
const ANIM_DURATION = 0.7
# 上浮的高度（游戏单位）
const FLOAT_HEIGHT = 0.5

# 这个函数将由外部调用，用来启动整个效果
func show_judgement(judgement_text: String, judgement_color: Color):
	# 设置显示的文本和颜色
	self.text = judgement_text
	self.modulate = judgement_color # Modulate 可以整体调整颜色和透明度

	# 创建一个 Tween (补间动画器) 来处理动画，这比在 _process 中手动计算更高效简洁
	var tween = create_tween()

	# 1. 创建上浮动画
	# tween_property(对象, "属性", 结束值, 持续时间)
	# "position:y" 表示只修改 position 向量的 y 分量
	tween.tween_property(self, "position:y", self.position.y + FLOAT_HEIGHT, ANIM_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	# 2. 创建淡出动画 (并行执行)
	# "modulate:a" 表示修改 modulate 颜色的 alpha (透明度) 分量
	# 我们让它在动画的后半段开始淡出
	tween.parallel().tween_property(self, "modulate:a", 0.0, ANIM_DURATION * 0.5).set_delay(ANIM_DURATION * 0.5)

	# 3. 动画结束后，自动销毁节点
	# 将 tween 的 finished 信号连接到节点自己的 queue_free 方法
	tween.finished.connect(queue_free)

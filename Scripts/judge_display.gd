extends Label3D


func _ready():
	pass


func _process(delta):
	if(self.scale.x > 0.5):
		self.scale.x -= delta * 5

func show_judge(text):
	self.text=text
	self.scale.x = 5

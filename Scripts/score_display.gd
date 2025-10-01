extends Label3D

var scores = 0

func _ready():
	pass


func _process(_delta):
	var now_scores = int(self.text)
	var new_scores = 0.9 * now_scores + 0.1 * scores
	if abs(new_scores - scores) < 10000 :
		new_scores = scores
	self.text = ''
	for i in range(9-str(int(new_scores)).length()) :
		self.text+='0'
	self.text+=str(int(new_scores))

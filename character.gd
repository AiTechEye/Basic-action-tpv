extends KinematicBody

onready var anim = $testman/AnimationPlayer
var cur_anim = ""

func animation(a):
	if a != cur_anim:
		if a == "stand":
			anim.play(a)
		if a == "climb":
			anim.play(a)
			anim.get_animation(a).loop = true
		elif a == "walk":
			anim.play(a,0.1)
			anim.get_animation(a).loop = true
		elif a == "run":
			anim.play("walk",0.1,2)
			anim.get_animation("walk").loop = true
		elif a == "jump":
			anim.play(a,0.2,1.5)
	cur_anim = a

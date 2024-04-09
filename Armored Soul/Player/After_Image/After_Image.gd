extends Sprite

func _ready():
	$Tween.interpolate_property(self, "modulate", Color(1, 0, 0, 1), Color(0.55, 0, 0, 0), 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_Tween_tween_completed(object, key):
	queue_free()
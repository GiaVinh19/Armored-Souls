extends Node

func _ready():
	$Control/VBoxContainer/Start_Button.grab_focus()

# warning-ignore:unused_argument
func _physics_process(delta):
	if $Control/VBoxContainer/Start_Button.is_hovered() == true:
		$Control/VBoxContainer/Start_Button.grab_focus()
	if $Control/VBoxContainer/Exit_Button.is_hovered() == true:
		$Control/VBoxContainer/Exit_Button.grab_focus()

func _on_Start_Button_pressed():
# warning-ignore:return_value_discarded
	yield(get_tree().create_timer(0.2),"timeout")
	get_tree().change_scene("res://Map/World_One.tscn")

func _on_Exit_Button_pressed():
	get_tree().quit()

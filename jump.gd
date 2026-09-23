extends TouchScreenButton


func _on_pressed() -> void :
	Input.action_press("jump")


func _on_released() -> void :
	Input.action_release("jump")

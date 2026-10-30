extends Button

func _ready() -> void:
	focus_entered.connect(_highlight_button)
	mouse_entered.connect(_highlight_button)
	
	focus_exited.connect(_unhighlight_button)
	mouse_exited.connect(_unhighlight_button)
	
func _highlight_button():
	$selectrec.visible = true

func _unhighlight_button():
	$selectrec.visible = false

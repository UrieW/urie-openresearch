extends Control

@onready var scroll_container: ScrollContainer = $scrolls

var current_page: int = 0
const TOTAL_PAGES: int = 3
const PAGE_WIDTH: int = 640 # 600px panel width + 40px HBox separation

func _ready() -> void:
	# Jump to a specific pixel position
	scroll_container.scroll_horizontal = 0
	grab_focus()

func smooth_scroll_to(target_x: int, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(scroll_container, "scroll_horizontal", target_x, duration)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_disclaimer_interact"):
		current_page += 1
		if current_page < TOTAL_PAGES:
			smooth_scroll_to(current_page * PAGE_WIDTH)
		else:
			smooth_fade_to_and_kill(0)
		get_viewport().set_input_as_handled()

func smooth_fade_to_and_kill(op: int, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", op, duration)
	tween.finished.connect(queue_free)

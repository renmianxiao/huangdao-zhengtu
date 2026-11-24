extends Control
const PaperStyle=preload("res://code/scripts/ui/global_theme.gd")
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PaperStyle.PAPER)


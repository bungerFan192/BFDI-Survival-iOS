
extends Label

@export var base_offset: = Vector2(-10, -54)
@export var rise_px: = 34.0
@export var rise_time: = 0.55
@export var hold_time: = 4.05
@export var fade_time: = 0.4
@export var stack_step: = 16.0

func play(text_in: String, stack_index: int = 0) -> void :
	text = text_in
	add_to_group("chat_bubble")


	position = base_offset + Vector2(0, - stack_index * stack_step)
	modulate.a = 1.0
	scale = Vector2.ONE


	var tw: = create_tween()
	tw.set_parallel(true)

	tw.tween_property(self, "position:y", position.y - rise_px, rise_time)\
	.set_trans(Tween.TRANS_ELASTIC)\
	.set_ease(Tween.EASE_OUT)

	tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12)\
	.set_trans(Tween.TRANS_BACK)\
	.set_ease(Tween.EASE_OUT)

	tw.chain().tween_property(self, "scale", Vector2.ONE, 0.1)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_OUT)


	tw.chain().tween_interval(hold_time)
	tw.chain().tween_property(self, "modulate:a", 0.0, fade_time)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_IN)

	tw.chain().tween_callback(queue_free)

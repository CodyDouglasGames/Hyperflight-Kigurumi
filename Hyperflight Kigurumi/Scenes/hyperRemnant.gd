extends Node2D
var tween

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	await get_tree().create_timer(0.5).timeout
	queue_free()
	pass

func _on_ready():
	tween = get_tree().create_tween()
	tween.tween_property($".","modulate:a",0,0.5)
	

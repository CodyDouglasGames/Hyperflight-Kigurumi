extends Node2D

var hyperRemnant = preload("res://Scenes/hyperRemnant.tscn")
var instance
var child

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_hyper_remnant_timeout():
	instance = hyperRemnant.instantiate()
	instance.position = $Player.position
	instance.rotation = $Player.rotation
	child = instance.get_children()[0]
	child.flip_v = $Player/AnimatedSprite2D.flip_v
	add_child(instance)
	pass # Replace with function body.
	randi()

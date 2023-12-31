class_name FollowNode extends Node3D

@export var LERP_WEIGHT : int
@export var following_node : Node

func _process(delta):
	follow(delta)

func follow(delta):
	transform.origin = lerp(transform.origin, following_node.transform.origin, delta*LERP_WEIGHT)

func setNodeToFollow(node):
	following_node = node

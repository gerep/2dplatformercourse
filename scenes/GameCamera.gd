extends Camera2D

var targetPosition = Vector2.ZERO

export(Color, RGB) var backgroundColor

func _ready():
	VisualServer.set_default_clear_color(backgroundColor)

func _process(delta):
	acquire_target_position()

	global_position = lerp(targetPosition, global_position, pow(2, -15 * delta))

func acquire_target_position():
	var acquired = get_target_position_from_group("player")
	if !acquired:
		get_target_position_from_group("player_death")

func get_target_position_from_group(groupName):
	var nodes = get_tree().get_nodes_in_group(groupName)
	if nodes.size() > 0:
		var node = nodes[0]
		targetPosition = node.global_position
		return true

	return false

extends Button

export(bool) var disableHoverAnimation

func _ready():
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")
	connect("pressed", self, "on_pressed")

func _process(_delta):
	# The button size changes during hover animations. This line calculates it's
	# center on every frame.
	rect_pivot_offset = rect_min_size / 2

func on_mouse_entered():
	if !disableHoverAnimation:
		$HoverAnimationPlayer.play("hover")

func on_mouse_exited():
	if !disableHoverAnimation:
		$HoverAnimationPlayer.play_backwards("hover")

func on_pressed():
	$AudioStreamPlayer.play()
	$ClickAnimationPlayer.play_backwards("click")

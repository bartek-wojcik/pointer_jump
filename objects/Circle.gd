extends Area2D

onready var orbit_position = $Pivot/OrbitPosition
onready var move_tween = $MoveTween

enum MODES { STATIC, LIMITED }

var _radius = 80
var rotation_speed = PI
var mode = MODES.STATIC
var move_range = 0
var move_speed = 2.0
var num_orbits = 3
var orbits_left = 0
var orbit_start = null
var pointer = null

func init(_position, level=1):
	var _mode = settings.rand_weighted([5, level-1])
	set_mode(_mode)
	position = _position
	var small_chance = level / 6.0
	if randf() < small_chance:
		_radius = max(40, _radius - level * 5)
	var move_chance = level / 6.0
	if randf() < move_chance:
		move_range = max(50, 270 * move_chance - 2 * _radius) * pow(-1, randi() % 2)
		move_speed = max(ceil(level/5) * 0.25, 1)
	$Sprite.material = $Sprite.material.duplicate()
	$SpriteEffect.material = $Sprite.material
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.radius = _radius
	var img_size = $Sprite.texture.get_size().x / 2
	$Sprite.scale = Vector2(1, 1) * _radius / img_size
	orbit_position.position.x = _radius + 25
	rotation_speed *= pow(-1, randi() % 2)
	set_tween()

func set_mode(_mode):
	mode = _mode
	var color
	match mode:
		MODES.STATIC:
			$Label.hide()
			color = settings.theme["circle_static"]
		MODES.LIMITED:
			orbits_left = num_orbits
			$Label.text = str(orbits_left)
			$Label.show()
			color = settings.theme["circle_limited"]
	$Sprite.material.set_shader_param("color", color)
			

func _process(delta):
	$Pivot.rotation += rotation_speed * delta
	if mode == MODES.LIMITED and pointer:
		check_orbits()
		update()
		
func check_orbits():
	if abs($Pivot.rotation - orbit_start) > 2 * PI:
		orbits_left -= 1
		if settings.enable_sound:
			$Beep.play()
		$Label.text = str(orbits_left)
		if orbits_left <= 0:
			pointer.die()
			pointer = null
			implode()
		orbit_start = $Pivot.rotation

func implode():
	$AnimationPlayer.play("implode")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
	
func capture(target):
	pointer = target
	$AnimationPlayer.play("capture")
	$Pivot.rotation = (pointer.position - position).angle()
	orbit_start = $Pivot.rotation
	
func _draw():
	if pointer:
		var r = ((_radius - 50) / num_orbits) * (1 + num_orbits - orbits_left)
		draw_circle_arc_poly(Vector2.ZERO, r, orbit_start + PI/2,
							$Pivot.rotation + PI/2, settings.theme["circle_fill"])
	
func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	points_arc.push_back(center)
	var colors = PoolColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI/2
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_polygon(points_arc, colors)
	
func set_tween():
	if move_range == 0:
		return
	move_range  *= -1
	move_tween.interpolate_property(self, "position:x",
				position.x, position.x + move_range,
				move_speed, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	move_tween.start()

func _on_MoveTween_tween_completed(object, key):
	set_tween()

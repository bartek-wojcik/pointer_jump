extends Node

var play_games_services = null
var L_ID = "CgkI3cip4vwDEAIQAA"
var Circle = preload("res://objects/Circle.tscn")
var Pointer = preload("res://objects/Pointer.tscn")

var player
var score = -1 setget set_score
var highscore = 0
var level = 0 

func _ready():
	randomize()
	load_score()
	$HUD.hide()
	
func new_game():
	self.score = -1
	level = 0
	$HUD.update_score(score)
	$Camera2D.position = $StartPosition.position
	player = Pointer.instance()
	player.position = $StartPosition.position
	player.connect("captured", self, "_on_Pointer_captured")
	player.connect("died", self, "_on_Pointer_died")
	spawn_circle($StartPosition.position)
	add_child(player)	
	$HUD.show()
	$HUD.show_message("Go!")
	if settings.enable_music:
		$Music.volume_db = 0
		$Music.play()
	
func spawn_circle(_position=null):
	var c = Circle.instance()
	if !_position:
		var x = rand_range(-150, 150)
		var y = rand_range(-500, -400)
		_position = player.target.position + Vector2(x, y)
	add_child(c)
	c.init(_position, level)
	
func _on_Pointer_captured(object):
	$Camera2D.position = object.position
	object.capture(player)
	call_deferred("spawn_circle")
	self.score += 1
	$HUD.update_score(score)
	
func set_score(value):
	score = value
	$HUD.update_score(score)
	if score > 0 && score % settings.circles_per_level == 0:
		level += 1
	
func _on_Pointer_died():
	if score > highscore:
		highscore = score
		update_highscore_title()
		save_score()
	get_tree().call_group("circles", "implode")
	$Screens.game_over(score, highscore)
	$HUD.hide()
	if settings.enable_music:
		$Music.stop()

func update_highscore_title():
	$Screens/TitleScreen/MarginContainer/VBoxContainer/Best.text = "Best: %s" % highscore

func load_score():
	var f = File.new()
	if f.file_exists(settings.score_file):
		f.open(settings.score_file, File.READ)
		highscore = f.get_var()
		f.close()
		update_highscore_title()
		
func save_score():
	GooglePlay.submit_score(highscore)
	var f = File.new()
	f.open(settings.score_file, File.WRITE)
	f.store_var(highscore)
	f.close()

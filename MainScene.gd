extends Node

var play_games_services
var leaderboard_id = "CgkI3cip4vwDEAIQAA"
var Circle = preload("res://objects/Circle.tscn")
var Pointer = preload("res://objects/Pointer.tscn")

var player
var score = -1 setget set_score
var highscore = 0
var level = 0 

func initialize_play_services():
	if Engine.has_singleton("GodotPlayGamesServices"):
		play_games_services = Engine.get_singleton("GodotPlayGamesServices")
		var show_popups := true 
		play_games_services.init(show_popups)
		play_games_services.connect("_on_leaderboard_score_submitted", self, "_on_leaderboard_score_submitted") # leaderboard_id: String
		play_games_services.connect("_on_leaderboard_score_submitting_failed", self, "_on_leaderboard_score_submitting_failed") # leaderboard_id: String

func _on_leaderboard_score_submitted(leaderboard_id: String):
	print('success')

func _on_leaderboard_score_submitting_failed(leaderboard_id: String):
	print(leaderboard_id)

func _ready():
	initialize_play_services()
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
	add_child(player)
	player.connect("captured", self, "_on_Pointer_captured")
	player.connect("died", self, "_on_Pointer_died")
	spawn_circle($StartPosition.position)
	$HUD.show()
	$HUD.show_message("Go!")
	if settings.enable_music:
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
	if play_games_services:
		play_games_services.submitLeaderBoardScore(leaderboard_id, highscore)
	var f = File.new()
	f.open(settings.score_file, File.WRITE)
	f.store_var(highscore)
	f.close()

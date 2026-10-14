extends SceneTree
func _initialize():call_deferred("run_check")
func run_check():
	var game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	for i in 5:await physics_frame
	game.enter_ragdoll()
	for i in 3:await physics_frame
	var disabled_during=game.actor.get_child(0).disabled
	game.restart()
	for i in 60:await physics_frame
	print("RESTART_RAGDOLL ",JSON.stringify({"disabled_during":disabled_during,"disabled_after_restart":game.actor.get_child(0).disabled,"feet_y":game.feet().y,"floor":595,"ragdoll":game.ragdoll_active}))
	quit(0)

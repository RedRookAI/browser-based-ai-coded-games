extends SceneTree
func _initialize():call_deferred("run_checks")
func run_checks():
	var game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	for i in 5:await physics_frame
	game.set_physics_process(false);game.creatures.restart_lineup(["pancake"])
	var target=game.creatures.bodies[0];target.p=Vector2(760,480);target.v=Vector2(0,-480)
	game.aim=target.p;game.update_visual();game.fire_hook()
	var closest=INF
	for i in 24:
		var previous:Vector2=game.hook.p
		target.p+=target.v/60
		game.update_hook(1.0/60)
		if game.hook.state=="flying":
			var segment:Vector2=game.hook.p-previous
			var t=clampf((target.p-previous).dot(segment)/maxf(segment.length_squared(),0.001),0,1)
			closest=minf(closest,target.p.distance_to(previous+segment*t))
		if game.hook.state=="attached":break
	print("MOVING_HOOK ",JSON.stringify({"target_id":game.hook.target,"state":game.hook.state,"closest_observed_segment_distance":closest,"target_radius":target.r,"target_position":target.p,"anchor":game.hook.anchor}))
	quit(0)

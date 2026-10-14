extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://main.tscn").instantiate();root.add_child(game)
	for i in 5:await physics_frame
	game.set_physics_process(false);game.creatures.restart_lineup(["pancake"])
	var target=game.creatures.bodies[0];target.p=Vector2(760,480);target.v=Vector2(0,-480)
	game.aim=target.p;game.update_visual();game.fire_hook()
	var attached_to_evading_target=false;var closest=INF
	for i in 60:
		var previous:Vector2=game.hook.p;target.p+=target.v/60;game.update_hook(1.0/60)
		var segment:Vector2=game.hook.p-previous;var t=clampf((target.p-previous).dot(segment)/maxf(segment.length_squared(),0.001),0,1)
		closest=minf(closest,target.p.distance_to(previous+segment*t))
		if game.hook.target==str(target.id)&&game.hook.state=="attached":attached_to_evading_target=true;break
	var evasion_pass=!attached_to_evading_target&&closest>target.r+2
	game.restart();game.set_physics_process(false);game.creatures.restart_lineup(["pancake"])
	target=game.creatures.bodies[0];target.p=Vector2(760,480);target.v=Vector2.ZERO;game.aim=target.p;game.update_visual();game.fire_hook()
	for i in 60:
		game.update_hook(1.0/60)
		if game.hook.state=="attached":break
	var stationary_pass=game.hook.state=="attached"&&game.hook.target==str(target.id)
	game.release_hook();game.creatures.restart_lineup(["popcorn"]);game.aim=game.creatures.popcorn_center();game.update_visual();game.fire_hook()
	for i in 60:
		game.update_hook(1.0/60)
		if game.hook.state=="attached":break
	var colony_pass=game.hook.state=="attached"&&game.hook.target=="popcorn"&&game.creatures.colony.mode=="towed"
	print(JSON.stringify({"evading_target_not_hit":evasion_pass,"closest_flight_distance":closest,"stationary_target_hit":stationary_pass,"colony_hit":colony_pass}))
	quit(0 if evasion_pass&&stationary_pass&&colony_pass else 1)

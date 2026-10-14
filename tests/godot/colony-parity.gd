extends SceneTree
var results=[]
func _initialize():call_deferred("run_checks")
func run_checks():
	var foods=load("res://creatures.gd").new()
	root.add_child(foods)
	var platforms:Array[Rect2]=[Rect2(420,327.5,160,18)]
	foods.configure(Rect2(18,60,964,535),platforms)
	foods.restart_lineup(["popcorn"])
	for i in 60:foods.update_popcorn(1.0/60)
	results.append({"name":"reset count","count":foods.grains.size(),"connected":foods.popcorn_components()[0].size()})
	var started=foods.start_stretch(foods.surface("left",465))
	for i in 300:foods.update_popcorn(1.0/60)
	results.append({"name":"wall arrival","started":started,"mode":foods.colony.mode,"destination":foods.colony.anchor.kind,"near_wall":foods.grains.filter(func(g):return g.p.x<110&&g.p.y<530).size()})
	foods.restart_lineup(["popcorn"]);foods.grains.resize(9)
	for i in 20:foods.update_popcorn(1.0/60)
	started=foods.start_stretch(foods.surface("left",395))
	var maximum=0.0
	var ratio=foods.colony.route.capacity/foods.colony.route.length
	for i in 240:
		foods.update_popcorn(1.0/60)
		if foods.colony.mode=="bridge":maximum=maxf(maximum,foods.colony.route.progress)
		if foods.colony.mode=="loose":break
	results.append({"name":"short group failure","started":started,"capacity_ratio":ratio,"max_progress":maximum,"mode":foods.colony.mode,"reason":foods.colony.reason})
	foods.restart_lineup(["popcorn"]);foods.pull_target("popcorn",Vector2.ZERO,Vector2(0,-60),0)
	results.append({"name":"tow","mode":foods.colony.mode})
	foods.release_target("popcorn")
	results.append({"name":"release","mode":foods.colony.mode,"timer":foods.colony.release})
	print("COLONY_AUDIT ",JSON.stringify(results))
	quit(0)

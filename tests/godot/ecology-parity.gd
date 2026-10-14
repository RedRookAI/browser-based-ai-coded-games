extends SceneTree
func _initialize():call_deferred("run_checks")
func run_checks():
	var foods=load("res://creatures.gd").new()
	root.add_child(foods)
	var platforms:Array[Rect2]=[Rect2(420,327.5,160,18)]
	foods.configure(Rect2(18,60,964,535),platforms)
	var choices=[["pancake","popcorn"],["cake","popcorn"],["sushi","popcorn"],["cake","pancake"],["sushi","cake"],["sushi","pancake"],["cake","popcorn","sushi"],["cake","popcorn","pancake"]]
	var records=[]
	for lineup in choices:
		foods.restart_lineup(lineup)
		for i in 180:foods.step(1.0/60,Rect2(),Vector2.ZERO)
		var finite=true
		for b in foods.bodies+foods.grains:finite=finite&&b.p.is_finite()&&b.v.is_finite()
		records.append({"lineup":lineup,"finite":finite,"ants":foods.grains.size()})
	foods.restart_lineup(["cake","popcorn"])
	var cake=foods.cake()
	cake.p=foods.grains[0].p;cake.cooldown=0
	foods.food_interactions(1.0/60)
	records.append({"case":"cake consumes popcorn","remaining":foods.grains.size()})
	foods.restart_lineup(["cake","pancake"])
	cake=foods.cake()
	var ray=foods.bodies.filter(func(b):return b.kind=="pancake")[0]
	ray.p=cake.p-Vector2(24,3);ray.v=Vector2.RIGHT;ray.cooldown=0;ray.pause=0
	foods.food_interactions(1.0/60)
	records.append({"case":"pancake bites cake","cake_chunks":cake.chunks})
	for i in 3:
		ray.hunting=true;ray.hurt=0
		foods.pancake_crash(ray,{"impact":120.0,"normal":Vector2.LEFT})
	records.append({"case":"pancake dies after 3 impacts","health":ray.health,"dead":ray.dead,"gravity":ray.gravity})
	foods.restart_lineup(["sushi"])
	var roll=foods.bodies[0]
	foods.pull_target(str(roll.id),Vector2.ZERO,Vector2.ZERO,200)
	foods.update_sushi(0.2)
	foods.pull_target(str(roll.id),Vector2.ZERO,Vector2.ZERO,0)
	foods.update_sushi(0.5)
	records.append({"case":"slack tension preserves bonds","active":foods.bonds.filter(func(b):return b.active).size()})
	foods.pull_target(str(roll.id),Vector2.ZERO,Vector2.ZERO,200)
	foods.update_sushi(0.5)
	records.append({"case":"real tension breaks bond","active":foods.bonds.filter(func(b):return b.active).size()})
	print("ECOLOGY_AUDIT ",JSON.stringify(records));quit(0)

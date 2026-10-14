extends SceneTree
var checks=[]
var failures=[]
func _initialize()->void:call_deferred("run")
func check(label:String,condition:bool,detail:Variant=null)->void:
	checks.append({"name":label,"pass":condition,"detail":detail})
	if !condition:failures.append(label)
func run()->void:
	var c=load("res://creatures.gd").new();root.add_child(c)
	var platforms:Array[Rect2]=[Rect2(420,327.5,160,18)]
	c.configure(Rect2(18,60,964,535),platforms)
	for destination in [c.surface("floor",340),c.surface("ceiling",145),c.surface("platform",455)]:
		c.restart_lineup(["popcorn"])
		for i in 18:c.step(1.0/60,Rect2(),Vector2.ZERO)
		check("start "+destination.kind,c.start_stretch(destination))
		var route_length=c.colony.route.length;var arrived=false;var actual=0
		for i in 600:
			c.step(1.0/60,Rect2(),Vector2.ZERO)
			if c.colony.mode=="pile"&&c.colony.anchor.kind==destination.kind&&c.colony.anchor.p.distance_to(destination.p)<10:
				for g in c.grains:
					if g.p.distance_to(destination.p)<100:actual+=1
				arrived=true;break
		check("physical arrival "+destination.kind,arrived&&actual>25,{"arrived":arrived,"near_destination":actual,"length":route_length,"colony":c.colony})
		var penetration=false
		for g in c.grains:
			if platforms[0].has_point(g.p):penetration=true
		check("no platform penetration "+destination.kind,!penetration)
	c.restart_lineup(["popcorn"])
	for g in c.grains.slice(5):g.p.x+=600
	check("separated population not counted",c.popcorn_components()[0].size()<45)
	c.start_stretch(c.surface("ceiling",800))
	check("capacity only connected group",c.colony.route.members.size()<45&&c.colony.route.capacity<c.popcorn_reach(c.grains))
	c.restart_lineup(["popcorn"])
	for i in 18:c.step(1.0/60,Rect2(),Vector2.ZERO)
	c.start_stretch(c.surface("left",465));var old=c.colony.route.capacity;c.grains.pop_front()
	for i in 2:c.step(1.0/60,Rect2(),Vector2.ZERO)
	check("losing one preserves sufficient route",c.colony.mode=="bridge"&&c.colony.route.capacity<old&&c.colony.route.capacity>c.colony.route.length)
	for i in 100:c.step(1.0/60,Rect2(),Vector2.ZERO)
	c.grains.resize(3);c.step(1.0/60,Rect2(),Vector2.ZERO)
	check("loss mid-stretch collapses",c.colony.mode=="loose")
	c.restart_lineup(["popcorn"]);c.grains.resize(1)
	check("single ant cannot form stretch",!c.start_stretch(c.surface("left",465)))
	c.grains.clear();c.step(1.0/60,Rect2(),Vector2.ZERO)
	check("empty colony safe",c.colony.mode=="pile"&&c.colony.route.is_empty())
	c.restart_lineup(["popcorn"]);c.pull_target("popcorn",Vector2(0,-30),Vector2(60,-50),100);c.release_target("popcorn")
	check("no instant stretch after release",!c.start_stretch(c.surface("ceiling",145)))
	for i in 100:c.step(1.0/60,Rect2(),Vector2.ZERO)
	check("released ants regroup",c.colony.mode=="pile"&&c.grains.size()==45)
	c.restart_lineup(["sushi"])
	var rolls=c.bodies;var original_links=c.bonds.size();c.bonds[2].active=false;c.bonds[2].reconnect=0
	c.update_sushi(1.0/60)
	check("free sushi ends reconnect",c.sushi_groups().size()==1&&c.bonds.size()>original_links)
	var no_branch=true
	for b in rolls:
		if c.degree(b.id)>2:no_branch=false
	check("sushi no branches or loop",no_branch&&c.bonds.filter(func(b):return b.active).size()==6)
	c.restart_lineup(["sushi"])
	var reached_ceiling=false
	for i in 1500:
		c.step(1.0/60,Rect2(),Vector2.ZERO)
		for roll in c.bodies:
			if roll.p.y<100:reached_ceiling=true
	check("sushi physically climbs room surfaces",reached_ceiling)
	c.restart_lineup(["cake","popcorn"])
	var spider=c.cake();spider.distance=326.0;spider.p=c.perimeter(0,326.0,24).p
	for g in c.grains:g.p=Vector2(500+(g.id%7-3)*10,588-floori(g.id/7.0)*8)
	var point=c.perimeter(0,326.0,24)
	check("cake can plan bounded ballistic jump",c.try_cake_jump(spider,c.nearest_food(spider.p),point.n))
	var jumped=false
	for i in 90:
		c.step(1.0/60,Rect2(),Vector2.ZERO)
		if spider.p.y>480:jumped=true
	check("cake jump moves to another surface",jumped&&spider.p.is_finite(),spider.p)
	print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)

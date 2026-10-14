extends SceneTree
var checks=[]
var failures=[]
func _initialize()->void:call_deferred("run")
func check(label:String,condition:bool,detail:Variant=null)->void:
	checks.append({"name":label,"pass":condition,"detail":detail})
	if !condition:failures.append(label)
func tick(frames:int)->void:
	for i in frames:await physics_frame
func run()->void:
	var game=load("res://main.tscn").instantiate();root.add_child(game);await tick(3)
	game.creatures.restart_lineup([])
	check("spawn grounded",game.feet().distance_to(Vector2(380,595))<2&&game.grounded)
	var start=game.feet().x;Input.action_press("move_right");await tick(60);Input.action_release("move_right")
	check("input moves right",game.feet().x>start+100,game.feet().x)
	await tick(30);Input.action_press("jump");game.jump();await tick(12);Input.action_release("jump")
	check("jump rises",game.feet().y<560,game.feet().y)
	await tick(80);check("jump lands",game.grounded)
	game.restart();await tick(3);game.aim=Vector2(100,90);game.fire_hook();await tick(45)
	check("wall hook attaches",game.hook.state=="attached",game.hook.state)
	game.release_hook();check("hook releases",game.hook.state=="idle")
	game.restart();game.actor.velocity=Vector2(420,-90);game.enter_ragdoll();await tick(40)
	check("ragdoll articulated motion",game.ragdoll_active&&game.loose_nodes.size()==16&&game.loose_nodes.head.p.distance_to(game.loose_nodes.hips.p)>10)
	game.recover();await tick(3);check("ragdoll recovers",!game.ragdoll_active)
	game.restart();check("restart resets hook and motion",game.feet()==Vector2(380,595)&&game.actor.velocity==Vector2.ZERO&&game.hook.state=="idle")
	game.enter_ragdoll();await tick(3);game.restart();await tick(60)
	check("restart from ragdoll restores collider",!game.actor.get_child(0).disabled&&!game.ragdoll_active&&game.feet().y<=595.1,game.feet())
	game.set_physics_process(false)
	var c=game.creatures
	c.restart_lineup(["sushi"]);c.bodies[0].p=Vector2(390,550);c.bodies[0].v=Vector2(-80,0)
	c.step(1.0/60,Rect2(366,450,28,145),Vector2.ZERO)
	check("two-way creature contact response",c.player_contact_response().displacement.length()>0)
	c.step(1.0/60,Rect2(),Vector2.ZERO)
	check("no upright phantom during ragdoll",c.player_contact_response().displacement==Vector2.ZERO)
	c.configure(Rect2(18,60,964,535),game.world.platforms)
	var lineups=[["pancake","popcorn"],["cake","popcorn"],["sushi","popcorn"],["cake","pancake"],["sushi","cake"],["sushi","pancake"],["cake","popcorn","sushi"],["cake","popcorn","pancake"]]
	for lineup in lineups:
		c.restart_lineup(lineup)
		for i in 300:c.step(1.0/60,Rect2(366,450,28,145),Vector2.ZERO)
		var finite=true
		for b in c.bodies+c.grains:
			if !b.p.is_finite()||!b.v.is_finite():finite=false
		check("finite ecology "+str(lineup),finite)
	c.restart_lineup(["popcorn"])
	check("45 live ants",c.grains.size()==45)
	for i in 18:c.step(1.0/60,Rect2(366,450,28,145),Vector2.ZERO)
	check("45 connected ants",c.popcorn_components()[0].size()==45)
	check("wall stretch begins",c.start_stretch(c.surface("left",465)))
	for i in 360:c.step(1.0/60,Rect2(366,450,28,145),Vector2.ZERO)
	check("wall arrival",c.colony.mode=="pile"&&c.colony.anchor.kind=="left",c.colony)
	c.restart_lineup(["popcorn"]);c.grains.resize(9)
	for i in 18:c.step(1.0/60,Rect2(366,450,28,145),Vector2.ZERO)
	c.start_stretch(c.surface("left",395))
	check("undersized capacity",c.colony.route.capacity<c.colony.route.length)
	var collapsed=false
	for i in 240:
		c.step(1.0/60,Rect2(366,450,28,145),Vector2.ZERO)
		if c.colony.mode=="loose":collapsed=true;break
	check("undersized attempt collapses",collapsed)
	c.restart_lineup(["popcorn"]);c.pull_target("popcorn",Vector2(0,-10),Vector2(20,-80),150)
	check("grapple tows colony",c.colony.mode=="towed")
	c.release_target("popcorn");check("release loose",c.colony.mode=="loose"&&c.colony.release>0)
	c.restart_lineup(["sushi"]);var roll=c.bodies[0];c.pull_target(str(roll.id),Vector2.ZERO,Vector2.ZERO,150)
	for i in 35:c.update_sushi(1.0/60)
	check("sushi tension splits",c.sushi_groups().size()>1)
	c.restart_lineup(["sushi"]);roll=c.bodies[0];c.pull_target(str(roll.id),Vector2.ZERO,Vector2.ZERO,150);c.pull_target(str(roll.id),Vector2.ZERO,Vector2.ZERO,0)
	for i in 35:c.update_sushi(1.0/60)
	check("slack keeps sushi intact",c.sushi_groups().size()==1)
	c.restart_lineup(["cake","popcorn"]);var cake=c.cake();cake.crawling=false;c.grains[0].p=cake.p;c.food_interactions(1.0/60)
	check("cake eats real member",c.grains.size()==44)
	c.restart_lineup(["cake","pancake"]);cake=c.cake();var ray=c.bodies[1];ray.p=cake.p-Vector2(24,3);ray.v=Vector2.RIGHT;c.food_interactions(1.0/60)
	check("pancake bites cake",cake.chunks==5)
	for i in 3:ray.hunting=true;ray.hurt=0;c.pancake_crash(ray,{"impact":150.0,"normal":Vector2.UP})
	check("three crashes limp pancake",ray.health==0&&ray.dead&&ray.gravity==850)
	c.restart_lineup(["cake"]);cake=c.cake();cake.p=Vector2(480,300);c.pull_target(str(cake.id),Vector2(0,100),Vector2.ZERO,150)
	check("cake pull blocked by platform",cake.p.y<=303.51,cake.p)
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

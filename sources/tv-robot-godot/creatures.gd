extends Node2D
## Food ecosystem. Positions and velocities are in the fixed logical room, never screen pixels.
const World=preload("res://world.gd")
var world=World.new()
var bodies:Array=[]
var grains:Array=[]
var bonds:Array=[]
var lineup:Array=[]
var rng=RandomNumberGenerator.new()
var clock=0.0
var next_id=1
var colony={}
var message=""
var player={}

func configure(_room_rect:Rect2,platform_rects:Array[Rect2])->void:
	world.platforms.assign(platform_rects)
	rng.randomize()

func body(kind:String,p:Vector2,r:float,mass:float)->Dictionary:
	var b={"id":next_id,"kind":kind,"p":p,"v":Vector2.ZERO,"r":r,"mass":mass,"angle":0.0,"phase":0.0,"hooked":false,"tension":0.0,"gravity":850.0,"bounce":0.04,"contacts":[],"timer":2.0,"cooldown":0.0}
	next_id+=1;bodies.append(b);return b

func restart(seed_value:int=-1)->void:
	if seed_value>=0:rng.seed=seed_value
	restart_lineup()

func restart_lineup(forced_lineup:Array=[])->void:
	bodies.clear();grains.clear();bonds.clear();next_id=1;clock=0;message=""
	var choices=[["pancake","popcorn"],["cake","popcorn"],["sushi","popcorn"],["cake","pancake"],["sushi","cake"],["sushi","pancake"],["cake","popcorn","sushi"],["cake","popcorn","pancake"]]
	lineup=forced_lineup.duplicate() if !forced_lineup.is_empty() else choices[rng.randi_range(0,choices.size()-1)].duplicate()
	if "cake" in lineup:
		var b=body("cake",Vector2(500,303.5),24,2.5)
		b.merge({"chunks":6,"crawling":true,"surface":0,"distance":80.0,"direction":1,"age":0.0,"jump_check":0.6,"jump_cooldown":2.0,"jump":{},"knockback":0.0,"bite":0.0})
	if "pancake" in lineup:
		var b=body("pancake",Vector2(300,150),34,1.8)
		b.merge({"gravity":0.0,"health":3,"dead":false,"pause":0.0,"hurt":0.0,"stun":0.0,"chew":0.0,"hunting":false,"goal":Vector2(650,170),"route":[],"route_timer":0.0})
	if "sushi" in lineup:
		for i in 7:
			var b=body("sushi",Vector2(720-i*29,world.FLOOR-15),14,0.75)
			b.merge({"index":i,"head":i==0,"follow":-1,"root":-1,"direction":1,"surface":"floor","climb":-1,"travel":1,"wander":3.0,"strain":0.0})
			if i>0:bonds.append({"a":bodies[bodies.size()-2].id,"b":b.id,"active":true,"strain":0.0,"reconnect":0.0})
	if "popcorn" in lineup:
		for i in 45:
			grains.append({"id":i,"p":Vector2(140+(i%7-3)*11,world.FLOOR-7-floori(i/7.0)*10),"v":Vector2.ZERO,"r":5.3+(i%4)*0.45,"bounce":0.03})
	colony={"mode":"pile","anchor":surface("floor",140),"target":230.0,"timer":4.0,"release":0.0,"route":{},"reason":""}
	queue_redraw()

func lookup(id:int)->Dictionary:
	for b in bodies:
		if b.id==id:return b
	return {}

func cake()->Dictionary:
	for b in bodies:
		if b.kind=="cake"&&b.chunks>0:return b
	return {}

func nearest_food(p:Vector2)->Dictionary:
	var nearest={};var distance=INF
	for grain in grains:
		var d=p.distance_to(grain.p)
		if d<distance:distance=d;nearest=grain
	return nearest

func step(dt:float,player_rect:Rect2,player_velocity:Vector2)->void:
	player={"p":player_rect.position+Vector2(14,145),"v":player_velocity};clock+=dt
	update_sushi(dt)
	for b in bodies:
		if b.kind=="cake"&&b.chunks<=0:continue
		b.phase+=dt*(3.0+b.v.length()*0.1);b.cooldown=maxf(0,b.cooldown-dt)
		if b.kind=="cake":update_cake(b,dt)
		elif b.kind=="pancake":update_pancake(b,dt)
		elif b.kind=="sushi":sushi_think(b,dt)
		if b.kind=="cake"&&(b.crawling||!b.jump.is_empty())&&!b.hooked:continue
		b.v.y+=b.gravity*dt
		b.v*=exp(-0.15*dt)
		var contact=world.move_body(b,b.v*dt,b.r)
		b.contacts=contact.contacts
		if b.kind=="pancake":pancake_crash(b,contact)
	for i in bodies.size():
		for j in range(i+1,bodies.size()):collide_pair(bodies[i],bodies[j])
	solve_sushi_links()
	update_popcorn(dt)
	for b in bodies:
		if b.kind=="cake"&&b.chunks<=0:continue
		world.collide(b,b.r)
		collide_player(b)
	for grain in grains:collide_player(grain)
	food_interactions(dt)
	queue_redraw()

func collide_player(b:Dictionary)->void:
	if player.is_empty()||player.get("ragdoll",false):return
	var feet:Vector2=player.get("p",Vector2(380,world.FLOOR))
	var near=b.p.clamp(feet-Vector2(14,145),feet+Vector2(14,0))
	var delta:Vector2=b.p-near
	var d=delta.length()
	if d>=b.r:return
	var n=delta.normalized() if d>0.001 else Vector2.RIGHT if b.p.x>=feet.x else Vector2.LEFT
	var penetration=b.r-d if d>0.001 else b.r+14-absf(b.p.x-feet.x)
	var share=10.0/(10+float(b.get("mass",0.4)))
	b.p+=n*penetration*share
	var relative=(b.v-player.get("v",Vector2.ZERO)).dot(n)
	if relative<0:b.v-=n*relative*share;pass
	world.collide(b,b.r)

func collide_pair(a:Dictionary,b:Dictionary)->void:
	if a.get("chunks",1)<=0||b.get("chunks",1)<=0:return
	var delta:Vector2=b.p-a.p
	var d=delta.length();var limit=a.r+b.r
	if d>=limit:return
	var n=delta/d if d>0.001 else Vector2.RIGHT
	var ia=1.0/a.mass;var ib=1.0/b.mass
	a.p-=n*(limit-d)*ia/(ia+ib);b.p+=n*(limit-d)*ib/(ia+ib)
	var relative=(b.v-a.v).dot(n)
	if relative<0:
		var impulse=-relative*1.04/(ia+ib)
		a.v-=n*impulse*ia;b.v+=n*impulse*ib

func perimeter(surface_index:int,distance:float,r:float)->Dictionary:
	# Outside platform vs inside room. Rounded corners keep the body out of the solid.
	var box=world.platforms[surface_index] if surface_index>=0 else Rect2(18,60,964,535)
	var points=[];var normals=[]
	if surface_index>=0:
		points=[Vector2(box.position.x,box.position.y-r),Vector2(box.end.x,box.position.y-r),Vector2(box.end.x+r,box.position.y),Vector2(box.end.x+r,box.end.y),Vector2(box.end.x,box.end.y+r),Vector2(box.position.x,box.end.y+r),Vector2(box.position.x-r,box.end.y),Vector2(box.position.x-r,box.position.y)]
		normals=[Vector2.UP,Vector2(1,-1).normalized(),Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,Vector2(-1,1).normalized(),Vector2.LEFT,Vector2(-1,-1).normalized()]
	else:
		box=box.grow(-r)
		points=[box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)]
		normals=[Vector2.DOWN,Vector2.LEFT,Vector2.UP,Vector2.RIGHT]
	var lengths=[];var total=0.0
	for i in points.size():var length=points[i].distance_to(points[(i+1)%points.size()]);lengths.append(length);total+=length
	var remaining=fposmod(distance,total)
	for i in points.size():
		if remaining<=lengths[i]:
			var tangent=(points[(i+1)%points.size()]-points[i]).normalized()
			return {"p":points[i]+tangent*remaining,"n":normals[i],"t":tangent,"total":total}
		remaining-=lengths[i]
	return {"p":points[0],"n":normals[0],"t":Vector2.RIGHT,"total":total}

func attach_cake(b:Dictionary)->bool:
	var best=INF;var chosen={}
	for surface_index in range(-1,world.platforms.size()):
		var total=perimeter(surface_index,0,24).total
		for i in 128:
			var point=perimeter(surface_index,total*i/128.0,24)
			var d=b.p.distance_to(point.p)
			if d<best:best=d;chosen={"surface":surface_index,"distance":total*i/128.0}
	if best>18:return false
	b.surface=chosen.surface;b.distance=chosen.distance;b.crawling=true;b.age=0.0
	return true

func update_cake(b:Dictionary,dt:float)->void:
	b.knockback=maxf(0,b.knockback-dt);b.jump_cooldown=maxf(0,b.jump_cooldown-dt);b.jump_check=maxf(0,b.jump_check-dt);b.bite=maxf(0,b.bite-dt)
	if b.hooked:b.crawling=false;b.jump={};return
	if !b.jump.is_empty():
		var jump=b.jump;jump.elapsed=minf(jump.duration,jump.elapsed+dt)
		var t=jump.elapsed;b.p=jump.start+jump.velocity*t+Vector2(0,425*t*t);b.v=jump.velocity+Vector2(0,850*t)
		if t>=jump.duration:b.surface=jump.surface;b.distance=jump.distance;b.jump={};b.crawling=true;b.age=0.0
		return
	if !b.crawling:
		if b.knockback<=0:attach_cake(b)
		return
	b.age+=dt;b.timer-=dt
	var food=nearest_food(b.p)
	var point=perimeter(b.surface,b.distance,24)
	if !food.is_empty():
		var best=INF;var target=0.0
		for i in 64:
			var candidate=point.total*i/64.0
			var d=perimeter(b.surface,candidate,24).p.distance_to(food.p)
			if d<best:best=d;target=candidate
		var forward=fposmod(target-b.distance,point.total)
		if minf(forward,point.total-forward)>7:b.direction=1 if forward<point.total-forward else -1
	elif b.timer<=0:
		b.timer=rng.randf_range(2,5)
		if rng.randf()<0.15:b.direction*=-1
	var speed=82.0 if !food.is_empty() else 68.0
	b.distance+=b.direction*speed*dt
	point=perimeter(b.surface,b.distance,24);b.p=point.p;b.v=point.t*speed*b.direction;b.angle=point.n.angle()+PI/2
	if b.jump_cooldown<=0&&b.jump_check<=0&&b.age>0.8:
		b.jump_check=0.6;try_cake_jump(b,food,point.n)
	if b.crawling&&b.surface>=0&&point.n.y>0.85&&b.age>12:b.crawling=false;b.knockback=0.6;b.v=Vector2(b.direction*45,70)

func try_cake_jump(b:Dictionary,food:Dictionary,normal:Vector2)->bool:
	var best=INF;var plan={}
	for surface_index in range(-1,world.platforms.size()):
		if surface_index==b.surface:continue
		var total=perimeter(surface_index,0,24).total
		for i in 48:
			var distance=total*i/48.0;var end=perimeter(surface_index,distance,24)
			var delta:Vector2=end.p-b.p
			if delta.length()<85||delta.length()>360:continue
			for duration in [0.4,0.55,0.7,0.85]:
				var velocity=delta/duration-Vector2(0,425*duration)
				if velocity.length()>850||velocity.dot(normal)<35||(velocity+Vector2(0,850*duration)).dot(end.n)>-25:continue
				var clear=true
				for step_index in 50:
					var t=duration*(step_index+1)/50.0;var p=b.p+velocity*t+Vector2(0,425*t*t)
					if p.x<42||p.x>958||p.y<84||p.y>world.FLOOR-24:clear=false;break
					for box in world.platforms:
						if p.distance_to(p.clamp(box.position,box.end))<23.5:clear=false
				if !clear:continue
				var score=end.p.distance_to(food.p) if !food.is_empty() else delta.length()+rng.randf()*140
				if !food.is_empty()&&score>b.p.distance_to(food.p)-35:continue
				if score<best:best=score;plan={"surface":surface_index,"distance":distance,"start":b.p,"velocity":velocity,"elapsed":0.0,"duration":duration}
	if plan.is_empty():return false
	b.jump=plan;b.crawling=false;b.jump_cooldown=4.0;b.v=plan.velocity
	return true

func update_pancake(b:Dictionary,dt:float)->void:
	b.pause=maxf(0,b.pause-dt);b.hurt=maxf(0,b.hurt-dt);b.stun=maxf(0,b.stun-dt);b.chew=maxf(0,b.chew-dt)
	if b.dead||b.hooked||b.stun>0:return
	var target=cake();b.hunting=!target.is_empty()&&b.pause<=0
	b.route_timer-=dt;b.timer-=dt
	if b.hunting:
		var direction=signf(target.p.x-b.p.x)
		b.goal=target.p+target.v*(0.32 if b.cooldown<=0 else 0.0)-Vector2(direction*(24 if b.cooldown<=0 else 75),35 if b.cooldown>0 else 0)
		var probe={"p":b.goal,"v":Vector2.ZERO}
		world.collide(probe,b.r+11);b.goal=probe.p
	elif b.timer<=0||b.p.distance_to(b.goal)<30:
		b.goal=Vector2(rng.randf_range(85,915),rng.randf_range(115,world.FLOOR-75));b.timer=rng.randf_range(5,9);b.route_timer=0
	if b.route_timer<=0:b.route=world.route(b.p,b.goal,b.r+10);b.route_timer=0.4
	while b.route.size()>1&&b.p.distance_to(b.route[0])<24:b.route.pop_front()
	var waypoint:Vector2=b.goal if b.route.is_empty() else b.route[0]
	var speed=12.0 if b.chew>0 else 25.0 if b.route.size()>1&&b.p.distance_to(waypoint)<65 else 52.0
	var acceleration=((waypoint-b.p).normalized()*speed-b.v)*2.4
	b.v+=acceleration.limit_length(125)*dt
	b.angle=lerp_angle(b.angle,clampf(atan2(b.v.y,maxf(15,absf(b.v.x))),-0.45,0.45),1-exp(-3*dt))

func pancake_crash(b:Dictionary,contact:Dictionary)->void:
	if b.dead||!b.hunting||contact.impact<=0:return
	b.hunting=false;b.pause=5.0;b.route=[];b.route_timer=0.0;b.timer=0.0
	if contact.impact<110||b.hurt>0:return
	b.health=maxi(0,b.health-1);b.hurt=0.85;b.stun=0.32;b.v+=contact.normal*105
	message="Pancake crashed · %d/3 health"%b.health
	if b.health==0:b.dead=true;b.gravity=850.0;b.chew=0.0

func sushi_groups()->Array:
	var groups=[];var seen={}
	for b in bodies:
		if b.kind!="sushi"||seen.has(b.id):continue
		var group=[];var queue=[b];seen[b.id]=true
		while !queue.is_empty():
			var current=queue.pop_back();group.append(current)
			for bond in bonds:
				if !bond.active:continue
				var neighbor=lookup(bond.b if bond.a==current.id else bond.a if bond.b==current.id else -1)
				if !neighbor.is_empty()&&!seen.has(neighbor.id):seen[neighbor.id]=true;queue.append(neighbor)
		groups.append(group)
	return groups

func degree(id:int)->int:
	var count=0
	for bond in bonds:
		if bond.active&&(bond.a==id||bond.b==id):count+=1
	return count

func update_sushi(dt:float)->void:
	for bond in bonds:
		if !bond.active:continue
		var a=lookup(bond.a);var b=lookup(bond.b)
		var tension=a.tension if a.hooked&&!b.hooked else b.tension if b.hooked&&!a.hooked else 0.0
		bond.strain=bond.strain+dt if tension>100 else maxf(0,bond.strain-dt*2)
		if bond.strain>0.45:bond.active=false;bond.reconnect=clock+1.3
	var groups=sushi_groups()
	for group in groups:
		var ends=group.filter(func(b):return degree(b.id)<=1)
		var head=ends[0] if !ends.is_empty() else group[0]
		for end in ends:
			if end.head:head=end;break
		head.wander-=dt
		if head.wander<=0&&ends.size()>1&&rng.randf()<0.15:head=ends[ends.size()-1];head.direction*=-1;head.climb=-int(head.get("climb",-1));head.travel=-int(head.get("travel",1))
		if head.wander<=0:head.wander=rng.randf_range(2,5)
		var visited={};var current=head;var previous=-1
		while !current.is_empty()&&!visited.has(current.id):
			visited[current.id]=true;current.head=current.id==head.id;current.follow=previous;current.root=head.id;previous=current.id
			var next={}
			for bond in bonds:
				if !bond.active:continue
				var id=bond.b if bond.a==current.id else bond.a if bond.b==current.id else -1
				if id>=0&&!visited.has(id):next=lookup(id);break
			current=next
		# Point free ends toward the nearest disconnected chain, never form a branch or loop.
		var closest={};var best=INF
		for other_group in groups:
			if other_group==group:continue
			for other in other_group:
				if degree(other.id)>1:continue
				var d=head.p.distance_to(other.p)
				if d<best:best=d;closest=other
		head.reunion=closest.get("p",Vector2.INF)
	for i in bodies.size():
		var a=bodies[i]
		if a.kind!="sushi"||a.hooked||degree(a.id)>1:continue
		for j in range(i+1,bodies.size()):
			var b=bodies[j]
			if b.kind!="sushi"||b.hooked||degree(b.id)>1||a.p.distance_to(b.p)>=35||(a.v-b.v).length()>=150:continue
			var same=false;var cooling=false
			for group in sushi_groups():
				if a in group&&b in group:same=true
			for link in bonds:
				if !link.active&&clock<link.reconnect&&(link.a in [a.id,b.id]||link.b in [a.id,b.id]):cooling=true
			if !same&&!cooling:bonds.append({"a":a.id,"b":b.id,"active":true,"strain":0.0,"reconnect":0.0})

func sushi_think(b:Dictionary,dt:float)->void:
	if b.hooked:return
	var candidates=[{"d":absf(b.p.y-(world.FLOOR-b.r)),"n":Vector2.UP,"kind":"floor"},{"d":absf(b.p.x-(18+b.r)),"n":Vector2.RIGHT,"kind":"left"},{"d":absf(b.p.x-(982-b.r)),"n":Vector2.LEFT,"kind":"right"},{"d":absf(b.p.y-(60+b.r)),"n":Vector2.DOWN,"kind":"ceiling"}]
	for box in world.platforms:
		if b.p.x>=box.position.x-b.r&&b.p.x<=box.end.x+b.r:
			candidates.append_array([{"d":absf(b.p.y-(box.position.y-b.r)),"n":Vector2.UP,"kind":"platform-top"},{"d":absf(b.p.y-(box.end.y+b.r)),"n":Vector2.DOWN,"kind":"platform-bottom"}])
		if b.p.y>=box.position.y-b.r&&b.p.y<=box.end.y+b.r:
			candidates.append_array([{"d":absf(b.p.x-(box.position.x-b.r)),"n":Vector2.LEFT,"kind":"platform-side"},{"d":absf(b.p.x-(box.end.x+b.r)),"n":Vector2.RIGHT,"kind":"platform-side"}])
	candidates.sort_custom(func(a,c):return a.d<c.d)
	var support=candidates[0]
	# Explicit corner transitions keep the leading roll climbing instead of pushing into a wall.
	if b.head&&b.p.y>=world.FLOOR-b.r-5:
		if b.p.x<=18+b.r+8&&b.direction<0:support={"d":0.0,"n":Vector2.RIGHT,"kind":"left"}
		if b.p.x>=982-b.r-8&&b.direction>0:support={"d":0.0,"n":Vector2.LEFT,"kind":"right"}
	if b.head&&b.surface in ["left","right"]&&b.p.y<=60+b.r+5:support={"d":0.0,"n":Vector2.DOWN,"kind":"ceiling"}
	if support.d>=7:b.gravity=850.0;b.surface="air";return
	b.gravity=0.0
	var n:Vector2=support.n;var previous=b.surface;b.surface=support.kind
	var desired=Vector2.ZERO
	if b.head:
		if n.x!=0:
			if previous!=b.surface:b.climb=1 if previous=="ceiling" else -1
			desired.y=b.climb*54.0
		elif n.y>0:
			if previous=="left":b.travel=1
			if previous=="right":b.travel=-1
			desired.x=b.travel*54.0
		else:
			if previous=="left":b.direction=1
			if previous=="right":b.direction=-1
			if b.get("reunion",Vector2.INF).is_finite():b.direction=int(signf(b.reunion.x-b.p.x))
			desired.x=b.direction*54.0
	else:
		var leader=lookup(b.follow)
		if !leader.is_empty():desired=leader.v+(leader.p-leader.v.normalized()*29-b.p)*3
	var acceleration=(desired-b.v)*6.0
	if n.x!=0:b.v.y+=clampf(acceleration.y,-350,350)*dt
	else:b.v.x+=clampf(acceleration.x,-350,350)*dt
	b.v-=n*170*dt;b.angle=lerp_angle(b.angle,atan2(n.x,-n.y),1-exp(-8*dt))

func solve_sushi_links()->void:
	for iteration in 4:
		for link in bonds:
			if !link.active:continue
			var a=lookup(link.a);var b=lookup(link.b);var delta:Vector2=b.p-a.p;var distance=delta.length()
			if distance>29*1.9:link.active=false;link.reconnect=clock+1.3;continue
			if distance<0.001:continue
			var shift=delta*(distance-29)/distance*0.5
			a.p+=shift;b.p-=shift
			world.collide(a,a.r);world.collide(b,b.r)

func food_interactions(_dt:float)->void:
	var spider=cake()
	if spider.is_empty():return
	var food=nearest_food(spider.p)
	if !food.is_empty()&&spider.cooldown<=0&&spider.knockback<=0&&spider.p.distance_to(food.p)<=28+food.r:
		grains.erase(food);spider.cooldown=0.65;spider.bite=0.3;message="Cake ate one popcorn · %d remaining"%grains.size()
	for b in bodies:
		if b.kind!="pancake"||b.dead||b.hooked||b.cooldown>0||b.pause>0:continue
		var mouth=b.p+Vector2(24 if b.v.x>=0 else -24,3).rotated(b.angle)
		if mouth.distance_to(spider.p)>22||!world.clear_line(mouth,spider.p):continue
		spider.chunks=maxi(0,spider.chunks-1);b.cooldown=5.0;b.chew=0.65
		message="Pancake bit the cake · %d chunks left"%spider.chunks
		if spider.chunks==0:spider.crawling=false;spider.v=Vector2.ZERO

func surface(kind:String,position:float,index:int=0)->Dictionary:
	if kind=="platform":
		var box=world.platforms[index]
		return {"kind":kind,"index":index,"p":Vector2(clampf(position,box.position.x+20,box.end.x-20),box.position.y-12),"n":Vector2.UP}
	if kind in ["left","right"]:return {"kind":kind,"p":Vector2(34 if kind=="left" else 966,clampf(position,100,world.FLOOR-45)),"n":Vector2.RIGHT if kind=="left" else Vector2.LEFT}
	return {"kind":kind,"p":Vector2(clampf(position,65,935),75 if kind=="ceiling" else world.FLOOR-8),"n":Vector2.DOWN if kind=="ceiling" else Vector2.UP}

func nearest_surface(p:Vector2)->Dictionary:
	var options=[surface("floor",p.x),surface("ceiling",p.x),surface("left",p.y),surface("right",p.y)]
	for i in world.platforms.size():options.append(surface("platform",p.x,i))
	options.sort_custom(func(a,b):return a.p.distance_squared_to(p)<b.p.distance_squared_to(p))
	return options[0]

func popcorn_center()->Vector2:
	var p=Vector2.ZERO
	for g in grains:p+=g.p
	return p/maxi(1,grains.size())

func popcorn_components()->Array:
	var groups=[];var seen={}
	for grain in grains:
		if seen.has(grain.id):continue
		var group=[];var queue=[grain];seen[grain.id]=true
		while !queue.is_empty():
			var current=queue.pop_back();group.append(current)
			for other in grains:
				if !seen.has(other.id)&&current.p.distance_to(other.p)<=(current.r+other.r)*1.65:seen[other.id]=true;queue.append(other)
		groups.append(group)
	groups.sort_custom(func(a,b):return a.size()>b.size())
	return groups

func popcorn_reach(group:Array)->float:
	var reach=0.0
	for i in range(1,group.size()):reach+=(group[i-1].r+group[i].r)*1.12
	return reach

func start_stretch(destination:Dictionary={})->bool:
	if grains.size()<2||colony.mode in ["loose","towed"]||colony.release>0:return false
	var groups=popcorn_components()
	var group:Array=groups[0]
	if group.size()<2:return false
	var center=Vector2.ZERO;var max_radius=0.0
	for g in group:center+=g.p;max_radius=maxf(max_radius,g.r)
	center/=group.size()
	var origin=nearest_surface(center)
	var targets=[destination] if !destination.is_empty() else [surface("floor",rng.randf_range(65,935)),surface("left",rng.randf_range(100,world.FLOOR-45)),surface("right",rng.randf_range(100,world.FLOOR-45)),surface("ceiling",rng.randf_range(65,935))]
	if destination.is_empty():
		for i in world.platforms.size():targets.append(surface("platform",rng.randf_range(world.platforms[i].position.x+20,world.platforms[i].end.x-20),i))
	var routes=[]
	for target in targets:
		if target.p.distance_to(origin.p)<45:continue
		var path=world.route(origin.p,target.p,max_radius+1)
		if path.is_empty():continue
		path.push_front(origin.p)
		var length=0.0
		for i in range(1,path.size()):length+=path[i-1].distance_to(path[i])
		routes.append({"points":path,"length":length,"destination":target})
	if routes.is_empty():colony.timer=1.0;return false
	var feasible=routes.filter(func(route):return route.length<=popcorn_reach(group))
	var choices=feasible if !feasible.is_empty()&&rng.randf()<0.8 else routes
	var route:Dictionary=choices[rng.randi_range(0,choices.size()-1)]
	route.merge({"members":group.map(func(g):return g.id),"capacity":popcorn_reach(group),"progress":0.0,"travel":0.0,"hold":0.0,"blocked":0.0})
	colony.route=route;colony.anchor=origin;colony.mode="bridge";colony.reason=""
	return true

func collapse(reason:String)->void:
	colony.reason=reason;colony.mode="loose";colony.route={};colony.release=1.3;colony.timer=3.0;colony.anchor=nearest_surface(popcorn_center());colony.target=colony.anchor.p.x

func route_point(route:Dictionary,t:float)->Vector2:
	var distance=clampf(t,0,1)*route.length
	for i in range(1,route.points.size()):
		var a:Vector2=route.points[i-1];var b:Vector2=route.points[i];var length=a.distance_to(b)
		if distance<=length||i==route.points.size()-1:return a.lerp(b,minf(1,distance/maxf(length,0.001)))
		distance-=length
	return route.points[0]

func update_popcorn(dt:float)->void:
	if grains.is_empty():colony.mode="pile";colony.route={};return
	colony.release=maxf(0,colony.release-dt)
	if colony.mode=="loose"&&colony.release==0:colony.anchor=nearest_surface(popcorn_center());colony.mode="pile";colony.target=colony.anchor.p.y if colony.anchor.n.x!=0 else colony.anchor.p.x
	if colony.mode=="pile":
		colony.timer-=dt
		var anchor=colony.anchor;var spider=cake();var position=anchor.p.y if anchor.n.x!=0 else anchor.p.x
		var minimum=100.0 if anchor.n.x!=0 else 65.0;var maximum=world.FLOOR-45 if anchor.n.x!=0 else 935.0
		if anchor.kind=="platform":minimum=world.platforms[anchor.index].position.x+20;maximum=world.platforms[anchor.index].end.x-20
		var panic=!spider.is_empty()&&spider.p.distance_to(anchor.p)<230
		if panic:colony.target=clampf(position+(1 if position>=(spider.p.y if anchor.n.x!=0 else spider.p.x) else -1)*180,minimum,maximum)
		var next=move_toward(position,colony.target,(140 if panic else 58)*dt)
		if anchor.n.x!=0:anchor.p.y=clampf(next,minimum,maximum)
		else:anchor.p.x=clampf(next,minimum,maximum)
		if colony.timer<=0:start_stretch()
	if colony.mode=="bridge":
		var route:Dictionary=colony.route
		var survivors=grains.filter(func(g):return g.id in route.members)
		var connected=[]
		for group in popcorn_components():
			if !survivors.is_empty()&&survivors[0] in group:connected=survivors.filter(func(g):return g in group);break
		route.capacity=popcorn_reach(connected)
		var limit=minf(1,route.capacity/route.length)
		if connected.size()<2||route.progress>limit+0.02||(route.travel>0&&limit<1):collapse("Group lost the reach needed to hold the formation")
		else:
			route.progress=minf(limit,route.progress+dt*155/route.length)
			if limit<1&&route.progress>=limit-0.000001:
				route.blocked+=dt
				if route.blocked>0.55:collapse("Destination beyond this group’s reach")
			elif route.progress>=1:
				route.hold+=dt
				if route.hold>0.8:route.travel=minf(1,route.travel+dt*155/route.length)
			if colony.mode=="bridge"&&route.travel>=1:colony.anchor=route.destination.duplicate(true);colony.mode="pile";colony.route={};colony.timer=rng.randf_range(3,6);colony.target=colony.anchor.p.y if colony.anchor.n.x!=0 else colony.anchor.p.x
	var groups=popcorn_components();var main:Array=groups[0] if !groups.is_empty() else []
	for grain in grains:
		var loose=colony.mode in ["loose","towed"]||colony.release>0
		var route:Dictionary=colony.route;var index=route.get("members",[]).find(grain.id)
		var forming=colony.mode=="bridge"&&index>=0
		var target:Vector2=grain.p
		if forming:
			var t=index/float(maxi(1,route.members.size()-1))*route.progress+route.travel
			target=route_point(route,t)
			if t>1:target+=pile_offset(index,route.destination.n)
		elif !loose:
			target=colony.anchor.p+pile_offset(grain.id,colony.anchor.n)
			if !(grain in main)&&!main.is_empty():
				var nearest:Dictionary=main[0]
				for g in main:
					if g.p.distance_squared_to(grain.p)<nearest.p.distance_squared_to(grain.p):nearest=g
				var path=world.route(grain.p,nearest.p,grain.r)
				if !path.is_empty():target=path[0]
		grain.v+=(target-grain.p)*Vector2(45 if forming else 30,70 if forming else 40)*dt
		grain.v.y+=(850 if loose else 360)*dt
		grain.v*=Vector2(exp(-(0.55 if loose else 8)*dt),exp(-(0.55 if loose else 9)*dt))
		world.move_body(grain,grain.v*dt,grain.r)
	for iteration in 3:
		for i in grains.size():
			for j in range(i+1,grains.size()):
				var a=grains[i];var b=grains[j];var delta:Vector2=b.p-a.p;var d=delta.length();var minimum=(a.r+b.r)*0.85
				if d<minimum&&d>0.001:var shift=delta*(minimum-d)/d*0.28;a.p-=shift;b.p+=shift
				elif colony.mode=="pile"&&d<20:a.p+=delta*0.004;b.p-=delta*0.004
		if colony.mode=="bridge":
			var chain=[]
			for id in colony.route.members:
				for g in grains:
					if g.id==id:chain.append(g);break
			for i in range(chain.size()-1):
				var a=chain[i];var b=chain[i+1];var delta:Vector2=b.p-a.p;var d=delta.length();var limit=(a.r+b.r)*1.12
				if d>limit:var shift=delta*(d-limit)/d*0.45;a.p+=shift;b.p-=shift
		for grain in grains:world.collide(grain,grain.r)

func pile_offset(index:int,normal:Vector2)->Vector2:
	return Vector2(-normal.y,normal.x)*(index%7-3)*10.5+normal*floori(index/7.0)*8.5

func ray_target(a:Vector2,b:Vector2)->Dictionary:
	var delta=b-a;var length=delta.length_squared();var best={};var candidates=bodies+grains
	for item in candidates:
		if item.get("chunks",1)<=0:continue
		var t=clampf((item.p-a).dot(delta)/maxf(length,0.001),0,1);var hit=a+delta*t
		if hit.distance_to(item.p)<=item.r+2&&(best.is_empty()||t<best.t):best={"id":str(item.id) if item.has("kind") else "popcorn","point":hit,"distance":a.distance_to(hit),"t":t,"kind":item.get("kind","popcorn")}
	return best

func target_valid(id:int)->bool:
	return !grains.is_empty() if id==-1 else !lookup(id).is_empty()&&lookup(id).get("chunks",1)>0
func body_position(id:int)->Vector2:
	return popcorn_center() if id==-1 else lookup(id).get("p",Vector2.ZERO)
func body_mass(id:int)->float:
	return maxf(1,grains.size()*0.15) if id==-1 else lookup(id).get("mass",1.0)
func target_velocity(id:int)->Vector2:
	if id!=-1:return lookup(id).get("v",Vector2.ZERO)
	var v=Vector2.ZERO
	for g in grains:v+=g.v
	return v/maxi(1,grains.size())
func grab(id:int)->void:
	if id==-1:colony.mode="towed";colony.route={};colony.release=0.0
	else:
		var b=lookup(id)
		if !b.is_empty():b.hooked=true
func pull(id:int,delta:Vector2,impulse:Vector2,tension:float)->void:
	var group=grains if id==-1 else [lookup(id)]
	for b in group:
		if b.is_empty():continue
		b.tension=tension;b.v+=impulse;world.move_body(b,delta,b.r)
func release(id:int)->void:
	if id==-1:collapse("Grapple released the colony")
	else:
		var b=lookup(id)
		if !b.is_empty():b.hooked=false;b.tension=0.0
func punch_at(p:Vector2,impulse:Vector2,radius:float=12.0)->void:
	var hits=[]
	for b in bodies:
		if b.get("chunks",1)<=0||b.p.distance_to(p)>b.r+radius:continue
		b.v+=impulse/b.mass;hits.append(b.id)
		if b.kind=="cake":b.crawling=false;b.jump={};b.knockback=0.6

func target_position(id:String)->Vector2:
	return body_position(-1 if id=="popcorn" else int(id))
func target_mass(id:String)->float:
	return body_mass(-1 if id=="popcorn" else int(id))
func has_target(id:String)->bool:
	return !id.is_empty()&&target_valid(-1 if id=="popcorn" else int(id))
func pull_target(id:String,displacement:Vector2,impulse:Vector2,tension:float)->void:
	var numeric=-1 if id=="popcorn" else int(id)
	grab(numeric)
	pull(numeric,displacement,impulse,tension)
func release_target(id:String)->void:
	release(-1 if id=="popcorn" else int(id))

func debug_state()->Dictionary:
	return {"popcorn_count":grains.size(),"popcorn_mode":colony.get("mode","pile"),"popcorn_capacity":colony.get("route",{}).get("capacity",popcorn_reach(grains)),"popcorn_destination":colony.get("route",{}).get("destination",{}).get("kind",""),"cake_chunks":cake().get("chunks",0),"sushi_groups":sushi_groups().map(func(group):return group.map(func(b):return b.id)),"pancake_health":bodies.filter(func(b):return b.kind=="pancake").map(func(b):return b.health),"lineup":lineup.duplicate(),"bodies":bodies.duplicate(true),"grains":grains.duplicate(true),"bonds":bonds.duplicate(true),"colony":colony.duplicate(true),"message":message}

func _draw()->void:
	for link in bonds:
		if link.active:draw_line(lookup(link.a).p,lookup(link.b).p,Color("e9d8ae"),3,true)
	for grain in grains:
		var p:Vector2=grain.p;var walk=sin(clock*13+grain.id)*1.5
		for side in [-1,1]:draw_line(p+Vector2(side*3,3),p+Vector2(side*(6+walk),7),Color("927545"),1,true)
		for l in range(3+grain.id%3):var a=grain.id*0.79+l*TAU/(3+grain.id%3);draw_circle(p+Vector2.from_angle(a)*grain.r*0.48,grain.r*0.58,Color("fff3cf"))
		draw_circle(p+Vector2(-1,1),1.5,Color("c09245"));draw_circle(p+Vector2(2,-1),0.8,Color("433a25"))
	for b in bodies:
		if b.kind=="cake"&&b.chunks<=0:continue
		draw_set_transform(b.p,b.angle)
		match b.kind:
			"cake":draw_cake(b)
			"pancake":draw_pancake(b)
			"sushi":draw_sushi(b)
		draw_set_transform(Vector2.ZERO)

func draw_cake(b:Dictionary)->void:
	for side in [-1,1]:
		for i in 2:
			var hip=Vector2(side*16,5);var knee=Vector2(side*(32+i*6),13+sin(b.phase+i)*4);var foot=Vector2(side*(43+i*5),26+sin(b.phase+i)*5)
			draw_line(hip,knee,Color("78554a"),5,true);draw_line(knee,foot,Color("cba88a"),4,true);draw_circle(knee,3,Color("e2c7a0"))
	var cake_shape=PackedVector2Array([Vector2(-28,18),Vector2(24,18),Vector2(31,-8),Vector2(-13,-26),Vector2(-30,-8)])
	draw_colored_polygon(cake_shape,Color("b7865b"))
	draw_line(Vector2(-28,2),Vector2(28,2),Color("e7c594"),6,true)
	draw_line(Vector2(-27,-9),Vector2(28,-9),Color("f0dfc3"),8,true)
	draw_circle(Vector2(3,-21),6,Color("c76173"));draw_line(Vector2(4,-25),Vector2(8,-31),Color("73864b"),2,true)
	for i in b.chunks:draw_circle(Vector2(-19+i*7,-14),2.4,Color("e3ab8c"))
	for side in [-1,1]:draw_circle(Vector2(side*9,4),3,Color("392e28"));draw_circle(Vector2(side*9+1,3),1,Color("fff3cc"))
	draw_arc(Vector2(0,7),5,0,PI,12,Color("52372e"),1.5,true)

func draw_pancake(b:Dictionary)->void:
	var facing=1 if b.v.x>=0 else -1
	draw_line(Vector2(-19*facing,4),Vector2(-60*facing,8+sin(b.phase)*9),Color("81482c"),4,true)
	var flap=22.0 if b.dead else sin(b.phase)*17
	for side in [-1,1]:draw_colored_polygon(PackedVector2Array([Vector2(-17,side*5),Vector2(-42,flap+side*8),Vector2(-28,15+side*5),Vector2(15,7)]),Color("d6a35f") if side>0 else Color("b47c41"))
	food_ellipse(Vector2(0,3),Vector2(24,10),Color("a97037"));food_ellipse(Vector2.ZERO,Vector2(24,10),Color("e2b975"))
	for i in 3:draw_rect(Rect2(-12+i*7,-16,5.5,5),Color("ffe599") if i<b.health else Color("735338"))
	for ex in [12,19]:
		draw_rect(Rect2(ex*facing-3,-12,6,7),Color("f1d979"))
		if b.dead:draw_line(Vector2(ex*facing-1,-11),Vector2(ex*facing+2,-8),Color("453623"),1);draw_line(Vector2(ex*facing+2,-11),Vector2(ex*facing-1,-8),Color("453623"),1)
		else:draw_circle(Vector2(ex*facing,-9),1.2,Color("453623"))

func draw_sushi(b:Dictionary)->void:
	for side in [-1,1]:
		for leg in 2:var p=Vector2(side*(6+leg*4),9);draw_line(p,p+Vector2(sin(b.phase+leg)*3,7),Color("c9b67d"),2,true)
	draw_rect(Rect2(-14,-13,28,26),Color("253e31"));draw_circle(Vector2.ZERO,12,Color("e9e7cf"));draw_circle(Vector2.ZERO,5.5,Color("ed967c"))
	draw_rect(Rect2(-2,-5,2,8),Color("799452"));draw_rect(Rect2(1,-1,3,3),Color("f0ce81"))
	for i in 10:food_ellipse(Vector2.from_angle(i*2.399+b.index)*8,Vector2(1.6,0.8),Color("fff8e6"))
	if b.head:
		for ex in [5,9]:draw_rect(Rect2(ex,-5,2,3),Color("223023"));draw_line(Vector2(ex,-12),Vector2(ex+2,-18),Color("94a66b"),1.3);draw_circle(Vector2(ex+2,-18),1.6,Color("e9d7a4"))
	if b.hooked:draw_arc(Vector2.ZERO,18,0,TAU,32,Color("96d4bc"),1.5,true)

func food_ellipse(center:Vector2,radii:Vector2,color:Color)->void:
	var points=PackedVector2Array()
	for i in 32:points.append(center+Vector2.from_angle(i*TAU/32)*radii)
	draw_colored_polygon(points,color)

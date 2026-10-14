extends Node2D
const World=preload("res://world.gd")
const Foods=preload("res://creatures.gd")
const Robot=preload("res://robot_visual.gd")
var world=World.new()
var creatures=Foods.new()
var robot=Robot.new()
var actor=CharacterBody2D.new()
var facing=1.0
var clock=0.0
var aim=Vector2(650,360)
var crouched=false
var punch_time=-1.0
var punch_cooldown=0.0
var punch_hits=[]
var hook={"state":"idle","target":"","p":Vector2.ZERO,"anchor":Vector2.ZERO,"length":65.0,"travel":0.0,"total":0.0,"start":Vector2.ZERO,"end":Vector2.ZERO,"offset":Vector2.ZERO}
var ragdoll_active=false
var recovery_grace=0.5
var loose_nodes={}
var status:Label
var population:Label
var held_buttons={}
var grounded=true
var held_shift_locations={}

func _ready()->void:
	create_input()
	actor.position=Vector2(380,World.FLOOR-72.5);actor.collision_layer=1;actor.collision_mask=1;actor.floor_snap_length=3
	var shape=CollisionShape2D.new();var rect=RectangleShape2D.new();rect.size=Vector2(28,145);shape.shape=rect;actor.add_child(shape);add_child(actor)
	var solids=[Rect2(8,50,10,World.FLOOR-50),Rect2(982,50,10,World.FLOOR-50),Rect2(18,50,964,10),Rect2(18,World.FLOOR,964,105)]
	solids.append_array(world.platforms)
	for box in solids:
		var solid=StaticBody2D.new();solid.position=box.get_center();var collider=CollisionShape2D.new();var geometry=RectangleShape2D.new();geometry.size=box.size;collider.shape=geometry;solid.add_child(collider);add_child(solid)
	creatures.configure(Rect2(18,60,964,535),world.platforms);add_child(creatures);add_child(robot)
	build_ui();restart();publish_debug()

func create_input()->void:
	var mappings={"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE],"crouch":[KEY_S,KEY_DOWN],"run":[KEY_SHIFT],"release_hook":[KEY_R],"restart_run":[KEY_ENTER]}
	for action in mappings:
		if !InputMap.has_action(action):InputMap.add_action(action)
		for code in mappings[action]:var event=InputEventKey.new();event.physical_keycode=code;InputMap.action_add_event(action,event)
	for action in ["punch","grapple"]:
		if !InputMap.has_action(action):InputMap.add_action(action)
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT if action=="punch" else MOUSE_BUTTON_RIGHT;InputMap.action_add_event(action,event)

func build_ui()->void:
	var layer=CanvasLayer.new();add_child(layer)
	population=Label.new();population.position=Vector2(20,15);layer.add_child(population)
	status=Label.new();status.position=Vector2(20,40);status.add_theme_color_override("font_color",Color("bcceca"));layer.add_child(status)
	var hint=Label.new();hint.position=Vector2(20,620);hint.text="A / D or arrows: walk · Space: jump · S: crouch · Shift: run\nLeft click: punch · Right click: grapple/release · R: release\nRelease the hook to carry momentum. Any movement key recovers a ragdoll.";hint.add_theme_font_size_override("font_size",12);layer.add_child(hint)
	var buttons=HBoxContainer.new();buttons.position=Vector2(580,640);layer.add_child(buttons)
	for item in [["Left","move_left"],["Right","move_right"],["Jump","jump"],["Restart","restart_run"]]:
		var button=Button.new();button.text=item[0];button.custom_minimum_size=Vector2(88,40);button.focus_mode=Control.FOCUS_NONE;buttons.add_child(button)
		button.button_down.connect(func():held_buttons[item[1]]=true;if item[1]=="jump":jump();if item[1]=="restart_run":restart();if ragdoll_active:recover())
		button.button_up.connect(func():held_buttons[item[1]]=false)

func feet()->Vector2:return actor.position+Vector2(0,72.5)

func restart(seed_value:int=-1)->void:
	release_hook();actor.get_child(0).set_deferred("disabled",false);actor.position=Vector2(380,World.FLOOR-72.5);actor.velocity=Vector2.ZERO;ragdoll_active=false;loose_nodes.clear();robot.loose_pose={};punch_time=-1;punch_cooldown=0;facing=1;grounded=true;recovery_grace=0.5;held_buttons.clear();creatures.restart(seed_value);status.text="Grappling gun equipped";update_visual()
	held_shift_locations.clear()
	for action in ["move_left","move_right","run","jump","crouch"]:Input.action_release(action)

func action_down(action:String)->bool:
	if action=="run"&&held_shift_locations.values().has(true):return true
	return Input.is_action_pressed(action)||held_buttons.get(action,false)

func _input(event:InputEvent)->void:
	if event is InputEventKey&&(event.physical_keycode==KEY_SHIFT||event.keycode==KEY_SHIFT):held_shift_locations[event.location]=event.pressed
	if event is InputEventMouseMotion||event is InputEventMouseButton:aim=get_global_mouse_position()
	if event is InputEventKey&&event.pressed&&!event.echo:
		if ragdoll_active:recover();return
		if event.is_action_pressed("jump"):jump()
		if event.is_action_pressed("release_hook"):release_hook()
		if event.is_action_pressed("restart_run"):restart()
	if event is InputEventMouseButton&&event.pressed:
		if event.button_index==MOUSE_BUTTON_LEFT:start_punch()
		if event.button_index==MOUSE_BUTTON_RIGHT:fire_hook()

func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		held_buttons.clear();held_shift_locations.clear()
		for action in ["move_left","move_right","run","jump","crouch"]:Input.action_release(action)

func jump()->void:
	if ragdoll_active:recover();return
	if grounded:actor.velocity.y=-410;grounded=false

func _physics_process(dt:float)->void:
	clock+=dt;recovery_grace=maxf(0,recovery_grace-dt);punch_cooldown=maxf(0,punch_cooldown-dt)
	if punch_time>=0:punch_time+=dt;if punch_time>0.30:punch_time=-1
	creatures.step(dt,Rect2() if ragdoll_active else Rect2(feet()-Vector2(14,145),Vector2(28,145)),actor.velocity)
	if !ragdoll_active:
		var response=creatures.player_contact_response()
		actor.move_and_collide(response.displacement);actor.velocity+=response.velocity_change
	if ragdoll_active:update_ragdoll(dt)
	else:
		var direction=float(action_down("move_right"))-float(action_down("move_left"))
		crouched=action_down("crouch");var speed=65.0 if crouched else 245.0 if action_down("run") else 145.0
		if grounded:actor.velocity.x=lerpf(actor.velocity.x,direction*speed,1-exp(-12*dt))
		else:actor.velocity.x=clampf((actor.velocity.x+direction*(420 if hook.state=="attached" else 240)*dt)*exp(-0.18*dt),-480,480)
		if direction!=0:facing=direction
		actor.velocity.y+=1000*dt
		var before=actor.velocity;actor.move_and_slide();grounded=actor.is_on_floor()
		var impact_normal=Vector2.ZERO
		for i in actor.get_slide_collision_count():
			var n=actor.get_slide_collision(i).get_normal()
			if -before.dot(n)>=340&&n.y>-0.8:impact_normal=n
		if impact_normal!=Vector2.ZERO&&recovery_grace<=0:actor.velocity=before+impact_normal*(-before.dot(impact_normal))*1.25;enter_ragdoll()
		update_hook(dt)
	update_visual()
	if punch_time>=0.065&&punch_time<=0.21:
		var direction=(aim-robot.fist()).normalized()
		var targets=creatures.bodies.filter(func(b):return !(b.id in punch_hits)&&b.p.distance_to(robot.fist())<=b.r+7)
		for target in targets:target.v+=(direction*280-Vector2(0,50))/target.mass;punch_hits.append(target.id);if target.kind=="cake":target.crawling=false;target.jump={};target.knockback=0.6
	population.text="Creatures: "+" + ".join(creatures.lineup)+(" · Popcorn: %d"%creatures.grains.size() if "popcorn" in creatures.lineup else "")
	if !creatures.message.is_empty():status.text=creatures.message;creatures.message=""
	queue_redraw();publish_debug()

func start_punch()->void:
	if ragdoll_active||punch_cooldown>0:return
	punch_time=0;punch_cooldown=0.38;punch_hits=[]

func fire_hook()->void:
	if ragdoll_active:return
	if hook.state!="idle":release_hook();return
	var origin=robot.gun_hand();var end=origin+(aim-origin).normalized()*2500
	var solid=world.ray_world(origin,end)
	var creature_hit=creatures.ray_target(origin,solid.p if !solid.is_empty() else end)
	if solid.is_empty()&&creature_hit.is_empty():return
	hook.target=creature_hit.id if !creature_hit.is_empty() else ""
	hook.end=creature_hit.point if !creature_hit.is_empty() else solid.p
	hook.start=origin;hook.p=origin;hook.total=origin.distance_to(hook.end);hook.travel=0.0;hook.state="flying"
	hook.offset=hook.end-creatures.target_position(hook.target) if !hook.target.is_empty() else Vector2.ZERO
	status.text="Hook fired"

func release_hook()->void:
	if !hook.target.is_empty():creatures.release_target(hook.target)
	hook.state="idle";hook.target=""
	if is_instance_valid(status):status.text="Grapple released"

func update_hook(dt:float)->void:
	if hook.state=="idle":return
	if !hook.target.is_empty()&&!creatures.has_target(hook.target):release_hook();return
	if hook.state=="flying":
		hook.travel=minf(hook.total,hook.travel+1250*dt);hook.p=hook.start.lerp(hook.end,hook.travel/maxf(0.001,hook.total))
		if hook.travel>=hook.total:hook.state="attached";hook.anchor=hook.end;hook.length=maxf(65,(feet()-Vector2(0,75)).distance_to(hook.anchor));status.text="Hook attached · Right click or R to release"
	if hook.state!="attached":return
	if !hook.target.is_empty():hook.anchor=creatures.target_position(hook.target)+hook.offset
	hook.p=hook.anchor
	var previous=hook.length;hook.length=maxf(65,hook.length-175*dt);var reel=(previous-hook.length)/dt
	var delta:Vector2=hook.anchor-(feet()-Vector2(0,75));var distance=delta.length()
	if distance<=hook.length:
		if !hook.target.is_empty():creatures.pull_target(hook.target,Vector2.ZERO,Vector2.ZERO,0)
		return
	var n=delta.normalized();var excess=distance-hook.length
	if hook.target.is_empty():
		actor.move_and_collide(n*excess)
		var radial=actor.velocity.dot(n)
		if radial<reel:actor.velocity+=n*(reel-radial)
	else:
		var share=10/(10+creatures.target_mass(hook.target))
		var numeric=-1 if hook.target=="popcorn" else int(hook.target)
		var relative=(creatures.target_velocity(numeric)-actor.velocity).dot(n)
		var impulse=maxf(0,relative+reel)
		creatures.pull_target(hook.target,-n*excess*share,-n*impulse*share,maxf(excess/dt,relative+reel))
		actor.move_and_collide(n*excess*(1-share));actor.velocity+=n*impulse*(1-share)
		if !creatures.has_target(hook.target):release_hook()

func enter_ragdoll()->void:
	update_visual();ragdoll_active=true;release_hook();punch_time=-1;loose_nodes={}
	for id in robot.joints:
		var p=robot.to_global(robot.joints[id]);var spin=(p.y-(feet().y-68))*0.65
		loose_nodes[id]={"p":p,"previous":p-(actor.velocity-Vector2(spin,-(p.x-feet().x)*0.65))/60,"v":actor.velocity}
	actor.get_child(0).set_deferred("disabled",true)

func update_ragdoll(dt:float)->void:
	for n in loose_nodes.values():var velocity=(n.p-n.previous)*0.993;n.previous=n.p;n.p+=velocity+Vector2(0,1000*dt*dt);n.v=velocity/dt
	for iteration in 10:
		for link in robot.LINKS:
			var a=loose_nodes[link[0]];var b=loose_nodes[link[1]];var delta:Vector2=b.p-a.p;var distance=delta.length()
			if distance>0.001:var correction=delta*(distance-link[2])/distance*0.5;a.p+=correction;b.p-=correction
		for id in loose_nodes:
			var n=loose_nodes[id];var before:Vector2=n.p
			world.collide(n,17 if id=="head" else 3)
			if n.p!=before:n.previous=n.p-n.v*dt*0.73
	var contact_points=[]
	for id in loose_nodes:
		var point=loose_nodes[id];point.r=17 if id=="head" else 3;contact_points.append(point)
	creatures.collide_loose_nodes(contact_points)
	var center=(loose_nodes.chest.p+loose_nodes.hips.p)*0.5+Vector2(0,68)
	actor.velocity=(center-feet())/dt;actor.position=center-Vector2(0,72.5);grounded=false
	robot.loose_pose={}
	for id in loose_nodes:robot.loose_pose[id]=loose_nodes[id].p-feet()

func recover()->void:
	if !ragdoll_active:return
	ragdoll_active=false;robot.loose_pose={};loose_nodes.clear();recovery_grace=0.7
	actor.position.x=clampf(actor.position.x,50,950);actor.position.y=clampf(actor.position.y,132.5,World.FLOOR-72.5)
	for box in world.platforms:
		var player_rect=Rect2(feet()-Vector2(14,145),Vector2(28,145))
		if player_rect.intersects(box):actor.position.x=box.position.x-15 if actor.position.x<box.get_center().x else box.end.x+15
	actor.get_child(0).set_deferred("disabled",false);held_buttons.clear()
	status.text="Back on your feet · Controls active";update_visual()

func update_visual()->void:
	robot.position=feet();robot.set_pose(actor.velocity,grounded,facing,crouched,aim,punch_time,ragdoll_active,clock)

func debug_state()->Dictionary:
	return {"player_feet":feet(),"player_velocity":actor.velocity,"grounded":grounded,"ragdoll_active":ragdoll_active,"hook_state":hook.state,"hook_target":hook.target,"punch_phase":punch_time,"crouched":crouched,"aim":aim,"creatures":creatures.debug_state()}

func publish_debug()->void:
	if OS.has_feature("web"):
		var snapshot=debug_state();snapshot.player_feet={"x":feet().x,"y":feet().y};snapshot.player_velocity={"x":actor.velocity.x,"y":actor.velocity.y};snapshot.erase("creatures");snapshot.popcorn_count=creatures.grains.size();snapshot.lineup=creatures.lineup;snapshot.aim={"x":aim.x,"y":aim.y}
		JavaScriptBridge.eval("window.__tv_robot_state="+JSON.stringify(snapshot),true)

func _draw()->void:
	draw_rect(Rect2(0,0,1000,700),Color("1d2832"))
	for x in range(0,1000,64):draw_line(Vector2(x,0),Vector2(x,595),Color(0.65,0.76,0.8,0.025),1)
	for y in range(0,595,64):draw_line(Vector2(0,y),Vector2(1000,y),Color(0.65,0.76,0.8,0.025),1)
	draw_rect(Rect2(0,50,1000,10),Color("344b54"));draw_rect(Rect2(8,50,10,545),Color("344b54"));draw_rect(Rect2(982,50,10,545),Color("344b54"));draw_rect(Rect2(0,595,1000,105),Color("364651"));draw_line(Vector2(0,595),Vector2(1000,595),Color("6c838d"),3)
	for box in world.platforms:
		draw_rect(box,Color("354b55"));draw_line(box.position,Vector2(box.end.x,box.position.y),Color("8aa5a8"),3)
		for x in range(int(box.position.x)+12,int(box.end.x),24):draw_rect(Rect2(x,box.position.y+8,3,3),Color("718785"))
	if hook.state!="idle":
		draw_line(robot.gun_hand(),hook.p,Color("a3c7bf"),2,true);draw_circle(hook.p,4,Color("d0ded0"));draw_arc(hook.p,7,0,TAU,20,Color("8fd4b5"),1,true)

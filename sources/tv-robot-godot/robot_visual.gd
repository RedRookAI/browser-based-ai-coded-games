extends Node2D
var velocity=Vector2.ZERO
var grounded=true
var facing=1.0
var crouched=false
var aim=Vector2(650,360)
var punch_phase=-1.0
var ragdoll_active=false
var clock=0.0
var joints={}
var loose_pose={}
const LINKS=[["hips","chest",38],["chest","neck",13],["neck","head",15],["chest","shoulderL",13],["chest","shoulderR",13],["shoulderL","elbowL",27],["shoulderR","elbowR",27],["elbowL","handL",25],["elbowR","handR",25],["hips","hipL",6],["hips","hipR",6],["hipL","kneeL",27],["hipR","kneeR",27],["kneeL","footL",27],["kneeR","footR",27]]

func set_pose(v:Vector2,on_floor:bool,direction:float,crouch:bool,target:Vector2,punch:float,loose:bool,time:float)->void:
	velocity=v;grounded=on_floor;facing=direction;crouched=crouch;aim=target;punch_phase=punch;ragdoll_active=loose;clock=time
	build_pose();queue_redraw()

func build_pose()->void:
	if ragdoll_active&&!loose_pose.is_empty():joints=loose_pose.duplicate();return
	var movement=minf(1,absf(velocity.x)/120)
	var stride=sin(clock*(2+absf(velocity.x)/15))*movement
	var drop=22.0 if crouched&&grounded else 0.0
	var bob=absf(cos(clock*10))*movement*2 if grounded else 0.0
	var hip=Vector2(0,-53+drop-bob);var lean=velocity.x*0.025+(facing*9 if crouched else 0)
	joints={"hips":hip,"chest":hip+Vector2(lean,-38),"neck":hip+Vector2(lean+facing*2,-51),"head":hip+Vector2(lean+facing*3,-66)}
	for side in ["L","R"]:
		var sign_value=-1 if side=="L" else 1
		var swing=stride*sign_value
		joints["hip"+side]=hip+Vector2(sign_value*5,0)
		joints["shoulder"+side]=hip+Vector2(lean+sign_value*11,-38)
		var foot=Vector2(sign_value*5+swing*19,-3-maxf(0,swing)*13) if grounded else Vector2(sign_value*5,-6-(9 if sign_value==1 else 0))
		if crouched&&grounded:foot=Vector2(sign_value*18,-3)
		joints["foot"+side]=foot
		var upper:Vector2=joints["hip"+side];var center=(upper+foot)*0.5
		joints["knee"+side]=center+Vector2(facing*sqrt(maxf(0,27*27-upper.distance_squared_to(foot)*0.25)),0)
		var shoulder:Vector2=joints["shoulder"+side]
		var hand=shoulder+Vector2(-swing*17+facing*2,48-absf(swing)*5)
		if !grounded:hand=shoulder+Vector2(-facing*14+sign_value*9,31)
		if side==("L" if facing>0 else "R"):hand=shoulder+(to_local(aim)-shoulder).normalized()*43
		if side==("R" if facing>0 else "L")&&punch_phase>=0:
			var reach=15.0 if punch_phase<0.045 else lerpf(15,52,(punch_phase-0.045)/0.055) if punch_phase<0.1 else 52.0 if punch_phase<0.19 else lerpf(52,23,(punch_phase-0.19)/0.11)
			hand=shoulder+(to_local(aim)-shoulder).normalized()*reach
		joints["hand"+side]=hand
		var delta=hand-shoulder;var along=(delta.length_squared()+27*27-25*25)/(2*maxf(delta.length(),1))
		joints["elbow"+side]=shoulder+delta.normalized()*along+delta.normalized().orthogonal()*facing*sqrt(maxf(0,27*27-along*along))

func fist()->Vector2:
	return to_global(joints.get("hand"+("R" if facing>0 else "L"),Vector2(30,-80)))
func gun_hand()->Vector2:
	return to_global(joints.get("hand"+("L" if facing>0 else "R"),Vector2(-16,-43)))

func _draw()->void:
	if joints.is_empty():return
	for link in LINKS:
		var a:Vector2=joints[link[0]];var b:Vector2=joints[link[1]]
		draw_line(a,b,Color("11191e"),7,true);draw_line(a,b,Color("aeb6b3"),4,true)
		draw_line(a+Vector2(-1,0),b+Vector2(-1,0),Color("d9ded6"),1,true)
		if "knee" in link[0]||"elbow" in link[0]:draw_line(a+Vector2(3,0),b+Vector2(3,0),Color("bc8eaa"),1,true)
	for id in joints:
		if id in ["head","hips","chest"]:continue
		draw_circle(joints[id],4.5,Color("11191d"));draw_circle(joints[id],3.5,Color("909891"));draw_circle(joints[id],1.5,Color("333d40"))
	for side in ["L","R"]:
		var p:Vector2=joints["foot"+side]
		draw_rect(Rect2(p+Vector2(-8,-7),Vector2(23,11)),Color("b4c4b8"));draw_line(p+Vector2(-8,3),p+Vector2(15,3),Color("2c3d39"),2)
		for i in 3:draw_line(p+Vector2(7,-4+i*2.4),p+Vector2(15-i*1.5,-4+i*2.4),Color("839c8b"),1.5)
		p=joints["hand"+side]
		draw_rect(Rect2(p-Vector2(4,4),Vector2(8,10)),Color("bbc7be"))
		for i in 4:draw_line(p+Vector2(-3+i*2,5),p+Vector2(-3+i*2,10+sin(clock*3+i)),Color("aeb6b3"),1.2)
	var hips:Vector2=joints.hips;var chest:Vector2=joints.chest
	draw_line(hips,chest,Color("202a2b"),5,true)
	for i in 6:
		var p=hips.lerp(chest,i/5.0);draw_line(p-Vector2(4,0),p+Vector2(4,0),Color("c0c0ad"),3,true)
	draw_rect(Rect2(chest+Vector2(-9,7),Vector2(17,16)),Color("405545"));draw_rect(Rect2(chest+Vector2(-4,10),Vector2(7,7)),Color("161e1e"))
	for color_index in 3:
		var offset=(color_index-1)*6.0
		draw_polyline(PackedVector2Array([chest+Vector2(offset,-3),chest.lerp(hips,0.3)+Vector2(offset+6,0),chest.lerp(hips,0.7)+Vector2(offset-5,0),hips+Vector2(offset,0)]),[Color("b684a4"),Color("d2c785"),Color("a7c177")][color_index],1.2,true)
	var p:Vector2=joints.head
	var look=(to_local(aim)-p).normalized()*1.6
	draw_rect(Rect2(p+Vector2(-23,-17),Vector2(47,34)),Color("526361"));draw_rect(Rect2(p+Vector2(-22,-10),Vector2(5,20)),Color("293f40"))
	for i in 5:draw_line(p+Vector2(-22,-7+i*3),p+Vector2(-18,-7+i*3),Color("111f26"),1)
	draw_style_box(screen_style(),Rect2(p+Vector2(-14,-14),Vector2(29,25)))
	for ex in [-5,6]:
		draw_style_box(eye_style(),Rect2(p+Vector2(ex-3,-7),Vector2(6,8)))
		draw_circle(p+Vector2(ex,-3)+look,1.5,Color("173f36"))
	draw_line(p+Vector2(-4,5),p+Vector2(5,5),Color("a5d8b8"),1.3,true)
	for tip in [Vector2(-12,-30),Vector2(7,-29)]:draw_line(p+Vector2(-4,-18),p+tip,Color("9bafa3"),1.6,true);draw_circle(p+tip,2,Color("d1dac5"))
	for cy in [-6,2]:draw_circle(p+Vector2(19,cy),2.8,Color("192b2e"));draw_line(p+Vector2(18,cy-1),p+Vector2(20,cy+1),Color("adbaaa"),0.8)
	draw_circle(p+Vector2(19,10),1.3,Color("b9db91"))
	var hand=to_local(gun_hand());var direction=(to_local(aim)-hand).normalized();var normal=direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([hand-normal*6,hand+direction*25-normal*6,hand+direction*25+normal*6,hand+normal*6]),Color("819e9b"))
	draw_line(hand+direction*18,hand+direction*27,Color("c4d6c5"),4,true)

func screen_style()->StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color("193c3c");style.set_corner_radius_all(5);style.border_color=Color("0d1a1c");style.set_border_width_all(2);return style
func eye_style()->StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color("b7e7c0");style.set_corner_radius_all(2);return style

extends RefCounted
## Fixed logical geometry and collision/path helpers shared by the player and food creatures.
const WIDTH=1000.0
const FLOOR=595.0
const CEILING=60.0
var platforms:Array[Rect2]=[Rect2(420,327.5,160,18)]

func collide(b:Dictionary, radius:float)->Dictionary:
	var p:Vector2=b.p
	var v:Vector2=b.v
	var normal=Vector2.ZERO
	var impact=0.0
	var contacts=[]
	var edges=[{"depth":18+radius-p.x,"n":Vector2.RIGHT,"kind":"left"}, {"depth":p.x-(WIDTH-18-radius),"n":Vector2.LEFT,"kind":"right"}, {"depth":CEILING+radius-p.y,"n":Vector2.DOWN,"kind":"ceiling"}, {"depth":p.y-(FLOOR-radius),"n":Vector2.UP,"kind":"floor"}]
	for edge in edges:
		if edge.depth>0:
			p+=edge.n*edge.depth
			var into=v.dot(edge.n)
			if -into>impact: impact=-into;normal=edge.n
			if into<0:v-=edge.n*into*(1.0+float(b.get("bounce",0.04)))
			contacts.append(edge.kind)
	for box in platforms:
		var near=p.clamp(box.position,box.end)
		var delta=p-near
		var d=delta.length()
		if d>=radius:continue
		var n=Vector2.ZERO
		var depth=radius-d
		if d>0.0001:n=delta/d
		else:
			var sides=[{"d":p.y-box.position.y,"n":Vector2.UP},{"d":box.end.y-p.y,"n":Vector2.DOWN},{"d":p.x-box.position.x,"n":Vector2.LEFT},{"d":box.end.x-p.x,"n":Vector2.RIGHT}]
			sides.sort_custom(func(a,c):return a.d<c.d)
			n=sides[0].n;depth=radius+sides[0].d
		p+=n*depth
		var into=v.dot(n)
		if -into>impact:impact=-into;normal=n
		if into<0:v-=n*into*(1.0+float(b.get("bounce",0.04)))
		contacts.append("platform")
	b.p=p;b.v=v
	return {"normal":normal,"impact":impact,"contacts":contacts}

func move_body(b:Dictionary,delta:Vector2,r:float)->Dictionary:
	var steps=maxi(1,int(ceil(delta.length()/maxf(2.0,r*0.4))))
	var result={"normal":Vector2.ZERO,"impact":0.0,"contacts":[]}
	for i in steps:
		b.p+=delta/steps
		var contact=collide(b,r)
		result.contacts.append_array(contact.contacts)
		if contact.impact>result.impact:result.impact=contact.impact;result.normal=contact.normal
	return result

func clear_line(a:Vector2,b:Vector2,r:float=0.0)->bool:
	for box in platforms:
		var expanded=box.grow(r+2.0)
		if expanded.has_point(a)||expanded.has_point(b):return false
		var enter=0.0
		var exit=1.0
		var delta=b-a
		for axis in 2:
			if absf(delta[axis])<0.000001:
				if a[axis]<expanded.position[axis]||a[axis]>expanded.end[axis]:enter=2.0;break
				continue
			var t1=(expanded.position[axis]-a[axis])/delta[axis]
			var t2=(expanded.end[axis]-a[axis])/delta[axis]
			enter=maxf(enter,minf(t1,t2));exit=minf(exit,maxf(t1,t2))
		if enter<exit&&exit>0&&enter<1:return false
	return true

func route(a:Vector2,b:Vector2,r:float)->Array:
	if clear_line(a,b,r):return [b]
	var points=[a,b]
	for box in platforms:
		var q=box.grow(r+5.0)
		points.append_array([q.position,Vector2(q.end.x,q.position.y),q.end,Vector2(q.position.x,q.end.y)])
	var distances=[];var parent=[];var visited=[]
	for i in points.size():distances.append(INF);parent.append(-1);visited.append(false)
	distances[0]=0.0
	for iteration in points.size():
		var best=-1
		for i in points.size():
			if !visited[i]&&(best<0||distances[i]<distances[best]):best=i
		if best<0||is_inf(distances[best]):break
		if best==1:break
		visited[best]=true
		for j in points.size():
			if j==best||!clear_line(points[best],points[j],r):continue
			var cost=distances[best]+points[best].distance_to(points[j])
			if cost<distances[j]:distances[j]=cost;parent[j]=best
	if is_inf(distances[1]):return []
	var answer=[];var index=1
	while index>0:answer.push_front(points[index]);index=parent[index]
	return answer

func ray_world(a:Vector2,b:Vector2)->Dictionary:
	var direction=(b-a).normalized()
	var best=2500.0
	var hit={}
	var boxes=[Rect2(8,50,10,FLOOR-50),Rect2(WIDTH-18,50,10,FLOOR-50),Rect2(18,50,WIDTH-36,10),Rect2(18,FLOOR,WIDTH-36,10)]
	boxes.append_array(platforms)
	for box in boxes:
		for axis in 2:
			if absf(direction[axis])<0.00001:continue
			for edge in [box.position[axis],box.end[axis]]:
				var t=(edge-a[axis])/direction[axis]
				var p=a+direction*t
				var other=1-axis
				if t>0.01&&t<best&&p[other]>=box.position[other]&&p[other]<=box.end[other]:best=t;hit={"p":p,"distance":t}
	return hit

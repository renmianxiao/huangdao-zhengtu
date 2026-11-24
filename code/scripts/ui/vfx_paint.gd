extends RefCounted
## Painted VFX, soft light and deterministic motes behind the precise hit marks.
static var _textures: Dictionary = {}
static var _glow: Texture2D
const GOLD=Color("f5c86e")
const IVORY=Color("fff1cc")
const CYAN=Color("a9e4ed")
const JADE=Color("8fe2b3")
const PURPLE=Color("be86de")

static func _texture(id: String) -> Texture2D:
	if _textures.has(id): return _textures[id]
	var path := "res://art/vfx/"+id+".png"
	if ResourceLoader.exists(path):
		_textures[id]=load(path) as Texture2D
		return _textures[id]
	return null

static func _light() -> Texture2D:
	if _glow != null: return _glow
	var gradient := Gradient.new()
	gradient.offsets=PackedFloat32Array([0.0,0.12,0.38,0.7,1.0])
	gradient.colors=PackedColorArray([Color(1,1,1,0.9),Color(1,1,1,0.5),Color(1,1,1,0.17),Color(1,1,1,0.035),Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.gradient=gradient
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(0.5,0.5)
	texture.fill_to=Vector2(0.5,0.0)
	texture.width=128;texture.height=128
	_glow=texture
	return _glow

static func _tint(color: Color, opacity: float) -> Color:
	return Color(color.r,color.g,color.b,clampf(color.a*opacity,0,1))

static func _sprite(canvas: Control, texture: Texture2D, center: Vector2, extent: Vector2, angle: float, tint: Color) -> void:
	if texture == null or tint.a<0.005 or extent.x<0.1 or extent.y<0.1: return
	var corners:=PackedVector2Array()
	for corner in [Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]:
		corners.append(center+(corner*extent).rotated(angle))
	canvas.draw_polygon(corners,PackedColorArray([tint]),PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),texture)

static func _halo(canvas: Control, center: Vector2, extent: Vector2, color: Color, opacity: float) -> void:
	_sprite(canvas,_light(),center,extent,0,_tint(color,opacity))

static func _ring(canvas: Control, center: Vector2, radius: float, squash: float, color: Color, opacity: float, angle: float=0.0) -> void:
	var points:=PackedVector2Array()
	for i in range(65):
		var a:=float(i)*TAU/64.0
		points.append(center+(Vector2(cos(a),sin(a)*squash)*radius).rotated(angle))
	canvas.draw_polyline(points,_tint(color,opacity*0.12),7,true)
	canvas.draw_polyline(points,_tint(color,opacity*0.6),1.25,true)

static func _motes(canvas: Control, center: Vector2, phase: float, radius: float, color: Color, count: int=14, rotation: float=0.0, opacity: float=1.0) -> void:
	var envelope:=sin(clampf(phase,0,1)*PI)*opacity
	for i in range(count):
		var seed:=float(i)*2.399963+rotation
		var direction:=Vector2.from_angle(seed)
		var speed:=0.6+float(i%5)*0.14
		var distance: float=(16+radius*pow(phase,0.65))*speed
		var point:=center+Vector2(direction.x*distance,direction.y*distance*0.7+phase*phase*18)
		var mote_alpha:=envelope*(0.55+float(i%3)*0.14)
		var length:=3+float(i%4)*1.3
		canvas.draw_line(point-direction*length,point+direction*length*0.5,_tint(color,mote_alpha*0.7),1.2,true)
		canvas.draw_circle(point,0.8+float(i%3)*0.45,_tint(IVORY,mote_alpha),true,-1,true)
		if i%4==0: _halo(canvas,point,Vector2(16,16),color,mote_alpha*0.4)

static func _burst(canvas: Control, target: Vector2, phase: float, size: float, color: Color=GOLD, opacity: float=1.0) -> void:
	if phase<=0 or phase>1:return
	var fade:=pow(1-phase,1.8)*minf(1,phase*36)
	var scale:=lerpf(0.45,1.18,1-pow(1-phase,3))
	_halo(canvas,target,Vector2(size*1.8,size*1.15),color,fade*0.48*opacity)
	_halo(canvas,target,Vector2.ONE*size*0.38,IVORY,exp(-phase*24)*minf(1,phase*60)*opacity)
	_sprite(canvas,_texture("impact"),target,Vector2(size*scale,size*scale),-0.12+phase*0.16,_tint(Color.WHITE,fade*0.9*opacity))
	_motes(canvas,target,phase,size*0.6,color,16,0.0,opacity)

static func draw(canvas: Control, cue: Dictionary, origin: Vector2, target: Vector2, phase: float, contact: float=0.12) -> void:
	var kind:=str(cue.get("kind","damage"))
	var family:=str(cue.get("family","impact"))
	var power:=clampf(float(cue.get("power",1)),0.35,2.0)
	var accent: Color=cue.get("accent",CYAN)
	var envelope:=sin(phase*PI)
	var attack_size:=174+power*32
	var strength:=0.68+power*0.24
	var hit:=clampf((phase-contact)/maxf(0.01,1.0-contact),0.0,1.0)
	var direction: Vector2=(target-origin).normalized() if origin.distance_squared_to(target)>0.1 else Vector2.RIGHT
	if kind in ["poison_add","poison_apply","poison_consume","poison_tick"]:family="poison"
	if kind=="counter":family="counter"
	match kind:
		"heal":
			_halo(canvas,target,Vector2(170,120),JADE,envelope*0.27)
			_sprite(canvas,_texture("sigil"),target,Vector2(150,100)*(0.8+phase*0.25),phase*0.22,_tint(JADE,envelope*0.6))
			_motes(canvas,target-Vector2(0,phase*30),phase,65,JADE,12)
			return
		"shield","armor_break":
			_halo(canvas,target,Vector2(175,160),GOLD,envelope*0.3)
			_ring(canvas,target,43+phase*30,0.9,GOLD,envelope*0.7,-0.15)
			_motes(canvas,target,phase,78,GOLD,12)
			if kind=="armor_break":_burst(canvas,target,hit,145,GOLD,0.75)
			return
		"buff","enemy_action":
			_halo(canvas,target,Vector2(150,120),GOLD,envelope*0.22)
			_sprite(canvas,_texture("sigil"),target,Vector2(125,100),phase*0.25,_tint(IVORY,envelope*0.45))
			_motes(canvas,target-Vector2(0,phase*24),phase,60,GOLD,10)
			return
		"interrupt":
			_burst(canvas,target,hit,175,Color("f29f75"),0.85)
			return
		"cast":return
	# A restrained contraction leads into the established audio contact cue.
	if phase<contact and family in ["slash","impact","arcane"]:
		var charge:=smoothstep(0.0,contact,phase)
		var color:=accent if family=="arcane" else GOLD
		_halo(canvas,target,Vector2(78,54)*(1.15-charge*0.3),color,charge*0.28*strength)
		_ring(canvas,target,lerpf(43.0,18.0,charge),0.58,color,charge*0.32)
	match family:
		"slash":
			var growth:=1-pow(1-hit,3)
			var fade:=pow(1-hit,1.25)*minf(1,hit*28)*strength
			_halo(canvas,target,Vector2(240,150),GOLD,fade*0.25)
			_sprite(canvas,_texture("slash"),target,Vector2(attack_size*1.32,attack_size*0.95)*(0.75+growth*0.3),-0.28+growth*0.32,_tint(Color.WHITE,fade*0.95))
			_motes(canvas,target,hit,100+power*18,GOLD,12+int(power*4),-0.4,strength)
			_burst(canvas,target,hit,110+power*12,GOLD,0.5*strength)
		"thrust","arrow","needle":
			var arrival:=contact
			var travel:=pow(minf(1,phase/arrival),1.35 if family=="thrust" else (1.2 if family=="needle" else 1.15))
			var head:=origin.lerp(target,travel)
			var width:=60.0 if family=="thrust" else 33.0
			var length:=140.0 if family=="thrust" else 100.0
			var color:=IVORY if family=="needle" else GOLD
			var trail:=envelope*(1.0-smoothstep(arrival,arrival+0.18,phase))
			_halo(canvas,head,Vector2(width*1.7,width*1.2),color,trail*0.65*strength)
			if phase<arrival+0.12:
				var normal:=direction.orthogonal()
				for layer in range(3):
					var spread:=float(3-layer)*2.7
					var points:=PackedVector2Array([head+direction*8,head-direction*length+normal*spread,head-direction*(length+30),head-direction*length-normal*spread])
					canvas.draw_colored_polygon(points,_tint(color,(0.045+float(layer)*0.045)*trail))
				canvas.draw_line(head-direction*length,head,_tint(IVORY,trail*0.85),1.6,true)
			_burst(canvas,target,hit,150 if family!="needle" else 120,color,strength)
		"impact":
			_burst(canvas,target,hit,attack_size,GOLD,strength)
			var ripple:=sin(hit*PI)*(1.0-hit)*strength
			_ring(canvas,target,30+pow(hit,0.6)*(85+power*20),0.5,GOLD,ripple*0.85,0.1)
			_ring(canvas,target,20+pow(hit,0.6)*(95+power*20),0.35,IVORY,ripple*0.38,-0.13)
		"arcane":
			var fire:=accent.r>accent.b*1.18
			var glow:=smoothstep(0.0,contact,phase)*(1.0-smoothstep(0.18,1.0,hit))*strength
			_halo(canvas,target,Vector2(250,200),accent,glow*0.38)
			_sprite(canvas,_texture("impact" if fire else "sigil"),target,Vector2(attack_size,attack_size)*(0.8+hit*0.3),-0.25+phase*0.6,_tint(Color.WHITE,glow*0.9))
			_ring(canvas,target,77+hit*24,0.9,accent,glow*0.5,phase*0.2)
			_motes(canvas,target,hit,125,accent,20,0.0,strength)
			_burst(canvas,target,hit,125,accent,0.55*strength)
		"poison":
			var consume:=kind=="poison_consume"
			var extent: float=lerpf(210.0,110.0,smoothstep(0.0,contact,phase)) if consume else (140+phase*70)
			if kind=="poison_tick":extent*=0.72
			_halo(canvas,target,Vector2(extent*1.15,extent*0.8),PURPLE,envelope*0.24)
			_sprite(canvas,_texture("poison"),target+Vector2(0,-phase*18),Vector2(extent,extent),phase*0.3,_tint(Color.WHITE,envelope*0.85))
			_sprite(canvas,_texture("poison"),target+Vector2(9,-phase*26),Vector2(extent*0.77,extent*0.67),-phase*0.4,_tint(Color.WHITE,envelope*0.3))
			_motes(canvas,target,phase,85,JADE,12)
			if consume:_burst(canvas,target,hit,135,PURPLE,0.75)
		"counter":
			var travel:=minf(1,phase/contact)
			var head:=origin.lerp(target,travel)+direction.orthogonal()*sin(travel*PI)*37
			var trail:=envelope*(1.0-smoothstep(contact,contact+0.2,phase))
			_halo(canvas,head,Vector2(100,85),GOLD,trail*0.65)
			_sprite(canvas,_texture("slash"),head,Vector2(125,100),direction.angle()+phase*2.1,_tint(Color.WHITE,trail*0.85))
			_burst(canvas,target,hit,155,GOLD,strength)

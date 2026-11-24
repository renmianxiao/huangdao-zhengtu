extends Control
var floor_number:=1
var frame: Dictionary={}
var gate: Texture2D
var glow: GradientTexture2D
var vignette: GradientTexture2D
var caption_shade: GradientTexture2D
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var gradient:=Gradient.new();gradient.set_color(0,Color(1,1,1,.6));gradient.set_color(1,Color(1,1,1,0))
	glow=GradientTexture2D.new();glow.gradient=gradient;glow.fill=GradientTexture2D.FILL_RADIAL;glow.fill_from=Vector2(.5,.5);glow.fill_to=Vector2(1,.5);glow.width=128;glow.height=128
	var edge_gradient:=Gradient.new()
	edge_gradient.offsets=PackedFloat32Array([0.0,0.48,1.0])
	edge_gradient.colors=PackedColorArray([Color(0,0,0,0),Color(0,0,0,0),Color(.018,.022,.03,.25 if floor_number==5 else .15)])
	vignette=GradientTexture2D.new();vignette.gradient=edge_gradient;vignette.fill=GradientTexture2D.FILL_RADIAL;vignette.fill_from=Vector2(.5,.46);vignette.fill_to=Vector2(1,.46);vignette.width=256;vignette.height=256
	var shade_gradient:=Gradient.new();shade_gradient.set_color(0,Color(0,0,0,0));shade_gradient.set_color(1,Color(.018,.022,.03,.42))
	caption_shade=GradientTexture2D.new();caption_shade.gradient=shade_gradient;caption_shade.fill_from=Vector2(.5,0);caption_shade.fill_to=Vector2(.5,1);caption_shade.width=4;caption_shade.height=128
func _draw():
	if frame.is_empty() or glow==null:return
	var t: float=frame.elapsed;var w:=size.x;var h:=size.y
	var mist_color: Color=Color(.81,.87,.85,.12 if floor_number==3 else .055)
	if floor_number>=4:mist_color=Color(.65,.59,.63,.055)
	for i in range(4):
		var x: float=fmod(float(i)*.31+t*.018,1.6)-.3
		var y: float=.48+i*.09+sin(t*.2+i)*.018
		draw_texture_rect(glow,Rect2(Vector2(x*w,y*h),Vector2(w*.85,h*.24)),false,mist_color)
	if floor_number in [1,2,3]:
		for i in range(3):
			var x: float=(.08+i*.14)*w
			draw_colored_polygon(PackedVector2Array([Vector2(x,-h*.05),Vector2(x+w*.05,-h*.05),Vector2(x+w*.40,h*.9),Vector2(x+w*.23,h*.9)]),Color(1,.91,.63,.012+.006*sin(t*.7+i)))
	for i in range(34):
		var f:=float(i)
		var x: float=fposmod(f*.618+t*(.021+fmod(f,.7)*.013),1.0)*w
		var y: float=fposmod(f*.371+t*(.014 if floor_number<5 else -.033),1.0)*h
		var color: Color=Color(.95,.84,.52,.22)
		if floor_number==2:
			color=Color(.64,.78,.26,.5)
			color.a*=smoothstep(0.0,.07,x/w)*(1.0-smoothstep(.93,1.0,x/w))*smoothstep(0.0,.06,y/h)*(1.0-smoothstep(.94,1.0,y/h))
			var lean:=sin(t*2+f)*4
			draw_line(Vector2(x-3,y-lean),Vector2(x+3,y+lean),color,maxf(1,w/1600.0))
		else:
			if floor_number==5:color=Color(1,.40,.10,.50)
			color.a*=smoothstep(0.0,.07,x/w)*(1.0-smoothstep(.93,1.0,x/w))*smoothstep(0.0,.06,y/h)*(1.0-smoothstep(.94,1.0,y/h))
			draw_circle(Vector2(x,y),(1.0+fmod(f,2.0))*w/1600.0,color)
	if floor_number==5:
		for x in [.14,.86]:
			var intensity:=.14+.025*sin(t*8.1)+.02*sin(t*13.7)
			draw_texture_rect(glow,Rect2(Vector2((x-.10)*w,.36*h),Vector2(.2*w,.36*h)),false,Color(1,.32,.08,intensity))
	if floor_number in [1,5] and gate!=null:_draw_gate()
	draw_texture_rect(vignette,Rect2(Vector2.ZERO,size),false)
	draw_texture_rect(caption_shade,Rect2(Vector2(0,h*.72),Vector2(w,h*.28)),false,Color(1,1,1,float(frame.title)*.75))
func _draw_gate():
	var w:=size.x;var h:=size.y;var opening: float=frame.open;var travel: float=(float(frame.near_zoom)-1.06)*.16
	var outer: float=-.08*w-travel*w
	# Subpixel overlap seals the join until the opening is visibly underway.
	var width: float=(.58*w)*(1.0-opening*.90)+1.0*(1.0-smoothstep(0.0,.08,opening))
	var inset: float=opening*h*.035
	var tint: Color=Color(.44,.49,.63,1) if floor_number==5 else Color(.79,.75,.65,1)
	var left:=PackedVector2Array([Vector2(outer,-.03*h),Vector2(outer+width,inset),Vector2(outer+width,h-inset),Vector2(outer,1.03*h)])
	var right:=PackedVector2Array([Vector2(w-outer-width,inset),Vector2(w-outer,-.03*h),Vector2(w-outer,1.03*h),Vector2(w-outer-width,h-inset)])
	draw_polygon(left,PackedColorArray([tint]),PackedVector2Array([Vector2(0,0),Vector2(.5,0),Vector2(.5,1),Vector2(0,1)]),gate)
	draw_polygon(right,PackedColorArray([tint]),PackedVector2Array([Vector2(.5,0),Vector2(1,0),Vector2(1,1),Vector2(.5,1)]),gate)

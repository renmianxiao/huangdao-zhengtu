extends Control
signal character_requested(id:String)
signal relic_requested(id:String)
signal new_requested
signal menu_requested
const Paper=preload("res://code/scripts/ui/global_theme.gd")
const Characters=preload("res://code/scripts/characters/character_catalog.gd")
const Relics=preload("res://code/scripts/relics/relic_catalog.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const Colors=preload("res://code/scripts/ui/character_card_colors.gd")
const Professions=preload("res://code/scripts/profession_names.gd")
const Run=preload("res://code/scripts/run/run_rules.gd")
const ItemArt=preload("res://code/scripts/ui/item_artwork.gd")
var state:Dictionary={}
var character_buttons:Dictionary={}
var relic_buttons:Dictionary={}
var grids:Array[GridContainer]=[]
var column:VBoxContainer
var title:Label
var overview:Label
var resources:Label
var tabs:TabContainer
func _ready():
 theme=Paper.make(17)
 column=VBoxContainer.new();column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 column.add_theme_constant_override("separation",12);add_child(column)
 var heading:=HBoxContainer.new();column.add_child(heading)
 title=_label(heading,"远征结算",34);title.size_flags_horizontal=SIZE_EXPAND_FILL
 title.add_theme_color_override("font_color",Paper.RED)
 var seal:=_label(heading,"黄道征途 · 本局行迹",18);seal.autowrap_mode=TextServer.AUTOWRAP_OFF;seal.custom_minimum_size.x=240;seal.add_theme_color_override("font_color",Paper.GOLD);seal.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var line:=HSeparator.new();column.add_child(line)
 overview=_label(column,"",20);overview.name="Overview"
 resources=_label(column,"",17);resources.name="Resources";resources.add_theme_color_override("font_color",Paper.MUTED)
 tabs=TabContainer.new();tabs.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(tabs)
 var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_END;actions.add_theme_constant_override("separation",16);column.add_child(actions)
 var menu:=Button.new();menu.text="返回主菜单";menu.custom_minimum_size=Vector2(170,48);menu.pressed.connect(func():menu_requested.emit());actions.add_child(menu)
 var again:=Button.new();again.text="开始新远征";again.custom_minimum_size=Vector2(190,48);Paper.primary(again);again.pressed.connect(func():new_requested.emit());actions.add_child(again)
 resized.connect(_layout)
func _label(parent:Node,text:String,font_size:int)->Label:
 var value:=Label.new();value.text=text;value.add_theme_font_size_override("font_size",font_size);value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(value);return value
static func duration(seconds:float)->String:
 var total:=maxi(0,int(seconds))
 return "%02d:%02d:%02d"%[total/3600,(total/60)%60,total%60]
func configure(value:Dictionary):
 state=value.duplicate(true)
 title.text={"won":"远征通关","lost":"远征战败","abandoned":"远征已放弃"}.get(state.phase,"远征结算")
 var wins:Dictionary=state.get("battle_wins",{})
 var won:=0
 for count in wins.values():won+=int(count)
 overview.text="本局时长  %s    抵达第 %d / 5 层    完成节点 %d    战斗胜场 %d / %d"%[duration(float(state.get("run_seconds",0))),Run.current_node(state).get("floor",1),state.completed.size(),won,state.battles]
 resources.text="最终等级 %d   累计经验 %d   累计获得金币 %d   剩余金币 %d   剩余声望 %d\n普通胜场 %d   精英胜场 %d   道中首领 %d   最终首领 %d"%[state.level,state.total_experience,state.get("earned_gold",0),state.gold,state.renown,wins.get("battle",0),wins.get("elite",0),wins.get("midboss",0),wins.get("boss",0)]
 for child in tabs.get_children():tabs.remove_child(child);child.queue_free()
 grids.clear();character_buttons.clear();relic_buttons.clear()
 var roster:GridContainer=_page("招募角色  %d"%state.roster.size(),"本局尚未招募角色。",state.roster.is_empty())
 for raw in state.roster:
  var id:=str(raw);var leader:Dictionary=Characters.leader(id)
  if leader.is_empty():continue
  var b:=_card(roster,load("res://art/characters/"+id+".png"),str(leader.name),Professions.label(str(leader["class"]))+(" · 已强化" if Growth.is_upgraded(state,id) else ""),true)
  Colors.button(b,id,false,Growth.is_upgraded(state,id));b.pressed.connect(func():character_requested.emit(id));character_buttons[id]=b
 var ids:=Relics.ids(state)
 var relics:GridContainer=_page("获得藏品  %d"%ids.size(),"本局尚未获得藏品。",ids.is_empty())
 for raw in ids:
  var id:=str(raw);var item:Dictionary=Relics.definition(id)
  if item.is_empty():continue
  var b:=_card(relics,load(str(item.icon)),str(item.name),"%s · %d 金币档"%[item.category,item.price],false)
  b.tooltip_text=Professions.text(str(item.effect));b.pressed.connect(func():relic_requested.emit(id));relic_buttons[id]=b
 _layout.call_deferred()
func _page(text:String,empty:String,is_empty:bool)->GridContainer:
 var scroll:=ScrollContainer.new();scroll.name=text;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;tabs.add_child(scroll)
 var content:=VBoxContainer.new();content.size_flags_horizontal=SIZE_EXPAND_FILL;scroll.add_child(content)
 if is_empty:_label(content,empty,20)
 var grid:=GridContainer.new();grid.size_flags_horizontal=SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);content.add_child(grid);grids.append(grid);return grid
func _card(parent:Node,texture:Texture2D,text:String,meta:String,portrait:bool)->Button:
 var b:=Button.new();b.custom_minimum_size=Vector2(160,252 if portrait else 180);b.size_flags_horizontal=SIZE_EXPAND_FILL;parent.add_child(b)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,10)
 b.add_child(margin);margin.mouse_filter=MOUSE_FILTER_IGNORE
 var stack:=VBoxContainer.new();stack.mouse_filter=MOUSE_FILTER_IGNORE;margin.add_child(stack)
 var art:TextureRect=TextureRect.new() if portrait else ItemArt.new()
 if portrait:art.texture=texture
 else:art.set_art(texture.resource_path)
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.size_flags_vertical=SIZE_EXPAND_FILL;art.mouse_filter=MOUSE_FILTER_IGNORE;stack.add_child(art)
 var caption:=_label(stack,text,20);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.mouse_filter=MOUSE_FILTER_IGNORE
 var note:=_label(stack,meta,15);note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.mouse_filter=MOUSE_FILTER_IGNORE
 b.tooltip_text=text+"\n"+meta+"\n点击查看详情"
 return b
func _layout():
 for grid in grids:grid.columns=maxi(1,int((size.x-48)/185.0))

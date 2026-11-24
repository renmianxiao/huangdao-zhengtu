extends Control
const CardColors=preload("res://code/scripts/ui/character_card_colors.gd")
## Fullscreen read-only reference; the owning run screen controls input shielding.
signal closed
const Catalog=preload("res://code/scripts/encyclopedia/catalog.gd")
const Profile=preload("res://code/scripts/encyclopedia/profile.gd")
const Paper=preload("res://code/scripts/ui/global_theme.gd")
var kind:="characters"
var selected_id:=""
var run_state: Dictionary={}
var history: Dictionary={}
var visible_ids: Array=[]
var page_states: Dictionary={}
var jumps: Array=[]
var _updating:=false
var _rows: Array=[]
var search: LineEdit
var category_select: OptionButton
var number_select: OptionButton
var record_select: OptionButton
var row_select: OptionButton
var growth_button: CheckButton
var list_scroll: ScrollContainer
var tile_grid: GridContainer
var tiles: Dictionary={}
var progress_bar: ProgressBar
var summary_label: Label
var empty_label: Label
var status_label: Label
var title_label: Label
var meta_label: Label
var detail_text: RichTextLabel
var detail_panel: PanelContainer
var art_button
var back_button: Button
var zoom: PanelContainer
var zoom_art: TextureRect
var links: HFlowContainer
var link_buttons: Array[Button]=[]
var tabs: Dictionary={}
var notice: Label
var heading_count: Label
var lead_title: Label
var lead_label: Label
const Tile=preload("res://code/scripts/ui/encyclopedia_tile.gd")
const Hero=preload("res://code/scripts/ui/encyclopedia_hero.gd")
const SceneArt=preload("res://code/scripts/ui/scene_art.gd")
## Tile footprint per page: portraits stand tall, battle paintings run wide.
const TILE_SIZES={"characters":Vector2(148,196),"monsters":Vector2(214,150),"relics":Vector2(136,160),"events":Vector2(200,150)}

func _label(parent: Node,text: String,font_size: int=18) -> Label:
 var value:=Label.new();value.text=text;value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 value.custom_minimum_size.x=1;value.add_theme_font_size_override("font_size",font_size);parent.add_child(value);return value

func _ready():
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 mouse_filter=MOUSE_FILTER_STOP;theme=Paper.make_dark(18)
 var background=preload("res://code/scripts/ui/paper_backdrop.gd").new();background.dark=true;background.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(background)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,22)
 add_child(margin)
 var page:=VBoxContainer.new();page.add_theme_constant_override("separation",10);margin.add_child(page)
 var head:=HBoxContainer.new();head.add_theme_constant_override("separation",16);page.add_child(head)
 var heading:=_label(head,"江湖见闻录",40);heading.add_theme_font_override("font",Paper.title_font());heading.add_theme_color_override("font_color",Paper.DARK_TEXT)
 heading.size_flags_horizontal=SIZE_SHRINK_BEGIN;heading.autowrap_mode=TextServer.AUTOWRAP_OFF
 heading_count=_label(head,"",16);heading_count.add_theme_color_override("font_color",Paper.OLD_GOLD);heading_count.size_flags_horizontal=SIZE_EXPAND_FILL;heading_count.size_flags_vertical=SIZE_SHRINK_CENTER
 back_button=Button.new();back_button.text="返回";back_button.custom_minimum_size=Vector2(100,42);back_button.size_flags_vertical=SIZE_SHRINK_CENTER;back_button.pressed.connect(handle_back);head.add_child(back_button)
 var rule:=ColorRect.new();rule.color=Color(Paper.OLD_GOLD,0.6);rule.custom_minimum_size.y=1;rule.mouse_filter=MOUSE_FILTER_IGNORE;page.add_child(rule)
 var tab_row:=HBoxContainer.new();tab_row.add_theme_constant_override("separation",10);page.add_child(tab_row)
 for key: String in Catalog.TITLES:
  var tab:=Button.new();tab.text=Catalog.TITLES[key];tab.toggle_mode=true;tab.custom_minimum_size.y=44;tab.size_flags_horizontal=SIZE_EXPAND_FILL
  tab_row.add_child(tab);tab.pressed.connect(select_kind.bind(key));tabs[key]=tab
 var main:=HBoxContainer.new();main.add_theme_constant_override("separation",16);main.size_flags_vertical=SIZE_EXPAND_FILL;page.add_child(main)
 var left:=VBoxContainer.new();left.add_theme_constant_override("separation",8);left.size_flags_horizontal=SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=1.0;left.custom_minimum_size.x=300;main.add_child(left)
 search=LineEdit.new();search.placeholder_text="搜索名称";search.custom_minimum_size.y=38;left.add_child(search);search.text_changed.connect(func(_text):if not _updating:_rebuild())
 var filters:=HBoxContainer.new();filters.add_theme_constant_override("separation",6);left.add_child(filters)
 category_select=OptionButton.new();number_select=OptionButton.new();record_select=OptionButton.new()
 for filter: OptionButton in [category_select,number_select,record_select]:
  filter.size_flags_horizontal=SIZE_EXPAND_FILL;filter.custom_minimum_size=Vector2(1,36);filter.clip_text=true;filters.add_child(filter)
  filter.item_selected.connect(func(_index):if not _updating:_rebuild())
 var summary_row:=HBoxContainer.new();summary_row.add_theme_constant_override("separation",10);left.add_child(summary_row)
 summary_label=_label(summary_row,"全部资料开放",15);summary_label.add_theme_color_override("font_color",Paper.DARK_MUTED);summary_label.autowrap_mode=TextServer.AUTOWRAP_OFF
 progress_bar=ProgressBar.new();progress_bar.show_percentage=false;progress_bar.custom_minimum_size=Vector2(80,6);progress_bar.size_flags_horizontal=SIZE_EXPAND_FILL;progress_bar.size_flags_vertical=SIZE_SHRINK_CENTER
 var track:=Paper.box(Color("1a1d1d"),Color("4e483b"));track.set_content_margin_all(0);progress_bar.add_theme_stylebox_override("background",track)
 var fill:=Paper.box(Paper.OLD_GOLD,Color.TRANSPARENT);fill.set_content_margin_all(0);progress_bar.add_theme_stylebox_override("fill",fill)
 summary_row.add_child(progress_bar)
 var list_area:=PanelContainer.new();list_area.size_flags_vertical=SIZE_EXPAND_FILL
 var well:=Paper.box(Color(0.07,0.08,0.08,0.55),Color("4e483b"));well.set_content_margin_all(8);list_area.add_theme_stylebox_override("panel",well);left.add_child(list_area)
 # Allow the viewport to shrink independently of the previous tile minima.
 # _layout fits each row to the viewport; no horizontal bar is needed.
 list_scroll=ScrollContainer.new();list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;list_scroll.follow_focus=true;list_area.add_child(list_scroll)
 tile_grid=GridContainer.new();tile_grid.size_flags_horizontal=SIZE_EXPAND_FILL;tile_grid.add_theme_constant_override("h_separation",10);tile_grid.add_theme_constant_override("v_separation",10);list_scroll.add_child(tile_grid)
 list_scroll.resized.connect(_layout)
 empty_label=_label(list_area,"没有符合条件的条目\n可清空搜索或调整筛选",19);empty_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty_label.mouse_filter=MOUSE_FILTER_IGNORE;empty_label.add_theme_color_override("font_color",Paper.DARK_MUTED)
 detail_panel=PanelContainer.new();detail_panel.size_flags_horizontal=SIZE_EXPAND_FILL;detail_panel.size_flags_stretch_ratio=1.05;detail_panel.custom_minimum_size.x=320;main.add_child(detail_panel)
 var detail:=VBoxContainer.new();detail.add_theme_constant_override("separation",0);detail_panel.add_child(detail)
 var hero:=Hero.new();hero.size_flags_vertical=SIZE_EXPAND_FILL;hero.size_flags_stretch_ratio=1.0;hero.custom_minimum_size.y=230;detail.add_child(hero);art_button=hero
 hero.art_clicked.connect(open_art)
 title_label=_label(hero.info,"选择条目",34);title_label.add_theme_font_override("font",Paper.title_font());title_label.add_theme_color_override("font_color",Paper.DARK_TEXT)
 meta_label=_label(hero.info,"",15);meta_label.add_theme_color_override("font_color",Paper.OLD_GOLD)
 status_label=_label(hero.info,"",15);status_label.add_theme_color_override("font_color",Color("9cc2b4"))
 # Relics and events lead with their effect or story in the stage's open space.
 var lead_gap:=Control.new();lead_gap.custom_minimum_size.y=6;hero.info.add_child(lead_gap)
 lead_title=_label(hero.info,"",14);lead_title.add_theme_color_override("font_color",Paper.OLD_GOLD)
 lead_label=_label(hero.info,"",19);lead_label.add_theme_color_override("font_color",Paper.DARK_TEXT);lead_label.add_theme_constant_override("line_spacing",6)
 var toggles:=HBoxContainer.new();toggles.add_theme_constant_override("separation",8);hero.info.add_child(toggles)
 growth_button=CheckButton.new();growth_button.text="强化后";toggles.add_child(growth_button);growth_button.toggled.connect(func(_pressed):if not _updating:_show_detail())
 row_select=OptionButton.new()
 for i in range(6):row_select.add_item("层内第 %d 排"%(i+1))
 toggles.add_child(row_select);row_select.item_selected.connect(func(_index):if not _updating:_show_detail())
 # Notes sit on a light paper scroll under the stage, the only light surface on the page.
 var notes:=PanelContainer.new();notes.size_flags_vertical=SIZE_EXPAND_FILL;notes.size_flags_stretch_ratio=0.95;notes.custom_minimum_size.y=150;notes.theme=Paper.make(17)
 var paper_style:=Paper.box(Paper.PANEL,Paper.GOLD);paper_style.content_margin_left=18;paper_style.content_margin_right=12;paper_style.content_margin_top=14;paper_style.content_margin_bottom=12
 notes.add_theme_stylebox_override("panel",Paper.ornate(paper_style));detail.add_child(notes)
 var scroller:=ScrollContainer.new();scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;notes.add_child(scroller)
 var content:=VBoxContainer.new();content.size_flags_horizontal=SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",10);scroller.add_child(content)
 detail_text=RichTextLabel.new();detail_text.fit_content=true;detail_text.scroll_active=false;detail_text.selection_enabled=true;detail_text.size_flags_horizontal=SIZE_EXPAND_FILL;detail_text.custom_minimum_size.x=1;detail_text.add_theme_constant_override("line_separation",5);content.add_child(detail_text)
 links=HFlowContainer.new();links.add_theme_constant_override("h_separation",8);links.add_theme_constant_override("v_separation",8);content.add_child(links)
 notice=_label(page,"全部条目均可查阅；见闻跨远征保留。右键 / Esc 返回。",14);notice.add_theme_color_override("font_color",Paper.DARK_MUTED)
 zoom=PanelContainer.new();zoom.set_anchors_and_offsets_preset(PRESET_FULL_RECT);zoom.add_theme_stylebox_override("panel",Paper.box(Color("191c1d"),Paper.OLD_GOLD));add_child(zoom)
 var zoom_column:=VBoxContainer.new();zoom.add_child(zoom_column)
 var close_zoom:=Button.new();close_zoom.text="收起立绘 · 右键 / Esc";close_zoom.custom_minimum_size.y=44;zoom_column.add_child(close_zoom);close_zoom.pressed.connect(func():zoom.hide();back_button.grab_focus())
 zoom_art=TextureRect.new();zoom_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;zoom_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;zoom_art.size_flags_vertical=SIZE_EXPAND_FILL;zoom_column.add_child(zoom_art);zoom.hide()
 resized.connect(_layout);_layout.call_deferred()

func configure(run: Dictionary,profile: Dictionary,message: String=""):
 run_state=run.duplicate(true);history=profile.duplicate(true)
 if _rows.is_empty():select_kind(kind)
 else:_rebuild(true)
 notice.text=message if not message.is_empty() else "全部条目均可查阅；见闻跨远征保留。右键 / Esc 返回。"
 back_button.grab_focus()

func _layout():
 if tile_grid==null:return
 var width:=list_scroll.size.x-14
 var base:Vector2=TILE_SIZES.get(kind,Vector2(150,180))
 var gap:=10
 var columns:=maxi(1,int((width+gap)/(base.x+gap)))
 tile_grid.columns=columns
 var tile_width:=floorf((width-gap*(columns-1))/columns)
 var tile_size:=Vector2(tile_width,roundf(base.y*clampf(tile_width/base.x,0.9,1.25)))
 for id in tiles:tiles[id].custom_minimum_size=tile_size

func _remember():
 if search==null:return
 page_states[kind]={"query":search.text,"category":category_select.selected,"number":number_select.selected,"record":record_select.selected,"selected":selected_id,"scroll":list_scroll.scroll_vertical,"growth":growth_button.button_pressed,"row":row_select.selected}

func select_kind(value: String):
 if not Catalog.TITLES.has(value):return
 _remember();kind=value;_rows=Catalog.entries(kind);_updating=true
 var prior: Dictionary=page_states.get(kind,{})
 search.text=prior.get("query","")
 category_select.clear();category_select.add_item("全部分类");var categories: Array=[]
 for entry: Dictionary in _rows:
  if not entry.category in categories:categories.append(entry.category);category_select.add_item(entry.category)
 number_select.clear();number_select.add_item("全部声望" if kind=="characters" else ("全部价格" if kind=="relics" else "全部楼层"))
 if kind=="characters":
  for cost in [0,1,3]:number_select.add_item("%d 声望"%cost,cost)
 elif kind=="relics":
  for cost in [8,12,16]:number_select.add_item("%d 金币"%cost,cost)
 elif kind=="monsters":
  for floor_number in range(1,6):number_select.add_item("第 %d 层"%floor_number,floor_number)
 number_select.visible=kind!="events"
 record_select.clear()
 var labels: Array=["全部记录","已记录","未记录"]
 if kind=="characters":labels=["全部记录","曾招募","未招募"]
 elif kind=="relics":labels=["全部记录","曾获得","未获得"]
 elif kind=="monsters":labels=["全部记录","已遭遇","未遭遇","已击败"]
 else:labels=["全部记录","已遭遇","未遭遇"]
 for text: String in labels:record_select.add_item(text)
 category_select.select(clampi(int(prior.get("category",0)),0,category_select.item_count-1));number_select.select(clampi(int(prior.get("number",0)),0,number_select.item_count-1));record_select.select(clampi(int(prior.get("record",0)),0,record_select.item_count-1))
 growth_button.set_pressed_no_signal(prior.get("growth",false));row_select.select(prior.get("row",0));selected_id=prior.get("selected","")
 _updating=false
 _style_tabs()
 _rebuild()
 list_scroll.set_deferred("scroll_vertical",int(prior.get("scroll",0)))

func _recorded(id: String,page: String="") -> bool:
 return history.get({"characters":"recruited","relics":"relics","monsters":"seen","events":"events"}[page if not page.is_empty() else kind],{}).has(id)

func _stamp(id: String) -> String:
 if kind=="monsters" and history.get("defeated",{}).has(id):return "已击败"
 return {"characters":"曾招募","relics":"曾获得","monsters":"已遭遇","events":"已遭遇"}[kind] if _recorded(id) else "未记录"

## Events use their own painting when one exists, otherwise their emblem relic.
func _art_path(entry: Dictionary) -> String:
 if kind=="events":
  var scene:=_event_painting(str(entry.id))
  if not scene.is_empty():return scene
  return SceneArt.event_emblem(str(entry.id),str(entry.art))
 return str(entry.art)

func _event_painting(id: String) -> String:
 return SceneArt.illustration("event",id,str(Catalog.Events.EVENTS.get(id,{}).get("category","")))

## An emblem-only event sits over a dimmed scene matching its story.
func _backdrop(id: String) -> Texture2D:
 if kind!="events" or not _event_painting(id).is_empty():return null
 return load(SceneArt.event_scene(id)) as Texture2D

## Selected tab is a vermilion seal with gilt trim; others are ink plates; each shows its progress.
func _style_tabs():
 for key: String in tabs:
  var tab: Button=tabs[key];var active:=key==kind
  tab.set_pressed_no_signal(active)
  var found:=0;var rows:=Catalog.entries(key)
  for entry: Dictionary in rows:if _recorded(entry.id,key):found+=1
  tab.text="%s   %d / %d"%[Catalog.TITLES[key],found,rows.size()]
  for state in ["normal","hover","pressed","focus"]:
   var face:=Paper.box(Paper.RED if active else (Color("383b37") if state=="hover" else Color("2a2e2f")),Color("c9a46a") if active or state=="hover" else Color("5d5546"))
   tab.add_theme_stylebox_override(state,Paper.trimmed(face) if active else face)
  for color in ["font_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:tab.add_theme_color_override(color,Color("fff1d6") if active else Paper.DARK_MUTED)
  tab.add_theme_font_size_override("font_size",18)

func _rebuild(preserve_scroll: bool=false):
 var offset:=list_scroll.scroll_vertical
 for child in tile_grid.get_children():tile_grid.remove_child(child);child.queue_free()
 tiles.clear();visible_ids.clear()
 var count:=0
 for entry: Dictionary in _rows:
  if _recorded(entry.id):count+=1
  if not search.text.strip_edges().is_empty() and not str(entry.name).containsn(search.text.strip_edges()):continue
  if category_select.selected>0 and entry.category!=category_select.get_item_text(category_select.selected):continue
  if number_select.visible and number_select.selected>0 and int(entry.get("floor" if kind=="monsters" else "cost",-1))!=number_select.get_selected_id():continue
  if record_select.selected==1 and not _recorded(entry.id):continue
  if record_select.selected==2 and _recorded(entry.id):continue
  if record_select.selected==3 and not history.get("defeated",{}).has(entry.id):continue
  visible_ids.append(entry.id)
  var tile:=Tile.new();var id:=str(entry.id)
  var caption:=str(entry.category)
  if kind=="characters":caption="%s · %d 声望"%[entry.category,entry.cost]
  elif kind=="relics":caption="%s · %d 金币"%[entry.category,entry.cost]
  elif kind=="monsters":caption="第 %d 层 · %s"%[entry.floor,_stamp(id)]
  tile.configure(kind,{"id":id,"name":entry.name,"caption":caption,"stamp":_stamp(id),"recorded":_recorded(id),"badge":entry.category if kind=="monsters" else "","texture":load(_art_path(entry)),"backdrop":_backdrop(id)})
  tile.pressed.connect(select_entry.bind(id));tile_grid.add_child(tile);tiles[id]=tile
 summary_label.text="显示 %d / %d    见闻 %d / %d"%[visible_ids.size(),_rows.size(),count,_rows.size()]
 progress_bar.max_value=maxi(1,_rows.size());progress_bar.value=count
 heading_count.text="%s · 已录 %d / %d"%[Catalog.TITLES[kind],count,_rows.size()]
 empty_label.visible=visible_ids.is_empty()
 if not selected_id in visible_ids:selected_id=str(visible_ids[0]) if not visible_ids.is_empty() else ""
 _show_detail();_layout.call_deferred()
 if preserve_scroll:list_scroll.set_deferred("scroll_vertical",offset)

func select_entry(id: String):
 if not id in visible_ids:return
 selected_id=id;_show_detail()
 if tiles.has(id) and not tiles[id].has_focus():list_scroll.ensure_control_visible.call_deferred(tiles[id])

func _show_detail():
 for child in links.get_children():links.remove_child(child);child.queue_free()
 link_buttons.clear()
 var info:=Catalog.detail(kind,selected_id,growth_button.button_pressed,row_select.selected+1)
 var has_entry:=not info.is_empty()
 var frame:=Paper.box(Color("1b1f20"),CardColors.edge(selected_id,true) if kind=="characters" and has_entry else Paper.OLD_GOLD);frame.set_content_margin_all(3)
 detail_panel.add_theme_stylebox_override("panel",CardColors.framed(frame,selected_id,true) if kind=="characters" and has_entry else Paper.ornate(frame,true))
 for id in tiles:tiles[id].selected=id==selected_id
 growth_button.visible=has_entry and kind=="characters";row_select.visible=has_entry and kind=="monsters" and info.category in ["普通","精英"]
 var art_path:=_art_path({"id":selected_id,"art":info.get("art","")}) if has_entry else ""
 art_button.show_entry(kind,selected_id,load(art_path) as Texture2D if has_entry else null,_backdrop(selected_id) if has_entry else null)
 title_label.text=info.get("name","没有符合条件的条目");meta_label.text=info.get("meta","");detail_text.text=info.get("text","");status_label.text=""
 var lead:=""
 if has_entry and kind=="relics":lead=str(Catalog.Relics.definition(selected_id).effect);lead_title.text="效果"
 elif has_entry and kind=="events":lead=str(Catalog.Events.EVENTS[selected_id].story);lead_title.text="缘起"
 lead_label.text=lead;lead_title.visible=not lead.is_empty();lead_label.visible=not lead.is_empty()
 # The notes scroll keeps everything else; the lead is not repeated there.
 for prefix in ["效果
%s

"%lead,"%s

"%lead]:
  if not lead.is_empty() and detail_text.text.begins_with(prefix):detail_text.text=detail_text.text.substr(prefix.length());break
 if not has_entry:return
 status_label.text="◆ "+_stamp(selected_id)
 if kind=="characters" and run_state.get("roster",[]).has(selected_id):status_label.text+="    本局已强化" if run_state.get("character_upgrades",{}).get(selected_id,false) else "    本局已招募"
 if kind=="relics" and run_state.get("relics",[]).has(selected_id):status_label.text+="    本局持有"
 if kind=="events":
  var chosen: Dictionary=history.get("branches",{}).get(selected_id,{})
  var names: Array[String]=[]
  for action: String in chosen:names.append(str(Catalog.branches(selected_id).get(action,action)))
  if not names.is_empty():detail_text.text+="\n\n已选择过的分支\n"+"\n".join(names)
 for link: Dictionary in info.get("links",[]):
  var button:=Button.new();button.text=link.name;button.custom_minimum_size=Vector2(110,36);links.add_child(button);link_buttons.append(button)
  button.pressed.connect(_jump.bind(link.kind,link.id))
 # Detail changes should start at the first line; list scroll is independent.
 var scroll:=links.get_parent().get_parent() as ScrollContainer
 scroll.scroll_vertical=0
 art_button.layout_info.call_deferred()

func _jump(target_kind: String,id: String):
 _remember();jumps.append({"kind":kind,"state":page_states[kind].duplicate(true)})
 select_kind(target_kind);_updating=true;search.clear();category_select.select(0);number_select.select(0);record_select.select(0);_updating=false;_rebuild();select_entry(id)

func open_art():
 if art_button.texture==null:return
 CardColors.panel(zoom,selected_id if kind=="characters" else "",true)
 zoom_art.texture=art_button.texture;zoom.show();back_button.release_focus()

func handle_back():
 if zoom.visible:zoom.hide();back_button.grab_focus();return
 if not jumps.is_empty():
  var previous: Dictionary=jumps.pop_back();page_states[previous.kind]=previous.state
  # Avoid overwriting the saved page when returning to a link source.
  kind="";select_kind(previous.kind);return
 _remember();closed.emit()


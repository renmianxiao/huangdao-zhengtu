extends RefCounted
## Persistent set-based discoveries, intentionally outside the three run slots.
const Catalog=preload("res://code/scripts/encyclopedia/catalog.gd")
const ROOT="user://encyclopedia"
const SETS=["recruited","relics","seen","defeated","events"]
const KINDS={"recruited":"characters","relics":"relics","seen":"monsters","defeated":"monsters","events":"events"}
const MAX_BYTES=262144

static func empty() -> Dictionary:
 return {"version":1,"recruited":{},"relics":{},"seen":{},"defeated":{},"events":{},"branches":{}}

static func known(kind: String,id: String) -> bool:
 for item: Dictionary in Catalog.entries(kind):
  if item.id==id:return true
 return false

static func valid(value: Variant) -> bool:
 if not value is Dictionary or value.size()!=7 or not value.get("version") is int or value.version!=1:return false
 for key: String in SETS:
  if not value.get(key) is Dictionary or value[key].size()>100:return false
  for id in value[key]:
   if not id is String or not value[key][id] is bool or not value[key][id] or not known(KINDS[key],id):return false
 if not value.get("branches") is Dictionary or value.branches.size()>12:return false
 for id in value.branches:
  if not id is String or not known("events",id) or not value.branches[id] is Dictionary:return false
  var allowed:=Catalog.branches(id)
  for action in value.branches[id]:
   if not allowed.has(action) or not value.branches[id][action] is bool or not value.branches[id][action]:return false
 return true

static func observe(profile: Dictionary,run: Dictionary) -> Dictionary:
 var next:=profile.duplicate(true)
 if not (run.get("phase","")=="formation" and str(run.get("current_node","")).is_empty()):
  var owned: Array=run.get("team",run.get("roster",[])) if str(run.get("current_node","")).is_empty() else run.get("roster",[])
  for id in owned:
   if known("characters",str(id)):next.recruited[id]=true
 for id in run.get("relics",[]):
  if known("relics",str(id)):next.relics[id]=true
 var event: String=str(run.get("node_state",{}).get("event",""))
 if known("events",event):next.events[event]=true
 if run.get("phase","")=="battle":
  var enemy: String=str(run.get("encounter",{}).get("config",{}).get("enemy_id",""))
  if known("monsters",enemy):next.seen[enemy]=true
 return next

static func mark_battle(profile: Dictionary,id: String,won: bool) -> Dictionary:
 var next:=profile.duplicate(true)
 if known("monsters",id):
  next.seen[id]=true
  if won:next.defeated[id]=true
 return next

static func choose(profile: Dictionary,id: String,action: String) -> Dictionary:
 var next:=profile.duplicate(true)
 if not known("events",id) or not Catalog.branches(id).has(action):return next
 next.events[id]=true
 if not next.branches.has(id):next.branches[id]={}
 next.branches[id][action]=true
 return next

static func _read(path: String) -> Variant:
 if not FileAccess.file_exists(path):return null
 var file:=FileAccess.open(path,FileAccess.READ)
 if file==null or file.get_length()>MAX_BYTES:return null
 var parser:=JSON.new()
 if parser.parse(file.get_as_text())!=OK:return null
 var data: Variant=parser.data
 if data is Dictionary and (data.get("version") is int or data.get("version") is float) and data.version==1:data.version=1
 return data

static func load_profile(directory: String=ROOT) -> Dictionary:
 var path:=directory.path_join("profile.json")
 for suffix in ["",".bak"]:
  var data: Variant=_read(path+suffix)
  if valid(data):return {"ok":true,"data":data,"recovered":not suffix.is_empty(),"message":"已从备份恢复图鉴记录" if not suffix.is_empty() else ""}
 var missing:=not FileAccess.file_exists(path) and not FileAccess.file_exists(path+".bak")
 return {"ok":missing,"data":empty(),"recovered":false,"message":"" if missing else "图鉴记录无法读取；仍可浏览全部资料，新的见闻将重新记录。"}

static func save(profile: Dictionary,directory: String=ROOT) -> Dictionary:
 if not valid(profile):return {"ok":false,"message":"图鉴记录无效"}
 if DirAccess.make_dir_recursive_absolute(directory)!=OK:return {"ok":false,"message":"无法创建图鉴记录目录"}
 var path:=directory.path_join("profile.json");var temp:=path+".tmp"
 var file:=FileAccess.open(temp,FileAccess.WRITE)
 if file==null:return {"ok":false,"message":"图鉴记录写入失败，见闻已暂存在本次游戏中"}
 file.store_string(JSON.stringify(profile));file.flush();var error:=file.get_error();file.close()
 if error!=OK or not valid(_read(temp)):return {"ok":false,"message":"图鉴记录校验失败，见闻已暂存在本次游戏中"}
 if valid(_read(path)) and DirAccess.copy_absolute(path,path+".bak")!=OK:return {"ok":false,"message":"图鉴备份失败，见闻已暂存在本次游戏中"}
 if DirAccess.rename_absolute(temp,path)!=OK:return {"ok":false,"message":"图鉴记录替换失败，见闻已暂存在本次游戏中"}
 return {"ok":true,"message":""}

extends RefCounted
## Read-only views over the authoritative gameplay catalogs.
const EnemyAI=preload("res://code/scripts/combat/enemy_intelligence.gd")
const Characters=preload("res://code/scripts/characters/character_catalog.gd")
const Enemies=preload("res://code/scripts/characters/enemy_catalog.gd")
const Relics=preload("res://code/scripts/relics/relic_catalog.gd")
const Events=preload("res://code/scripts/run/event_catalog.gd")
const Seeds=preload("res://code/scripts/run/run_catalog.gd")
const Orders=preload("res://code/scripts/run/recruit_orders.gd")
const Growth=preload("res://code/scripts/characters/character_growth.gd")
const Attributes=preload("res://code/scripts/combat/attributes.gd")
const Numbers=preload("res://code/scripts/number_text.gd")
const Professions=preload("res://code/scripts/profession_names.gd")
const Battle=preload("res://code/scripts/battle.gd")
const Drops=preload("res://code/scripts/relics/relic_drops.gd")
const TITLES={"characters":"角色图鉴","relics":"藏品图鉴","monsters":"怪物图鉴","events":"事件图鉴"}
const EVENT_TYPES={"money":"金钱事件","relic":"藏品事件","battle":"特殊战斗"}
const TIERS={"battle":"普通","elite":"精英","midboss":"道中Boss","boss":"最终Boss"}

static func monsters() -> Array:
 var all:=Enemies.MONSTERS.duplicate(true)
 all.append_array(Enemies.MIDBOSSES.duplicate(true))
 for enemy: Dictionary in all:enemy.hp=Enemies.scaled_hp(int(enemy.hp))
 var boss:=Seeds.encounter("boss",30,0,"")
 boss.patterns=Battle.PATTERNS.duplicate(true)
 all.append(boss)
 return all

static func entries(kind: String) -> Array:
 var rows: Array=[]
 match kind:
  "characters":
   for leader: Dictionary in Characters.LEADERS:
    rows.append({"id":leader.id,"name":leader.name,"category":Professions.label(Orders.profession(leader.id)),"cost":int(Characters.RECRUIT_COSTS[leader.id]),"art":"res://art/characters/%s.png"%leader.id})
  "relics":
   for item: Dictionary in Relics.ITEMS:
    rows.append({"id":item.id,"name":item.name,"category":item.category,"cost":int(item.price),"art":item.icon})
  "monsters":
   for enemy: Dictionary in monsters():
    rows.append({"id":enemy.id,"name":str(enemy.name).trim_prefix("最终 Boss · "),"category":TIERS[enemy.tier],"floor":int(enemy.floor),"art":"res://art/monsters/%s.png"%enemy.id})
  "events":
   for id: String in Events.EVENTS:
    var event: Dictionary=Events.EVENTS[id]
    rows.append({"id":id,"name":event.title,"category":EVENT_TYPES[event.category],"art":{"money":"res://art/resources/gold.png","relic":"res://art/relics/legacy_case.png","battle":"res://art/resources/order_warrior.png"}[event.category]})
 return rows

static func detail(kind: String,id: String,upgraded: bool=false,row: int=1) -> Dictionary:
 var entry: Dictionary={}
 for item: Dictionary in entries(kind):
  if item.id==id:entry=item;break
 if entry.is_empty():return {}
 entry.links=[]
 match kind:
  "characters":_character(entry,upgraded)
  "relics":_relic(entry)
  "monsters":_monster(entry,row)
  "events":_event(entry)
 entry.text=Professions.text(Numbers.description(entry.text))
 return entry

static func _character(entry: Dictionary,upgraded: bool):
 var id: String=entry.id
 var leader:=Characters.leader(id)
 var growth: Dictionary={id:true} if upgraded else {}
 var state:=Battle.create_battle({"team":[id],"character_upgrades":growth})
 var stats:=Attributes.stats(state,id)
 entry.attack=stats.attack;entry.hp=stats.max_hp;entry.skills=[]
 entry.meta="%s    招募 %d 声望    强化 %d 声望"%[entry.category,entry.cost,Growth.upgrade_cost(id)]
 var lines: Array[String]=["攻击  %s     生命  %s"%[Attributes.display(stats.attack),Attributes.display(stats.max_hp)],"强化预览：攻击与生命 +20%" if upgraded else "基础属性 · 未应用本局藏品及全队强化"]
 for slot: Dictionary in leader.skill_slots:
  if slot.type=="passive":
   entry.skills.append(leader.passive.duplicate(true))
   lines.append("被动 · %s\n%s"%[leader.passive.name,leader.passive.text])
  else:
   var source: Dictionary=Characters.SKILLS[slot.id]
   var skill:=Attributes.skill(state,slot.id)
   var amounts: Array[String]=[]
   for effect: Dictionary in skill.effects:
    if effect.has("amount") and effect.op in ["damage","multi_damage","heal","shield","regen"]:
     amounts.append("%s %d"%[{"damage":"伤害","multi_damage":"总伤害","heal":"治疗","shield":"护盾","regen":"每次恢复"}[effect.op],int(effect.amount)])
   entry.skills.append(source.duplicate(true))
   var text:="主动 · %s    %d AP\n%s"%[source.name,int(source.cost),source.text]
   if not amounts.is_empty():text+="\n基础效果："+" / ".join(amounts)
   if not str(source.get("rules","")).is_empty():text+="\n"+str(source.rules)
   if source.has("limit"):text+="\n每场战斗限 %d 次"%int(source.limit)
   lines.append(text)
 lines.append("每名角色每回合只能选择一个主动技能。被动占用技能格，仅前台生效。上回合使用的技能本回合消耗 +1 AP，停用一回合恢复；费用变化不改变基础倍率。")
 entry.text="\n\n".join(lines)

static func _relic(entry: Dictionary):
 var item:=Relics.definition(entry.id)
 entry.meta="%s    %d 金币档    %s"%[item.category,item.price,item.route]
 var sources:="商店：对应价格档随机售卖。\n战斗：普通战斗 %d%%，精英必定掉落；Boss优先掉落16金币档，另有 %d%% 概率额外掉落。\n营地：随机获得一件未持有藏品。\n事件：按事件指定价格档或置换规则获得。"%[Drops.ORDINARY_CHANCE,Drops.BOSS_EXTRA_CHANCE]
 entry.text="效果\n%s\n\n获得途径\n%s\n\n每局同一藏品仅可持有一件，触发条件和次数以效果说明为准。"%[item.effect,sources]

static func _monster(entry: Dictionary,row: int):
 var enemy: Dictionary={}
 for item: Dictionary in monsters():
  if item.id==entry.id:enemy=item;break
 var step:=clampi(row,1,6)-1 if enemy.tier in ["battle","elite"] else 0
 enemy.hp+=Enemies.scaled_hp(step*5)
 for pattern: Dictionary in enemy.patterns:
  if int(pattern.damage)>0:pattern.damage+=step
 enemy.patterns=Enemies.scaled_attack_patterns(enemy.patterns,int(enemy.floor))
 entry.hp=int(enemy.hp);entry.patterns=enemy.patterns.duplicate(true)
 entry.meta="第 %d 层    %s    %s"%[entry.floor,entry.category,"层内第 %d 排"%clampi(row,1,6) if enemy.tier in ["battle","elite"] else "关底"]
 var lines: Array[String]=["生命  %d"%entry.hp,"行动倾向\n"+EnemyAI.description(str(entry.id)),"招式库（按条件随机选择，非固定循环）"]
 var state:=Battle.create_battle({"enemy_hp":enemy.hp,"patterns":enemy.patterns})
 for i in range(enemy.patterns.size()):
  var pattern: Dictionary=enemy.patterns[i]
  state.round=i+1
  state.enraged=false;var normal:=Battle.intent(state)
  state.enraged=true;var angry:=Battle.intent(state)
  var text:="%d. %s"%[i+1,pattern.name]
  if int(normal.damage)>0:text+="\n伤害 %d × %d段；狂怒后 %d × %d段"%[normal.damage,normal.hits,angry.damage,angry.hits]
  if int(normal.get("ward",0))>0:text+="\n获得 %d 护甲"%int(normal.ward)
  text+="\n"+("可以打断" if pattern.interruptible else "不可打断")
  if pattern.get("piercing",false):text+=" · 穿透护盾"
  lines.append(text)
 lines.append("生命降至最大生命的一半或以下时进入狂怒，已预告的敌方行动按战斗规则结算。特殊事件可额外改变生命、攻击、登场生命及开场护盾，详见事件图鉴。")
 entry.text="\n\n".join(lines)

static func branches(id: String) -> Dictionary:
 if not Events.EVENTS.has(id):return {}
 var result: Dictionary=Events.EVENTS[id].actions.duplicate(true)
 if id=="exchange":result={"same_done":"交出一件持有藏品 · 从两份同档结果中选择一份","higher_done":"交出藏品并支付3金币 · 从两份高一档结果中选择一份（16金币档不可升档）"}
 result.leave="离开 · 不选择本次收益"
 return result

static func _event(entry: Dictionary):
 var id: String=entry.id;var event: Dictionary=Events.EVENTS[id]
 entry.meta=EVENT_TYPES[event.category]
 var lines: Array[String]=[str(event.story),"全部选项"]
 for action: String in branches(id):lines.append(str(branches(id)[action]))
 var notes:={"apothecary":"条件：至少持有4金币且生命未满；回复量不超过缺失生命。","inscription":"条件：当前生命必须高于将扣除的15%最大生命，扣血向上取整。","cache":"展示两份随机8金币档结果；只有一件可用藏品时，第二份改为8金币补偿；全部耗尽时仅展示一份8金币补偿。与取走5金币选项只能取其一。","exchange":"需持有用于置换的藏品；升档前需持有3金币。进入选择预览不会扣费，确认后才交出藏品。"}
 if notes.has(id):lines.append(notes[id])
 if event.category=="relic" or id in ["escort","guardian","wounded"]:
  lines.append("藏品从指定价格档的本局可获得池中随机选择。候选耗尽时，改为获得对应档位的金币；不会重复获得本局持有藏品。具体随机结果以进入事件后的展示为准。")
 if Events.FIGHTS.has(id):
  var fight: Dictionary=Events.FIGHTS[id]
  lines.append("特殊战斗：最大生命为普通配置的 %d%%，基础攻击为 %d%%，以 %d%% 生命登场；我方开场护盾为共享生命的 %d%%，敌方开场护甲为敌方最大生命的 %d%%。\n胜利额外金币 %d；战败结束远征。"%[fight.hp,fight.attack,fight.start,fight.team_guard,fight.enemy_guard,fight.bonus])
  if int(fight.relic)>0:lines.append("胜利获得 %d金币档指定藏品，替代常规藏品掉落；经验、金币与召集令仍按对应战斗结算。"%int(fight.relic))
  for monster: Dictionary in entries("monsters"):
   if monster.category==TIERS[fight.kind] and not (id=="guardian" and int(monster.floor)==1):entry.links.append({"kind":"monsters","id":monster.id,"name":monster.name})
  lines.append("下方列出可能遇到的敌人；实际候选由当前楼层决定，守宝强敌不会出现在第一层。")
 entry.text="\n\n".join(lines)

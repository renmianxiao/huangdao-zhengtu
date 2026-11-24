extends RefCounted
## Run-only item definitions. Acquisition sources are intentionally absent.
const ITEMS: Array[Dictionary] = [
	{
		"id": "silver_purse",
		"name": "碎银囊",
		"category": "资源型",
		"price": 8,
		"effect": "普通战斗胜利额外获得1金币。",
		"route": "金币",
		"icon": "res://art/relics/silver_purse.png"
	},
	{
		"id": "study_notes",
		"name": "问学札",
		"category": "资源型",
		"price": 8,
		"effect": "战斗胜利获得的经验提高20%。",
		"route": "经验",
		"icon": "res://art/relics/study_notes.png"
	},
	{
		"id": "merchant_ledger",
		"name": "行商账簿",
		"category": "资源型",
		"price": 8,
		"effect": "每层第一次购买藏品时，价格降低1金币。",
		"route": "商店",
		"icon": "res://art/relics/merchant_ledger.png"
	},
	{
		"id": "travel_notebook",
		"name": "游历手札",
		"category": "资源型",
		"price": 8,
		"effect": "每层第一次完成未知事件后，获得4经验。",
		"route": "事件",
		"icon": "res://art/relics/travel_notebook.png"
	},
	{
		"id": "escort_pass",
		"name": "镖行路引",
		"category": "资源型",
		"price": 8,
		"effect": "完成第一至第四层时，额外获得3金币。",
		"route": "过层",
		"icon": "res://art/relics/escort_pass.png"
	},
	{
		"id": "thrift_copper",
		"name": "惜银铜钱",
		"category": "资源型",
		"price": 8,
		"effect": "精英战斗胜利时，若最后一个我方回合结束战斗后剩余至少2AP，额外获得2金币；每层最多触发1次。",
		"route": "节制用能",
		"icon": "res://art/relics/thrift_copper.png"
	},
	{
		"id": "recommendation_token",
		"name": "荐贤令",
		"category": "资源型",
		"price": 12,
		"effect": "每层第一次付费招募的声望费用降低1，最低0；原本免费招募不消耗次数。",
		"route": "招募",
		"icon": "res://art/relics/recommendation_token.png"
	},
	{
		"id": "teaching_manual",
		"name": "授业谱",
		"category": "资源型",
		"price": 12,
		"effect": "每层第一次付费强化角色的声望费用降低1，最低0；原本免费强化不消耗次数。",
		"route": "强化",
		"icon": "res://art/relics/teaching_manual.png"
	},
	{
		"id": "iron_abacus",
		"name": "铁算盘",
		"category": "资源型",
		"price": 12,
		"effect": "精英战斗胜利额外获得2金币。",
		"route": "精英收益",
		"icon": "res://art/relics/iron_abacus.png"
	},
	{
		"id": "tactics_scroll",
		"name": "论武札记",
		"category": "资源型",
		"price": 12,
		"effect": "精英战斗胜利获得的经验提高30%。",
		"route": "精英经验",
		"icon": "res://art/relics/tactics_scroll.png"
	},
	{
		"id": "pearl_contract",
		"name": "还珠契",
		"category": "资源型",
		"price": 12,
		"effect": "招募原始招募费用为0声望的角色后获得2金币；每层最多触发2次，强化不触发。",
		"route": "低费招募",
		"icon": "res://art/relics/pearl_contract.png"
	},
	{
		"id": "camp_supply",
		"name": "行营补给牒",
		"category": "资源型",
		"price": 12,
		"effect": "每层第一次完成营地节点后，获得2金币和4经验；与营地所选行动无关。",
		"route": "营地",
		"icon": "res://art/relics/camp_supply.png"
	},
	{
		"id": "fortune_abacus",
		"name": "聚财算盘",
		"category": "资源型",
		"price": 16,
		"effect": "普通与精英战斗胜利额外获得2金币。",
		"route": "金币",
		"icon": "res://art/relics/fortune_abacus.png"
	},
	{
		"id": "chivalry_invitation",
		"name": "侠义名帖",
		"category": "资源型",
		"price": 16,
		"effect": "战斗胜利额外获得1声望；每层最多触发2次。",
		"route": "声望",
		"icon": "res://art/relics/chivalry_invitation.png"
	},
	{
		"id": "cinnabar_commentary",
		"name": "朱砂批注",
		"category": "资源型",
		"price": 16,
		"effect": "队伍每次提升等级时，额外获得1声望。",
		"route": "升级",
		"icon": "res://art/relics/cinnabar_commentary.png"
	},
	{
		"id": "guild_contract",
		"name": "商盟金契",
		"category": "资源型",
		"price": 16,
		"effect": "每层第一次进入商店时，获得3金币。",
		"route": "商店路线",
		"icon": "res://art/relics/guild_contract.png"
	},
	{
		"id": "recruitment_register",
		"name": "广纳贤帖",
		"category": "资源型",
		"price": 16,
		"effect": "每层第一次招募原始费用为3声望的角色后，返还1声望；必须先支付本次实际费用。",
		"route": "高费招募",
		"icon": "res://art/relics/recruitment_register.png"
	},
	{
		"id": "legacy_case",
		"name": "师门薪匣",
		"category": "资源型",
		"price": 16,
		"effect": "每层第一次完成原始强化费用大于0的角色强化后，获得2金币和1声望；必须先支付本次实际费用。",
		"route": "强化收益",
		"icon": "res://art/relics/legacy_case.png"
	},
	{
		"id": "whetstone",
		"name": "磨剑石",
		"category": "战斗型",
		"price": 8,
		"effect": "所有角色攻击力提高8%。",
		"route": "通用攻击",
		"icon": "res://art/relics/whetstone.png"
	},
	{
		"id": "heart_mirror",
		"name": "护心镜",
		"category": "战斗型",
		"price": 8,
		"effect": "所有角色血量属性提高10%；共享生命保持原有百分比。",
		"route": "通用生命",
		"icon": "res://art/relics/heart_mirror.png"
	},
	{
		"id": "long_arm_bracer",
		"name": "猿臂护腕",
		"category": "战斗型",
		"price": 8,
		"effect": "战士型角色的主动技能直接伤害提高12%。",
		"route": "战士",
		"icon": "res://art/relics/long_arm_bracer.png"
	},
	{
		"id": "willow_needles",
		"name": "柳叶飞针",
		"category": "战斗型",
		"price": 8,
		"effect": "每回合第一名刺客型角色的首次主动直接攻击伤害提高15%；每回合触发1次。",
		"route": "刺客",
		"icon": "res://art/relics/willow_needles.png"
	},
	{
		"id": "bamboo_talisman",
		"name": "竹纹符纸",
		"category": "战斗型",
		"price": 8,
		"effect": "法师型角色的主动技能直接伤害提高12%。",
		"route": "法师",
		"icon": "res://art/relics/bamboo_talisman.png"
	},
	{
		"id": "jade_pestle",
		"name": "青玉药杵",
		"category": "战斗型",
		"price": 8,
		"effect": "奶妈型角色主动技能的即时治疗量与再生治疗量提高15%。",
		"route": "奶妈",
		"icon": "res://art/relics/jade_pestle.png"
	},
	{
		"id": "rattan_charm",
		"name": "藤编护符",
		"category": "战斗型",
		"price": 8,
		"effect": "盾牌型角色主动技能提供的护盾提高15%。",
		"route": "盾牌",
		"icon": "res://art/relics/rattan_charm.png"
	},
	{
		"id": "clear_bell",
		"name": "清音铜铃",
		"category": "战斗型",
		"price": 8,
		"effect": "每回合辅助型角色首次使用不造成直接伤害的主动技能后，额外获得其血量属性4%的共享护盾；每回合触发1次。",
		"route": "辅助",
		"icon": "res://art/relics/clear_bell.png"
	},
	{
		"id": "hemostatic_cloth",
		"name": "止血布",
		"category": "战斗型",
		"price": 8,
		"effect": "战斗胜利后，恢复共享最大生命的3%。",
		"route": "战后续航",
		"icon": "res://art/relics/hemostatic_cloth.png"
	},
	{
		"id": "bamboo_scabbard",
		"name": "青竹剑鞘",
		"category": "战斗型",
		"price": 8,
		"effect": "第一回合所有主动技能的直接伤害提高15%。",
		"route": "开场进攻",
		"icon": "res://art/relics/bamboo_scabbard.png"
	},
	{
		"id": "wind_sword_tassel",
		"name": "回风剑穗",
		"category": "战斗型",
		"price": 12,
		"effect": "每回合第一次主动直接攻击后，使另一名角色的下一次主动直接攻击伤害提高20%；每回合触发1次，当回合未用则失效。",
		"route": "角色轮换",
		"icon": "res://art/relics/wind_sword_tassel.png"
	},
	{
		"id": "herbal_sachet",
		"name": "百草香囊",
		"category": "战斗型",
		"price": 12,
		"effect": "第三回合开始时，恢复共享最大生命的8%；每场战斗触发1次。",
		"route": "延时恢复",
		"icon": "res://art/relics/herbal_sachet.png"
	},
	{
		"id": "linked_clasp",
		"name": "连环扣",
		"category": "战斗型",
		"price": 12,
		"effect": "同一回合连续由不同角色使用主动直接攻击时，第二次攻击伤害提高12%，随后重新从第一次计数；每回合最多触发2次。",
		"route": "连携",
		"icon": "res://art/relics/linked_clasp.png"
	},
	{
		"id": "armor_piercing_awl",
		"name": "破甲锥",
		"category": "战斗型",
		"price": 12,
		"effect": "敌方当前护甲大于0时，主动技能的直接伤害提高20%；以该技能开始结算时的护甲判定。",
		"route": "破甲",
		"icon": "res://art/relics/armor_piercing_awl.png"
	},
	{
		"id": "poison_cup",
		"name": "淬毒盏",
		"category": "战斗型",
		"price": 12,
		"effect": "我方施加的中毒每次结算伤害提高25%，不改变层数和持续时间。",
		"route": "中毒",
		"icon": "res://art/relics/poison_cup.png"
	},
	{
		"id": "ember_talisman",
		"name": "余烬符",
		"category": "战斗型",
		"price": 12,
		"effect": "每场战斗法师型角色第一次主动直接攻击结束后，追加该角色攻击力60%的独立伤害；全队每场触发1次。",
		"route": "法师爆发",
		"icon": "res://art/relics/ember_talisman.png"
	},
	{
		"id": "iron_clasp",
		"name": "铁衣扣",
		"category": "战斗型",
		"price": 12,
		"effect": "每段敌方直接伤害结算前，若我方仍有护盾，该段伤害降低10%，再按护盾和生命顺序结算。",
		"route": "护盾减伤",
		"icon": "res://art/relics/iron_clasp.png"
	},
	{
		"id": "warm_jade",
		"name": "温玉佩",
		"category": "战斗型",
		"price": 12,
		"effect": "主动治疗的溢出部分有25%转化为共享护盾；每回合由此获得的护盾最多为共享最大生命的10%。",
		"route": "溢出治疗",
		"icon": "res://art/relics/warm_jade.png"
	},
	{
		"id": "twin_blossom_knot",
		"name": "并蒂结",
		"category": "战斗型",
		"price": 12,
		"effect": "同回合第二名不同角色施放主动治疗技能时，该次治疗量提高25%；每回合触发1次。",
		"route": "双治疗",
		"icon": "res://art/relics/twin_blossom_knot.png"
	},
	{
		"id": "formation_flag",
		"name": "换阵旗",
		"category": "战斗型",
		"price": 12,
		"effect": "每回合首次实际完成前后台换位后，获得换位后共享最大生命3%的护盾；每回合触发1次。",
		"route": "换位",
		"icon": "res://art/relics/formation_flag.png"
	},
	{
		"id": "meditation_mat",
		"name": "凝神蒲团",
		"category": "战斗型",
		"price": 12,
		"effect": "某回合未使用任何主动技能并手动结束回合时，恢复共享最大生命的6%；每场最多触发2次。",
		"route": "休整",
		"icon": "res://art/relics/meditation_mat.png"
	},
	{
		"id": "repeating_crossbow",
		"name": "连弩机括",
		"category": "战斗型",
		"price": 12,
		"effect": "自身基础效果包含至少两段直接伤害的主动技能，每段伤害提高10%；藏品追加伤害不增加技能的基础段数。",
		"route": "多段攻击",
		"icon": "res://art/relics/repeating_crossbow.png"
	},
	{
		"id": "hidden_blade_case",
		"name": "藏锋剑匣",
		"category": "战斗型",
		"price": 16,
		"effect": "本回合使用上一回合未使用过的主动直接攻击技能，且实际支付至少2AP后，返还1AP；每回合最多1次、每场最多2次。",
		"route": "技能轮换",
		"icon": "res://art/relics/hidden_blade_case.png"
	},
	{
		"id": "black_tortoise_seal",
		"name": "玄武铜印",
		"category": "战斗型",
		"price": 16,
		"effect": "开战获得共享最大生命12%的护盾；回合末保留剩余共享护盾的40%，保留量最多为共享最大生命的12%。",
		"route": "护盾留存",
		"icon": "res://art/relics/black_tortoise_seal.png"
	},
	{
		"id": "seven_star_disc",
		"name": "七星剑盘",
		"category": "战斗型",
		"price": 16,
		"effect": "同回合第三名不同角色使用主动直接攻击时，该次伤害提高40%；每回合触发1次。",
		"route": "多人连携",
		"icon": "res://art/relics/seven_star_disc.png"
	},
	{
		"id": "concord_jade",
		"name": "同心玉璧",
		"category": "战斗型",
		"price": 16,
		"effect": "前台恰有4名角色且职业各不相同时，前台角色攻击力和血量属性各提高12%；换位后立即重算，保持共享生命百分比。",
		"route": "多职业",
		"icon": "res://art/relics/concord_jade.png"
	},
	{
		"id": "phoenix_marrow",
		"name": "凤髓瓶",
		"category": "战斗型",
		"price": 16,
		"effect": "受到敌方伤害结算完毕后，若共享生命大于0且不高于30%，立即恢复共享最大生命的15%；每场触发1次。",
		"route": "低血应急",
		"icon": "res://art/relics/phoenix_marrow.png"
	},
	{
		"id": "dragon_scale_guard",
		"name": "龙鳞护手",
		"category": "战斗型",
		"price": 16,
		"effect": "每场战斗首次遇到超过共享最大生命25%的单段敌方直接伤害时，将该段伤害压至25%；其他减伤后、护盾吸收前判定，触发1次。",
		"route": "抵御重击",
		"icon": "res://art/relics/dragon_scale_guard.png"
	},
	{
		"id": "cosmos_pouch",
		"name": "乾坤袋",
		"category": "战斗型",
		"price": 16,
		"effect": "AP上限提高2，开场AP和每回合基础回复不变。",
		"route": "AP储备",
		"icon": "res://art/relics/cosmos_pouch.png"
	},
	{
		"id": "origin_pill_tray",
		"name": "归元丹盘",
		"category": "战斗型",
		"price": 16,
		"effect": "第五回合开始时额外恢复1AP，受AP上限限制；每场触发1次。",
		"route": "长线作战",
		"icon": "res://art/relics/origin_pill_tray.png"
	},
	{
		"id": "primordial_pages",
		"name": "太初残页",
		"category": "战斗型",
		"price": 16,
		"effect": "每回合首次使用上一回合未使用过的主动直接攻击技能时，该次伤害提高18%；每回合触发1次。",
		"route": "技能轮换",
		"icon": "res://art/relics/primordial_pages.png"
	},
	{
		"id": "four_symbols_chart",
		"name": "四象阵图",
		"category": "战斗型",
		"price": 16,
		"effect": "前台4个槽位全部有角色时，前台角色血量属性提高15%、攻击力提高5%；职业不限，换位后保持共享生命百分比。",
		"route": "满编前台",
		"icon": "res://art/relics/four_symbols_chart.png"
	}
]

static func definition(id: String) -> Dictionary:
	for item: Dictionary in ITEMS:
		if item.id == id: return item.duplicate(true)
	return {}

static func ids(state: Dictionary) -> Array:
	var value = state.get("relics",state.get("config",{}).get("relics",[]))
	return value.duplicate() if value is Array else []

static func has(state: Dictionary, id: String) -> bool:
	return ids(state).has(id)


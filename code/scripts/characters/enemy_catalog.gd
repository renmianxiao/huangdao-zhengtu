extends RefCounted

const HP_MULTIPLIER := 2

static func scaled_hp(base_hp: int) -> int:
	return base_hp * HP_MULTIPLIER

## Floor-one attacks keep their current values; later floors double base damage.
static func attack_multiplier(floor_number:int)->int:
	return 2 if floor_number>=2 else 1

static func scaled_attack_patterns(patterns:Array,floor_number:int)->Array:
	var result:Array=patterns.duplicate(true)
	for pattern:Dictionary in result:
		if int(pattern.damage)>0:pattern.damage=int(pattern.damage)*attack_multiplier(floor_number)
	return result

## Retain original percentage rounding before applying the global HP increase.
static func percent_hp(current_hp: int, percent: int) -> int:
	return scaled_hp(ceili(float(current_hp) / HP_MULTIPLIER * percent / 100.0))

## Layer-specific enemy pools. Each record owns a four-move repertoire.
const MONSTERS: Array = [
  {
    "id": "wandering_puppet",
    "name": "游荡傀儡",
    "floor": 1,
    "tier": "battle",
    "hp": 360,
    "patterns": [
      {
        "name": "残刃挥斩",
        "damage": 70,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "木架护身",
        "damage": 0,
        "hits": 0,
        "ward": 60,
        "interruptible": false
      },
      {
        "name": "失控劈砍",
        "damage": 120,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      },
      {
        "name": "僵步连斩",
        "damage": 40,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      }
    ]
  },
  {
    "id": "gate_patrol",
    "name": "城门巡卫",
    "floor": 1,
    "tier": "battle",
    "hp": 450,
    "patterns": [
      {
        "name": "戟锋横扫",
        "damage": 80,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "方盾结阵",
        "damage": 0,
        "hits": 0,
        "ward": 80,
        "interruptible": false
      },
      {
        "name": "破门重戟",
        "damage": 140,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      },
      {
        "name": "短戟双刺",
        "damage": 45,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      }
    ]
  },
  {
    "id": "bamboo_swordsman",
    "name": "竹林刀客",
    "floor": 1,
    "tier": "battle",
    "hp": 385,
    "patterns": [
      {
        "name": "竹叶双斩",
        "damage": 38,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "回身刀",
        "damage": 75,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "收刀蓄势",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "断竹拔刀",
        "damage": 150,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "mountain_crossbowman",
    "name": "山道弩手",
    "floor": 1,
    "tier": "battle",
    "hp": 380,
    "patterns": [
      {
        "name": "短弩射击",
        "damage": 65,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "穿甲弩矢",
        "damage": 45,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "装填重弩",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "重弩齐发",
        "damage": 58,
        "hits": 2,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "broken_fist_puppet",
    "name": "残甲拳傀",
    "floor": 1,
    "tier": "battle",
    "hp": 410,
    "patterns": [
      {
        "name": "残甲合拢",
        "damage": 0,
        "hits": 0,
        "ward": 100,
        "interruptible": false
      },
      {
        "name": "铁拳冲击",
        "damage": 85,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "左右摆拳",
        "damage": 42,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "崩山拳",
        "damage": 135,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "red_sand_guard",
    "name": "赤砂刀卫",
    "floor": 2,
    "tier": "battle",
    "hp": 430,
    "patterns": [
      {
        "name": "砂刃横斩",
        "damage": 82,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "双刀疾舞",
        "damage": 44,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "刀架护身",
        "damage": 0,
        "hits": 0,
        "ward": 65,
        "interruptible": false
      },
      {
        "name": "赤砂断首",
        "damage": 155,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "sun_spearman",
    "name": "烈阳枪卫",
    "floor": 2,
    "tier": "battle",
    "hp": 460,
    "patterns": [
      {
        "name": "烈阳直刺",
        "damage": 88,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "枪阵横封",
        "damage": 0,
        "hits": 0,
        "ward": 85,
        "interruptible": false
      },
      {
        "name": "连环枪",
        "damage": 48,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "贯日枪",
        "damage": 160,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "bronze_crossbow_puppet",
    "name": "铜面弩傀",
    "floor": 2,
    "tier": "battle",
    "hp": 405,
    "patterns": [
      {
        "name": "机关上弦",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "铜弩三连",
        "damage": 30,
        "hits": 3,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "穿甲钉",
        "damage": 50,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "蓄力弩矢",
        "damage": 165,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "incense_sorcerer",
    "name": "焚香术士",
    "floor": 2,
    "tier": "battle",
    "hp": 400,
    "patterns": [
      {
        "name": "香灰侵蚀",
        "damage": 48,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "烟幕结界",
        "damage": 0,
        "hits": 0,
        "ward": 95,
        "interruptible": false
      },
      {
        "name": "火符双发",
        "damage": 45,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "焚香爆燃",
        "damage": 160,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "stone_brute",
    "name": "石甲力士",
    "floor": 2,
    "tier": "battle",
    "hp": 500,
    "patterns": [
      {
        "name": "石甲凝固",
        "damage": 0,
        "hits": 0,
        "ward": 120,
        "interruptible": false
      },
      {
        "name": "石掌拍击",
        "damage": 95,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "举石蓄力",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "落石重压",
        "damage": 180,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "broken_sword_puppet",
    "name": "断刃剑傀",
    "floor": 3,
    "tier": "battle",
    "hp": 500,
    "patterns": [
      {
        "name": "断刃二连",
        "damage": 48,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "裂隙刺击",
        "damage": 55,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "剑架封挡",
        "damage": 0,
        "hits": 0,
        "ward": 90,
        "interruptible": false
      },
      {
        "name": "断剑突进",
        "damage": 175,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "chain_jailer",
    "name": "锁链狱卒",
    "floor": 3,
    "tier": "battle",
    "hp": 535,
    "patterns": [
      {
        "name": "铁链横扫",
        "damage": 98,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "双链绞击",
        "damage": 50,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "收链蓄势",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "锁链重坠",
        "damage": 185,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "iron_shield_guard",
    "name": "铁壁盾卫",
    "floor": 3,
    "tier": "battle",
    "hp": 560,
    "patterns": [
      {
        "name": "铁壁架盾",
        "damage": 0,
        "hits": 0,
        "ward": 150,
        "interruptible": false
      },
      {
        "name": "盾缘撞击",
        "damage": 95,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "重整铁壁",
        "damage": 0,
        "hits": 0,
        "ward": 80,
        "interruptible": false
      },
      {
        "name": "铁盾冲锋",
        "damage": 165,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "repeating_crossbow",
    "name": "机关连弩",
    "floor": 3,
    "tier": "battle",
    "hp": 475,
    "patterns": [
      {
        "name": "连弩齐射",
        "damage": 32,
        "hits": 3,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "更换弩匣",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "贯甲弩箭",
        "damage": 60,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "全匣齐发",
        "damage": 65,
        "hits": 2,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "seal_sorcerer",
    "name": "封印术士",
    "floor": 3,
    "tier": "battle",
    "hp": 450,
    "patterns": [
      {
        "name": "符印结界",
        "damage": 0,
        "hits": 0,
        "ward": 120,
        "interruptible": false
      },
      {
        "name": "封印侵蚀",
        "damage": 58,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "双符爆裂",
        "damage": 48,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "破印咒",
        "damage": 178,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "dusk_assassin",
    "name": "暮影刺客",
    "floor": 4,
    "tier": "battle",
    "hp": 560,
    "patterns": [
      {
        "name": "暮影穿刺",
        "damage": 64,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "袖刃双袭",
        "damage": 55,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "隐身蓄势",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "暮色绝杀",
        "damage": 188,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "blood_swordsman",
    "name": "血衣刀客",
    "floor": 4,
    "tier": "battle",
    "hp": 585,
    "patterns": [
      {
        "name": "血衣拔刀",
        "damage": 110,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "交错双刃",
        "damage": 54,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "血衣护身",
        "damage": 0,
        "hits": 0,
        "ward": 95,
        "interruptible": false
      },
      {
        "name": "血月斩",
        "damage": 195,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "lantern_soulguide",
    "name": "提灯引魂者",
    "floor": 4,
    "tier": "battle",
    "hp": 510,
    "patterns": [
      {
        "name": "灯火灼魂",
        "damage": 62,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "魂灯护罩",
        "damage": 0,
        "hits": 0,
        "ward": 135,
        "interruptible": false
      },
      {
        "name": "凝聚灯火",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "引魂爆灯",
        "damage": 190,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "fallen_banner_spirit",
    "name": "残旗枪魂",
    "floor": 4,
    "tier": "battle",
    "hp": 610,
    "patterns": [
      {
        "name": "残旗列阵",
        "damage": 0,
        "hits": 0,
        "ward": 125,
        "interruptible": false
      },
      {
        "name": "魂枪双刺",
        "damage": 56,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "残旗横扫",
        "damage": 108,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "枪魂破阵",
        "damage": 198,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "dusk_crow_machine",
    "name": "暮鸦机关",
    "floor": 4,
    "tier": "battle",
    "hp": 505,
    "patterns": [
      {
        "name": "翼刃三连",
        "damage": 36,
        "hits": 3,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "尖喙穿甲",
        "damage": 65,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "回旋盘桓",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "暮鸦俯冲",
        "damage": 185,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "ghost_armored_guard",
    "name": "幽甲禁卫",
    "floor": 5,
    "tier": "battle",
    "hp": 660,
    "patterns": [
      {
        "name": "幽甲列阵",
        "damage": 0,
        "hits": 0,
        "ward": 155,
        "interruptible": false
      },
      {
        "name": "禁卫重戟",
        "damage": 118,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "戟刃双击",
        "damage": 60,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "幽门重击",
        "damage": 210,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "moon_sword_spirit",
    "name": "月影剑魂",
    "floor": 5,
    "tier": "battle",
    "hp": 585,
    "patterns": [
      {
        "name": "月影穿心",
        "damage": 70,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "月弧双斩",
        "damage": 58,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "凝月蓄锋",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "碎月剑",
        "damage": 205,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "black_lantern_sorcerer",
    "name": "黑灯术士",
    "floor": 5,
    "tier": "battle",
    "hp": 575,
    "patterns": [
      {
        "name": "黑灯蚀魂",
        "damage": 72,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "黑灯结界",
        "damage": 0,
        "hits": 0,
        "ward": 155,
        "interruptible": false
      },
      {
        "name": "双焰焚身",
        "damage": 56,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "灭灯咒",
        "damage": 205,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "qi_devouring_machine",
    "name": "噬气机关兽",
    "floor": 5,
    "tier": "battle",
    "hp": 630,
    "patterns": [
      {
        "name": "机关扑咬",
        "damage": 115,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "噬气尖牙",
        "damage": 68,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "兽甲闭合",
        "damage": 0,
        "hits": 0,
        "ward": 130,
        "interruptible": false
      },
      {
        "name": "三爪撕裂",
        "damage": 58,
        "hits": 3,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "gate_stone_guard",
    "name": "镇门石卫",
    "floor": 5,
    "tier": "battle",
    "hp": 710,
    "patterns": [
      {
        "name": "镇门石甲",
        "damage": 0,
        "hits": 0,
        "ward": 185,
        "interruptible": false
      },
      {
        "name": "门柱横扫",
        "damage": 125,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "举柱蓄势",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "镇门重压",
        "damage": 230,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "armored_executor",
    "name": "重甲执行者",
    "floor": 1,
    "tier": "elite",
    "hp": 700,
    "patterns": [
      {
        "name": "重刀横扫",
        "damage": 100,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "执行者铁壁",
        "damage": 0,
        "hits": 0,
        "ward": 120,
        "interruptible": false
      },
      {
        "name": "刑刀重劈",
        "damage": 180,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      },
      {
        "name": "执刑双斩",
        "damage": 60,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      }
    ]
  },
  {
    "id": "bronze_shield_captain",
    "name": "铜盾卫长",
    "floor": 1,
    "tier": "elite",
    "hp": 730,
    "patterns": [
      {
        "name": "铜盾军阵",
        "damage": 0,
        "hits": 0,
        "ward": 160,
        "interruptible": false
      },
      {
        "name": "盾击压制",
        "damage": 105,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "铜枪二连",
        "damage": 58,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "卫长冲阵",
        "damage": 175,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "red_furnace_commander",
    "name": "赤炉监军",
    "floor": 2,
    "tier": "elite",
    "hp": 780,
    "patterns": [
      {
        "name": "炉刃横斩",
        "damage": 115,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "赤炉灼击",
        "damage": 75,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "赤炉铁甲",
        "damage": 0,
        "hits": 0,
        "ward": 145,
        "interruptible": false
      },
      {
        "name": "开炉重斩",
        "damage": 200,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "flame_machine_beast",
    "name": "炎纹机关兽",
    "floor": 2,
    "tier": "elite",
    "hp": 750,
    "patterns": [
      {
        "name": "炎爪双击",
        "damage": 63,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "炎纹甲壳",
        "damage": 0,
        "hits": 0,
        "ward": 125,
        "interruptible": false
      },
      {
        "name": "炉心蓄能",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "机关猛扑",
        "damage": 210,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "black_iron_sword_guard",
    "name": "玄铁剑卫",
    "floor": 3,
    "tier": "elite",
    "hp": 840,
    "patterns": [
      {
        "name": "玄铁双斩",
        "damage": 66,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "玄铁剑壁",
        "damage": 0,
        "hits": 0,
        "ward": 170,
        "interruptible": false
      },
      {
        "name": "破甲剑锋",
        "damage": 78,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "玄铁重剑",
        "damage": 215,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "prison_stone_beast",
    "name": "镇狱石兽",
    "floor": 3,
    "tier": "elite",
    "hp": 800,
    "patterns": [
      {
        "name": "镇狱石甲",
        "damage": 0,
        "hits": 0,
        "ward": 190,
        "interruptible": false
      },
      {
        "name": "镇狱重爪",
        "damage": 130,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "石牙绞击",
        "damage": 64,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "镇狱崩落",
        "damage": 220,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "red_robed_judge",
    "name": "赤衣判官",
    "floor": 4,
    "tier": "elite",
    "hp": 910,
    "patterns": [
      {
        "name": "判笔穿心",
        "damage": 83,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "朱衣符壁",
        "damage": 0,
        "hits": 0,
        "ward": 170,
        "interruptible": false
      },
      {
        "name": "双符审判",
        "damage": 68,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "赤印决刑",
        "damage": 230,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "night_commander",
    "name": "夜行统领",
    "floor": 4,
    "tier": "elite",
    "hp": 930,
    "patterns": [
      {
        "name": "夜刃扫阵",
        "damage": 140,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "夜行连斩",
        "damage": 70,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "暗甲结阵",
        "damage": 0,
        "hits": 0,
        "ward": 180,
        "interruptible": false
      },
      {
        "name": "夜袭破阵",
        "damage": 235,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "black_gate_executioner",
    "name": "玄门执刑者",
    "floor": 5,
    "tier": "elite",
    "hp": 1000,
    "patterns": [
      {
        "name": "玄门铁壁",
        "damage": 0,
        "hits": 0,
        "ward": 200,
        "interruptible": false
      },
      {
        "name": "执刑巨刃",
        "damage": 150,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "玄刃穿甲",
        "damage": 90,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "玄门断刑",
        "damage": 250,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      }
    ]
  },
  {
    "id": "dual_blade_guardian",
    "name": "双刃守阙者",
    "floor": 5,
    "tier": "elite",
    "hp": 980,
    "patterns": [
      {
        "name": "守阙双刃",
        "damage": 78,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "回旋三斩",
        "damage": 52,
        "hits": 3,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "双刃护架",
        "damage": 0,
        "hits": 0,
        "ward": 165,
        "interruptible": false
      },
      {
        "name": "交刃断空",
        "damage": 125,
        "hits": 2,
        "ward": 0,
        "interruptible": true
      }
    ]
  }
]

const MIDBOSSES: Array = [
  {
    "id": "iron_commander",
    "name": "道中 Boss · 铸铁统领",
    "floor": 3,
    "tier": "midboss",
    "hp": 1100,
    "patterns": [
      {
        "name": "扫阵",
        "damage": 120,
        "hits": 1,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "强化铁壁",
        "damage": 0,
        "hits": 0,
        "ward": 180,
        "interruptible": false
      },
      {
        "name": "蓄势重劈",
        "damage": 260,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      },
      {
        "name": "双重压制",
        "damage": 80,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      }
    ]
  },
  {
    "id": "puppet_master",
    "name": "道中 Boss · 千机傀师",
    "floor": 3,
    "tier": "midboss",
    "hp": 1000,
    "patterns": [
      {
        "name": "牵丝三刃",
        "damage": 38,
        "hits": 3,
        "ward": 0,
        "interruptible": false
      },
      {
        "name": "傀儡机关阵",
        "damage": 0,
        "hits": 0,
        "ward": 135,
        "interruptible": false
      },
      {
        "name": "蓄力千机齐射",
        "damage": 72,
        "hits": 3,
        "ward": 0,
        "interruptible": true
      },
      {
        "name": "收丝重整",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      }
    ]
  },
  {
    "id": "soul_judge",
    "name": "道中 Boss · 锁魂判官",
    "floor": 3,
    "tier": "midboss",
    "hp": 1040,
    "patterns": [
      {
        "name": "锁魂判笔",
        "damage": 90,
        "hits": 1,
        "ward": 0,
        "interruptible": false,
        "piercing": true
      },
      {
        "name": "合卷蓄印",
        "damage": 0,
        "hits": 0,
        "ward": 0,
        "interruptible": false,
        "text": "蓄势待发；趁机恢复、留存 AP 或准备防御"
      },
      {
        "name": "夺魄重印",
        "damage": 230,
        "hits": 1,
        "ward": 0,
        "interruptible": true
      },
      {
        "name": "阴阳双判",
        "damage": 68,
        "hits": 2,
        "ward": 0,
        "interruptible": false
      }
    ]
  }
]

static func pool(floor_number: int, tier: String) -> Array:
	var result: Array = []
	for enemy: Dictionary in MONSTERS:
		if int(enemy.floor) == clampi(floor_number, 1, 5) and enemy.tier == tier:
			result.append(enemy.duplicate(true))
	return result

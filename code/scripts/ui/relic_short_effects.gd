extends RefCounted
const Professions=preload("res://code/scripts/profession_names.gd")
## A short shopping cue; complete triggers and limits remain in the tooltip.
const TEXT={
 "silver_purse":"普通战斗金币 +1","study_notes":"战斗经验 +20%","merchant_ledger":"每层首购便宜1金币","travel_notebook":"每层首事件经验 +4","escort_pass":"前四层过层金币 +3","thrift_copper":"留AP赢精英：金币 +2",
 "recommendation_token":"每层首招声望 -1","teaching_manual":"每层首强化声望 -1","iron_abacus":"精英战斗金币 +2","tactics_scroll":"精英经验 +30%","pearl_contract":"零费招募返2金币","camp_supply":"首营地：金币与经验",
 "fortune_abacus":"普战/精英金币 +2","chivalry_invitation":"战斗获声望（每层2次）","cinnabar_commentary":"升级额外声望 +1","guild_contract":"每层首商店金币 +3","recruitment_register":"每层首招高费返1声望","legacy_case":"首付费强化返金币声望",
 "whetstone":"全队攻击 +8%","heart_mirror":"全队血量 +10%","long_arm_bracer":"侠客直伤 +12%","willow_needles":"刺客每轮首击 +15%","bamboo_talisman":"方士直伤 +12%","jade_pestle":"医师治疗 +15%","rattan_charm":"守卫护盾 +15%","clear_bell":"谋士非直伤技能附盾",
 "hemostatic_cloth":"战斗胜利回复3%生命","bamboo_scabbard":"首回合直伤 +15%","wind_sword_tassel":"首击强化队友下一击","herbal_sachet":"第三回合回复8%生命","linked_clasp":"异人连携直伤 +12%","armor_piercing_awl":"敌有护甲：直伤 +20%","poison_cup":"中毒伤害 +25%","ember_talisman":"方士首次攻击追加伤害",
 "iron_clasp":"有盾时承伤 -10%","warm_jade":"溢出治疗25%转盾","twin_blossom_knot":"异人第二治疗 +25%","formation_flag":"每轮首次换位获得盾","meditation_mat":"整轮不行动回复6%生命","repeating_crossbow":"多段直伤每段 +10%","hidden_blade_case":"间隔收费攻击返1AP",
 "black_tortoise_seal":"开场护盾与余盾保留","seven_star_disc":"第三名攻击者直伤 +40%","concord_jade":"四职业前台攻血 +12%","phoenix_marrow":"濒危时回复15%生命","dragon_scale_guard":"首次超重击压至25%","cosmos_pouch":"AP上限 +2","origin_pill_tray":"第五回合额外 +1AP","primordial_pages":"间隔首击直伤 +18%","four_symbols_chart":"满前台：血+15%攻+5%"
}
static func text(id:String)->String:return Professions.text(str(TEXT.get(id,"")))

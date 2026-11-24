extends RefCounted
const EVENTS={
"purse":{"category":"money","title":"遗失的钱囊","story":"山道旁落着一只钱囊，袋口绣着寻常人家的姓氏。","actions":{"take":"收下钱囊 · 获得4—6金币","return":"寻找失主 · 获得2声望"}},
"apothecary":{"category":"money","title":"山野药庐","story":"药香从竹屋中飘出，老医者愿以薄酬为远行人疗伤。","actions":{"heal":"支付4金币 · 恢复50%最大生命"}},
"village":{"category":"money","title":"贫寒村落","story":"村民正为修复被山洪冲毁的桥梁奔走募资。","actions":{"donate4":"捐赠4金币 · 获得3声望","donate2":"捐赠2金币 · 获得1声望"}},
"gamble":{"category":"money","title":"暗巷赌局","story":"巷口的庄家邀你押上一注。输赢皆看天意，落子之后再无反悔。","actions":{"bet":"押3金币 · 60%拿回7金币，40%失去赌注"}},
"merchant":{"category":"relic","title":"落魄行商","story":"行商急于筹措盘缠，愿将两件随身珍藏折价让出，但只肯卖一件。","actions":{"buy8":"支付6金币 · 购买8金币档藏品","buy12":"支付9金币 · 购买12金币档藏品"}},
"exchange":{"category":"relic","title":"旧物置换","story":"旧物铺掌柜识得你的随身藏品。他愿以两件珍藏供你择一交换，也可另收三枚金币，换取更高一档的宝物。","actions":{}},
"inscription":{"category":"relic","title":"残碑秘藏","story":"断碑铭文暗藏秘法，强行参悟虽可得宝，却也会损耗气血。","actions":{"study":"损失15%最大生命 · 获得12金币档藏品"}},
"cache":{"category":"relic","title":"无主遗藏","story":"荒废宅院的暗格中，藏着前人留下的两件旧物与一小袋碎银。只能取走其中一份。","actions":{"gift0":"领取第一份藏品","gift1":"领取第二份藏品","cash":"取走碎银 · 获得5金币"}},
"bounty":{"category":"battle","title":"悬赏凶徒","story":"告示上的凶徒就在附近。此敌生命和基础攻击提高10%，击败后除普通战利品外额外获得4金币。","actions":{"fight":"接下悬赏 · 挑战特殊普通战斗"}},
"escort":{"category":"battle","title":"护送商队","story":"商队愿以珍藏酬谢护送。需支付2金币筹备，我方开场获得20%最大生命的护盾；胜利获得普通战利品与下方指定奖励，替代常规藏品掉落。","actions":{"fight":"支付2金币 · 护送商队"}},
"guardian":{"category":"battle","title":"守宝强敌","story":"精英强敌守着一件珍宝，敌方开场拥有相当于自身20%最大生命的防护。胜利获得精英战利品与下方指定奖励，替代常规藏品掉落。","actions":{"fight":"挑战守宝精英"}},
"wounded":{"category":"battle","title":"负伤高手","story":"负伤高手停步路旁。你可以花6金币救治换取珍藏，也可发起挑战：精英以60%生命登场，基础攻击提高25%，胜利额外获得3金币。","actions":{"heal":"支付6金币救治 · 获得12金币档藏品","fight":"挑战负伤精英"}}
}
const WEIGHTS={"money":40,"relic":35,"battle":25}
const FIGHTS={
"bounty":{"kind":"battle","hp":110,"attack":110,"start":100,"team_guard":0,"enemy_guard":0,"bonus":4,"relic":0,"cost":0},
"escort":{"kind":"battle","hp":100,"attack":100,"start":100,"team_guard":20,"enemy_guard":0,"bonus":0,"relic":12,"cost":2},
"guardian":{"kind":"elite","hp":100,"attack":100,"start":100,"team_guard":0,"enemy_guard":20,"bonus":0,"relic":16,"cost":0},
"wounded":{"kind":"elite","hp":100,"attack":125,"start":60,"team_guard":0,"enemy_guard":0,"bonus":3,"relic":0,"cost":0}
}
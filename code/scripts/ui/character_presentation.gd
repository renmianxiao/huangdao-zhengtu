extends RefCounted
## Visual audit of all 84 updated transparent illustrations, 2026-11-11.
## Normalized head bounds include hair/crowns. Focus is the upper-body axis,
## separate from the image centre for crouched, seated and reaching poses.
## These are presentation data only; original artwork and character rules stay intact.
const HEADROOM := 0.025
const PROFILES := {
	"assassin_01": [Rect2(0.3500,0.0080,0.3000,0.2150),Vector2(0.4700,0.3400)],
	"assassin_02": [Rect2(0.2600,0.0250,0.4900,0.2550),Vector2(0.4900,0.3400)],
	"assassin_03": [Rect2(0.2450,0.0150,0.3400,0.2050),Vector2(0.4700,0.3400)],
	"assassin_04": [Rect2(0.3000,0.0150,0.3500,0.2600),Vector2(0.4900,0.3400)],
	"assassin_05": [Rect2(0.3300,0.0050,0.3300,0.2050),Vector2(0.4500,0.3400)],
	"budget_assassin_01": [Rect2(0.2350,0.0150,0.3800,0.2500),Vector2(0.4900,0.3400)],
	"budget_assassin_02": [Rect2(0.3650,0.0200,0.2450,0.2000),Vector2(0.4800,0.3400)],
	"budget_assassin_03": [Rect2(0.2600,0.0050,0.3800,0.2850),Vector2(0.5100,0.3400)],
	"budget_assassin_04": [Rect2(0.3500,0.0200,0.2800,0.1900),Vector2(0.5200,0.3400)],
	"budget_assassin_05": [Rect2(0.2900,0.0050,0.4000,0.2750),Vector2(0.5000,0.3400)],
	"budget_healer_01": [Rect2(0.3200,0.0050,0.3400,0.2850),Vector2(0.5100,0.3400)],
	"budget_healer_02": [Rect2(0.3000,0.0050,0.2800,0.3050),Vector2(0.4600,0.3400)],
	"budget_healer_03": [Rect2(0.3000,0.0050,0.3200,0.2750),Vector2(0.5100,0.3400)],
	"budget_healer_04": [Rect2(0.3060,0.0180,0.3330,0.2570),Vector2(0.5000,0.3400)],
	"budget_healer_05": [Rect2(0.2300,0.0050,0.3900,0.2950),Vector2(0.4600,0.3400)],
	"budget_mage_01": [Rect2(0.3330,0.0150,0.3000,0.2350),Vector2(0.4900,0.3400)],
	"budget_mage_02": [Rect2(0.3940,0.0150,0.2220,0.2420),Vector2(0.5100,0.3400)],
	"budget_mage_03": [Rect2(0.3890,0.0210,0.2440,0.1710),Vector2(0.5200,0.3400)],
	"budget_mage_04": [Rect2(0.4390,0.0240,0.2390,0.2600),Vector2(0.5900,0.3400)],
	"budget_mage_05": [Rect2(0.3700,0.0200,0.3600,0.2700),Vector2(0.5500,0.3400)],
	"budget_shield_01": [Rect2(0.3780,0.0180,0.2060,0.1830),Vector2(0.4800,0.3400)],
	"budget_shield_02": [Rect2(0.4000,0.0550,0.2610,0.1990),Vector2(0.5200,0.3400)],
	"budget_shield_03": [Rect2(0.2900,0.0050,0.4000,0.2950),Vector2(0.5000,0.3400)],
	"budget_shield_04": [Rect2(0.4200,0.0500,0.3400,0.2900),Vector2(0.6000,0.3400)],
	"budget_shield_05": [Rect2(0.2500,0.0050,0.4400,0.2950),Vector2(0.4900,0.3400)],
	"budget_support_01": [Rect2(0.3500,0.0460,0.2500,0.1900),Vector2(0.5100,0.3400)],
	"budget_support_02": [Rect2(0.3560,0.0150,0.3060,0.2480),Vector2(0.5000,0.3400)],
	"budget_support_03": [Rect2(0.3000,0.0000,0.3400,0.2600),Vector2(0.4700,0.3400)],
	"budget_support_04": [Rect2(0.4000,0.0000,0.3800,0.2900),Vector2(0.5700,0.3400)],
	"budget_support_05": [Rect2(0.3300,0.0000,0.3200,0.2900),Vector2(0.5000,0.3400)],
	"budget_warrior_01": [Rect2(0.4100,0.0100,0.1900,0.1950),Vector2(0.5000,0.3400)],
	"budget_warrior_02": [Rect2(0.3800,0.0080,0.2800,0.2100),Vector2(0.4900,0.3400)],
	"budget_warrior_03": [Rect2(0.3600,0.0050,0.3100,0.3050),Vector2(0.5100,0.3400)],
	"budget_warrior_04": [Rect2(0.3400,0.0100,0.3000,0.2200),Vector2(0.5200,0.3400)],
	"budget_warrior_05": [Rect2(0.3560,0.0490,0.2720,0.2260),Vector2(0.4900,0.3400)],
	"free_assassin_01": [Rect2(0.3500,0.0100,0.4100,0.2600),Vector2(0.5800,0.3400)],
	"free_assassin_02": [Rect2(0.3500,0.0000,0.3900,0.2500),Vector2(0.5200,0.3400)],
	"free_assassin_03": [Rect2(0.3890,0.0150,0.2330,0.1440),Vector2(0.5100,0.3400)],
	"free_healer_01": [Rect2(0.3200,0.0000,0.3500,0.2600),Vector2(0.5100,0.3400)],
	"free_healer_02": [Rect2(0.4110,0.0180,0.1780,0.1470),Vector2(0.5000,0.3400)],
	"free_healer_03": [Rect2(0.2800,0.0000,0.4200,0.2500),Vector2(0.5400,0.3400)],
	"free_mage_01": [Rect2(0.4720,0.0180,0.2170,0.2380),Vector2(0.6000,0.3400)],
	"free_mage_02": [Rect2(0.3720,0.0090,0.3000,0.2050),Vector2(0.5200,0.3400)],
	"free_mage_03": [Rect2(0.3800,0.0000,0.3900,0.2300),Vector2(0.5500,0.3400)],
	"free_shield_01": [Rect2(0.3170,0.0180,0.2060,0.1590),Vector2(0.4500,0.3400)],
	"free_shield_02": [Rect2(0.3890,0.0150,0.1890,0.2080),Vector2(0.4900,0.3400)],
	"free_shield_03": [Rect2(0.3720,0.0180,0.2390,0.1620),Vector2(0.5300,0.3400)],
	"free_shield_04": [Rect2(0.3940,0.0090,0.2780,0.2290),Vector2(0.5700,0.3400)],
	"free_support_01": [Rect2(0.4060,0.0210,0.1830,0.2140),Vector2(0.5000,0.3400)],
	"free_support_02": [Rect2(0.2800,0.0100,0.3500,0.2800),Vector2(0.4500,0.3400)],
	"free_support_03": [Rect2(0.3330,0.0580,0.3110,0.1830),Vector2(0.5000,0.3400)],
	"free_warrior_01": [Rect2(0.3830,0.0150,0.2000,0.1900),Vector2(0.5000,0.3400)],
	"free_warrior_02": [Rect2(0.4110,0.0280,0.2500,0.1800),Vector2(0.5300,0.3400)],
	"free_warrior_03": [Rect2(0.3560,0.0090,0.2830,0.2170),Vector2(0.4900,0.3400)],
	"free_warrior_04": [Rect2(0.4110,0.0090,0.1670,0.1680),Vector2(0.5000,0.3400)],
	"guardian": [Rect2(0.3750,0.0200,0.1850,0.1900),Vector2(0.4800,0.3400)],
	"healer": [Rect2(0.4100,0.0050,0.3500,0.2550),Vector2(0.6000,0.3400)],
	"healer_01": [Rect2(0.3300,0.0150,0.3600,0.2450),Vector2(0.5000,0.3400)],
	"healer_02": [Rect2(0.3600,0.0250,0.3100,0.2550),Vector2(0.5100,0.3400)],
	"healer_03": [Rect2(0.3500,0.0060,0.3000,0.2450),Vector2(0.5000,0.3400)],
	"healer_04": [Rect2(0.2500,0.0150,0.3300,0.2350),Vector2(0.4400,0.3400)],
	"healer_05": [Rect2(0.4200,0.0080,0.2800,0.2850),Vector2(0.5500,0.3400)],
	"knight": [Rect2(0.3200,0.0060,0.3500,0.2500),Vector2(0.5000,0.3400)],
	"mage_01": [Rect2(0.3250,0.0060,0.2800,0.2800),Vector2(0.4600,0.3400)],
	"mage_02": [Rect2(0.3700,0.0250,0.3000,0.2550),Vector2(0.5200,0.3400)],
	"mage_03": [Rect2(0.3050,0.0080,0.3000,0.2550),Vector2(0.4500,0.3400)],
	"mage_04": [Rect2(0.2500,0.0650,0.3400,0.2200),Vector2(0.4700,0.3400)],
	"mage_05": [Rect2(0.3500,0.0060,0.3100,0.2400),Vector2(0.5100,0.3400)],
	"ranger": [Rect2(0.3700,0.0150,0.2700,0.2050),Vector2(0.5000,0.3400)],
	"shield_01": [Rect2(0.3000,0.0150,0.2150,0.1650),Vector2(0.4000,0.3400)],
	"shield_02": [Rect2(0.3900,0.0080,0.2500,0.2700),Vector2(0.5200,0.3400)],
	"shield_03": [Rect2(0.3100,0.0200,0.3800,0.2500),Vector2(0.5300,0.3400)],
	"shield_04": [Rect2(0.3950,0.0500,0.2500,0.1900),Vector2(0.5100,0.3400)],
	"shield_05": [Rect2(0.3600,0.0100,0.3300,0.2350),Vector2(0.5300,0.3400)],
	"support_01": [Rect2(0.3000,0.0050,0.3800,0.2650),Vector2(0.6000,0.3400)],
	"support_02": [Rect2(0.3000,0.0300,0.3300,0.2400),Vector2(0.4600,0.3400)],
	"support_03": [Rect2(0.3350,0.0160,0.3550,0.1900),Vector2(0.5200,0.3400)],
	"support_04": [Rect2(0.3300,0.0050,0.3500,0.2850),Vector2(0.5200,0.3400)],
	"support_05": [Rect2(0.3300,0.0050,0.3200,0.2100),Vector2(0.4900,0.3400)],
	"warrior_01": [Rect2(0.3900,0.0070,0.2500,0.2350),Vector2(0.5100,0.3400)],
	"warrior_02": [Rect2(0.3500,0.0100,0.2900,0.2400),Vector2(0.5200,0.3400)],
	"warrior_03": [Rect2(0.4150,0.0320,0.2800,0.2400),Vector2(0.5700,0.3400)],
	"warrior_04": [Rect2(0.4500,0.0050,0.3900,0.2750),Vector2(0.6500,0.3400)],
	"warrior_05": [Rect2(0.3300,0.0090,0.3200,0.2250),Vector2(0.4800,0.3400)],
}

static func head_bounds(id: String) -> Rect2:
	return PROFILES[id][0] if PROFILES.has(id) else Rect2(0.40,0.04,0.20,0.20)

static func focus(id: String) -> Vector2:
	return PROFILES[id][1] if PROFILES.has(id) else Vector2(0.5,0.34)

## Region and destination are separate: at impossible aspect ratios we contain
## the protected head instead of clipping its sides or stretching the artwork.
static func region(id: String, dimensions: Vector2, destination: Vector2, mode: String="halfbody") -> Rect2:
	if dimensions.x <= 0.0 or dimensions.y <= 0.0 or destination.x <= 0.0 or destination.y <= 0.0:
		return Rect2()
	if mode == "fullbody":
		return Rect2(Vector2.ZERO,dimensions)
	var normalized_head := head_bounds(id)
	var protected := Rect2((normalized_head.position-Vector2(0.025,HEADROOM))*dimensions,
		(normalized_head.size+Vector2(0.05,HEADROOM*2.0))*dimensions).intersection(Rect2(Vector2.ZERO,dimensions))
	var ratio := destination.x / destination.y
	var height := maxf(dimensions.y*(0.27 if mode=="avatar" else 0.48),protected.size.y*(1.55 if mode=="avatar" else 2.65))
	var width := height*ratio
	if width < protected.size.x:
		width=protected.size.x;height=width/ratio
	var extent := Vector2(width,height)
	extent *= minf(1.0,minf(dimensions.x/extent.x,dimensions.y/extent.y))
	extent = extent.max(protected.size).min(dimensions)
	var center_x := normalized_head.get_center().x if mode=="avatar" else focus(id).x
	var left := clampf(center_x*dimensions.x-extent.x*0.5,protected.end.x-extent.x,protected.position.x)
	var top := protected.position.y-(extent.y-protected.size.y)*(0.14 if mode=="avatar" else 0.025)
	return Rect2(Vector2(clampf(left,0.0,dimensions.x-extent.x),clampf(top,0.0,dimensions.y-extent.y)),extent)

static func destination(source: Rect2, area: Rect2, bottom_aligned: bool=false) -> Rect2:
	if source.size.x <= 0.0 or source.size.y <= 0.0 or area.size.x <= 0.0 or area.size.y <= 0.0:
		return Rect2(area.position,Vector2.ZERO)
	var scale_value := minf(area.size.x/source.size.x,area.size.y/source.size.y)
	var shown := source.size*scale_value
	return Rect2(area.position+(area.size-shown)*Vector2(0.5,1.0 if bottom_aligned else 0.5),shown)

"""Builds art/events/<event id>.svg: one lacquer roundel per event, gilt frame
shared, pictogram unique. Run from the project root: python code/tools/build_event_emblems.py"""
import os

GOLD = "#e0bd78"
LIGHT = "#f3dca4"
DEEP = "#9c7637"
IVORY = "#efe2c4"
RED = "#b23a2c"
JADE = "#6f9a7a"
INK = "#1d1b1a"
SILVER = "#d6dce0"

FRAME = f"""<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<defs>
<radialGradient id="lac" cx=".42" cy=".36" r=".75"><stop offset="0" stop-color="#3d3530"/><stop offset=".7" stop-color="#1f1d1c"/><stop offset="1" stop-color="#121314"/></radialGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{LIGHT}"/><stop offset=".55" stop-color="{GOLD}"/><stop offset="1" stop-color="{DEEP}"/></linearGradient>
<radialGradient id="glow" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="{GOLD}" stop-opacity=".28"/><stop offset="1" stop-color="{GOLD}" stop-opacity="0"/></radialGradient>
</defs>
<circle cx="256" cy="256" r="238" fill="url(#lac)"/>
<circle cx="256" cy="256" r="190" fill="url(#glow)"/>
<circle cx="256" cy="256" r="238" fill="none" stroke="url(#gold)" stroke-width="9"/>
<circle cx="256" cy="256" r="216" fill="none" stroke="{GOLD}" stroke-opacity=".55" stroke-width="2"/>
{{ring}}
<g stroke-linecap="round" stroke-linejoin="round">
{{art}}
</g>
</svg>
"""


def ring_marks():
    marks = []
    for i in range(8):
        a = i * 45
        size = 9 if i % 2 == 0 else 5
        marks.append(f'<rect x="{256 - size}" y="{29 - size}" width="{size * 2}" height="{size * 2}" fill="{GOLD}" transform="rotate({a} 256 256) rotate(45 256 {29})"/>')
    return "\n".join(marks)


def coin(x, y, r=22):
    s = r * 0.36
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#gold)" stroke="{LIGHT}" stroke-width="3"/>'
            f'<circle cx="{x}" cy="{y}" r="{r * 0.72}" fill="none" stroke="{DEEP}" stroke-width="2"/>'
            f'<rect x="{x - s}" y="{y - s}" width="{s * 2}" height="{s * 2}" fill="{INK}" stroke="{DEEP}" stroke-width="2"/>')


ART = {
    # 遗失的钱囊: an embroidered drawstring purse dropped on the road, coins spilling.
    "purse": f"""
<path d="M188 236 C140 280 146 372 256 376 C366 372 372 280 324 236 Z" fill="url(#gold)" stroke="{LIGHT}" stroke-width="5"/>
<path d="M196 238 Q256 216 316 238 L304 206 Q256 192 208 206 Z" fill="{RED}" stroke="{LIGHT}" stroke-width="4"/>
<path d="M214 204 Q186 168 214 148 Q236 136 246 160" fill="none" stroke="{RED}" stroke-width="7"/>
<path d="M246 160 l-6 40 M246 160 l10 38" stroke="{RED}" stroke-width="5"/>
<circle cx="256" cy="304" r="30" fill="none" stroke="{DEEP}" stroke-width="4"/>
<path d="M256 282 L276 304 L256 326 L236 304 Z" fill="none" stroke="{RED}" stroke-width="4"/>
{coin(352, 352)}{coin(318, 384, 18)}""",

    # 山野药庐: a medicine gourd tied with cord, herb leaves at the stem, steam rising.
    "apothecary": f"""
<path d="M200 168 q14 -16 0 -32 M256 150 q14 -16 0 -32 M312 168 q14 -16 0 -32" fill="none" stroke="{IVORY}" stroke-opacity=".55" stroke-width="5"/>
<circle cx="256" cy="312" r="70" fill="url(#gold)" stroke="{LIGHT}" stroke-width="5"/>
<circle cx="256" cy="222" r="44" fill="url(#gold)" stroke="{LIGHT}" stroke-width="5"/>
<rect x="222" y="252" width="68" height="16" rx="6" fill="{RED}" stroke="{LIGHT}" stroke-width="3"/>
<path d="M290 262 q26 22 12 58 M296 266 q34 10 40 44" fill="none" stroke="{RED}" stroke-width="5"/>
<rect x="248" y="166" width="16" height="16" fill="{DEEP}"/>
<path d="M256 172 C220 150 200 160 192 178 C214 186 238 184 256 172 Z" fill="{JADE}" stroke="{LIGHT}" stroke-width="3"/>
<path d="M256 172 C292 146 314 156 322 174 C300 184 274 184 256 172 Z" fill="{JADE}" stroke="{LIGHT}" stroke-width="3"/>
<path d="M226 312 q30 -28 60 0" fill="none" stroke="{DEEP}" stroke-width="4"/>""",

    # 贫寒村落: a humble house above a timber bridge broken by the flood.
    "village": f"""
<path d="M182 206 L256 156 L330 206 Z" fill="{RED}" stroke="{LIGHT}" stroke-width="5"/>
<path d="M168 210 Q256 196 344 210" fill="none" stroke="{GOLD}" stroke-width="6"/>
<rect x="200" y="210" width="112" height="62" fill="{IVORY}" stroke="{GOLD}" stroke-width="4"/>
<rect x="244" y="232" width="24" height="40" fill="{INK}" stroke="{GOLD}" stroke-width="3"/>
<path d="M140 336 Q186 290 232 302 L238 318 L226 326" fill="none" stroke="url(#gold)" stroke-width="12"/>
<path d="M284 300 L296 290 Q336 290 372 336" fill="none" stroke="url(#gold)" stroke-width="12"/>
<path d="M162 316 v26 M196 302 v34 M318 300 v36 M350 318 v24" stroke="{GOLD}" stroke-width="6"/>
<path d="M140 362 q20 -12 40 0 t40 0 t40 0 t40 0 t40 0 t40 0" fill="none" stroke="{IVORY}" stroke-opacity=".7" stroke-width="5"/>
<path d="M164 388 q20 -12 40 0 t40 0 t40 0 t40 0 t40 0" fill="none" stroke="{IVORY}" stroke-opacity=".4" stroke-width="4"/>""",

    # 暗巷赌局: an upturned dice cup and two dice under a lantern's light.
    "gamble": f"""
<path d="M206 156 L306 156 L324 262 L188 262 Z" fill="url(#gold)" stroke="{LIGHT}" stroke-width="5"/>
<ellipse cx="256" cy="262" rx="72" ry="14" fill="{DEEP}" stroke="{LIGHT}" stroke-width="4"/>
<path d="M212 196 H300 M206 226 H306" stroke="{DEEP}" stroke-width="4"/>
<rect x="226" y="142" width="60" height="16" rx="6" fill="{RED}" stroke="{LIGHT}" stroke-width="3"/>
<g transform="rotate(-12 222 330)"><rect x="190" y="298" width="64" height="64" rx="10" fill="{IVORY}" stroke="{GOLD}" stroke-width="4"/>
<circle cx="222" cy="330" r="10" fill="{RED}"/></g>
<g transform="rotate(14 306 340)"><rect x="274" y="308" width="64" height="64" rx="10" fill="{IVORY}" stroke="{GOLD}" stroke-width="4"/>
<circle cx="290" cy="324" r="7" fill="{INK}"/><circle cx="306" cy="340" r="7" fill="{INK}"/><circle cx="322" cy="356" r="7" fill="{INK}"/></g>""",

    # 落魄行商: a peddler's carrying pole with two laden baskets.
    "merchant": f"""
<path d="M136 196 Q256 176 376 196" fill="none" stroke="url(#gold)" stroke-width="12"/>
<path d="M178 192 L160 262 M178 192 L206 262 M334 192 L306 262 M334 192 L352 262" stroke="{GOLD}" stroke-width="4"/>
<path d="M148 262 H218 L208 336 H158 Z" fill="url(#gold)" stroke="{LIGHT}" stroke-width="4"/>
<path d="M294 262 H364 L354 336 H304 Z" fill="url(#gold)" stroke="{LIGHT}" stroke-width="4"/>
<path d="M154 286 H212 M156 310 H210 M300 286 H358 M302 310 H356" stroke="{DEEP}" stroke-width="3"/>
<rect x="160" y="238" width="46" height="24" rx="10" fill="{RED}" stroke="{LIGHT}" stroke-width="3"/>
<circle cx="316" cy="250" r="14" fill="{IVORY}" stroke="{GOLD}" stroke-width="3"/><circle cx="344" cy="252" r="12" fill="{JADE}" stroke="{GOLD}" stroke-width="3"/>""",

    # 旧物置换: two curved arrows trading around a jade disc.
    "exchange": f"""
<path d="M168 228 A92 92 0 0 1 330 194" fill="none" stroke="url(#gold)" stroke-width="12"/>
<path d="M314 160 L346 202 L296 214 Z" fill="{GOLD}" stroke="{LIGHT}" stroke-width="3"/>
<path d="M344 284 A92 92 0 0 1 182 318" fill="none" stroke="url(#gold)" stroke-width="12"/>
<path d="M198 352 L166 310 L216 298 Z" fill="{GOLD}" stroke="{LIGHT}" stroke-width="3"/>
<circle cx="256" cy="256" r="54" fill="{JADE}" stroke="{LIGHT}" stroke-width="5"/>
<circle cx="256" cy="256" r="18" fill="{INK}" stroke="{LIGHT}" stroke-width="3"/>
<circle cx="256" cy="256" r="38" fill="none" stroke="{IVORY}" stroke-opacity=".55" stroke-width="2" stroke-dasharray="6 8"/>""",

    # 残碑秘藏: a cracked stele whose inscription still glows.
    "inscription": f"""
<path d="M206 196 Q206 150 256 150 Q306 150 306 196 L306 214 L262 238 L236 206 L206 222 Z" fill="{IVORY}" stroke="{GOLD}" stroke-width="5" transform="rotate(-8 256 190) translate(-10 -14)"/>
<path d="M206 236 L236 220 L262 252 L306 228 V362 H206 Z" fill="{IVORY}" stroke="{GOLD}" stroke-width="5"/>
<rect x="182" y="362" width="148" height="22" rx="4" fill="url(#gold)" stroke="{LIGHT}" stroke-width="4"/>
<path d="M232 270 h48 M232 294 h36 M232 318 h48 M232 342 h28" stroke="{RED}" stroke-width="7"/>
<circle cx="256" cy="306" r="70" fill="url(#glow)"/>
<path d="M214 174 h40 M222 190 h26" stroke="{DEEP}" stroke-width="5" transform="rotate(-8 256 190) translate(-10 -14)"/>""",

    # 无主遗藏: a secret niche opened in an old wall, a silver ingot inside.
    "cache": f"""
<path d="M152 168 H360 V360 H152 Z" fill="#3a332d" stroke="{GOLD}" stroke-width="5"/>
<path d="M152 216 H360 M152 264 H360 M152 312 H360 M204 168 v48 M308 168 v48 M256 216 v48 M180 264 v48 M332 264 v48 M228 312 v48 M292 312 v48" stroke="{DEEP}" stroke-width="3"/>
<rect x="196" y="228" width="120" height="96" fill="{INK}" stroke="{GOLD}" stroke-width="5"/>
<path d="M196 228 L156 248 V344 L196 324 Z" fill="url(#gold)" stroke="{LIGHT}" stroke-width="4"/>
<circle cx="174" cy="296" r="5" fill="{INK}"/>
<path d="M212 300 Q226 316 256 316 Q286 316 300 300 L288 290 Q272 300 256 300 Q240 300 224 290 Z" fill="{SILVER}" stroke="#ffffff" stroke-width="3"/>
<ellipse cx="256" cy="292" rx="20" ry="12" fill="{SILVER}" stroke="#ffffff" stroke-width="3"/>""",

    # 悬赏凶徒: a wanted notice nailed up, portrait and red seal.
    "bounty": f"""
<g transform="rotate(-4 256 262)">
<rect x="186" y="156" width="140" height="210" fill="{IVORY}" stroke="{GOLD}" stroke-width="5"/>
<path d="M208 182 h96" stroke="{RED}" stroke-width="9"/>
<circle cx="256" cy="244" r="30" fill="{INK}"/>
<path d="M206 316 Q206 280 256 280 Q306 280 306 316 Z" fill="{INK}"/>
<path d="M208 334 h64 M208 350 h44" stroke="{DEEP}" stroke-width="5"/>
<rect x="282" y="326" width="30" height="30" fill="{RED}"/><rect x="287" y="331" width="20" height="20" fill="none" stroke="{IVORY}" stroke-width="2"/>
</g>
<circle cx="256" cy="150" r="10" fill="{RED}" stroke="{LIGHT}" stroke-width="3"/>""",

    # 护送商队: an escort banner over a cart wheel.
    "escort": f"""
<path d="M196 140 V372" stroke="url(#gold)" stroke-width="10"/>
<circle cx="196" cy="136" r="9" fill="{GOLD}" stroke="{LIGHT}" stroke-width="3"/>
<path d="M200 154 H334 Q318 190 334 226 H200 Z" fill="{RED}" stroke="{LIGHT}" stroke-width="5"/>
<path d="M256 168 L278 190 L256 212 L234 190 Z" fill="none" stroke="{LIGHT}" stroke-width="4"/>
<circle cx="290" cy="316" r="54" fill="none" stroke="url(#gold)" stroke-width="10"/>
<circle cx="290" cy="316" r="12" fill="{GOLD}" stroke="{LIGHT}" stroke-width="3"/>
<path d="M290 262 V370 M236 316 H344 M252 278 L328 354 M328 278 L252 354" stroke="{GOLD}" stroke-width="5"/>""",

    # 守宝强敌: a bound treasure chest behind two crossed halberds.
    "guardian": f"""
<path d="M168 150 L344 372 M344 150 L168 372" stroke="{IVORY}" stroke-opacity=".85" stroke-width="8"/>
<path d="M156 136 l26 4 l-8 24 Z M356 136 l-26 4 l8 24 Z" fill="{SILVER}" stroke="#ffffff" stroke-width="3"/>
<path d="M190 238 Q190 196 256 196 Q322 196 322 238 Z" fill="url(#gold)" stroke="{LIGHT}" stroke-width="5"/>
<rect x="186" y="238" width="140" height="96" fill="{RED}" stroke="{LIGHT}" stroke-width="5"/>
<path d="M218 198 V334 M294 198 V334" stroke="{GOLD}" stroke-width="8"/>
<rect x="240" y="244" width="32" height="40" rx="4" fill="url(#gold)" stroke="{LIGHT}" stroke-width="3"/>
<circle cx="256" cy="260" r="6" fill="{INK}"/><rect x="253" y="262" width="6" height="12" fill="{INK}"/>""",

    # 负伤高手: a sword planted in the ground, its hilt bound with a bloodied cloth.
    "wounded": f"""
<path d="M256 214 L272 230 L264 376 L256 392 L248 376 L240 230 Z" fill="{SILVER}" stroke="#ffffff" stroke-width="4"/>
<path d="M256 236 V370" stroke="#9aa4aa" stroke-width="3"/>
<rect x="204" y="200" width="104" height="18" rx="8" fill="url(#gold)" stroke="{LIGHT}" stroke-width="4"/>
<rect x="246" y="140" width="20" height="62" rx="6" fill="{INK}" stroke="{GOLD}" stroke-width="4"/>
<circle cx="256" cy="134" r="12" fill="url(#gold)" stroke="{LIGHT}" stroke-width="3"/>
<path d="M238 252 L276 238 M236 270 L278 256 M238 288 L276 274" stroke="{IVORY}" stroke-width="10"/>
<path d="M276 238 Q306 250 300 290 Q296 312 312 330" fill="none" stroke="{IVORY}" stroke-width="8"/>
<circle cx="262" cy="262" r="10" fill="{RED}" fill-opacity=".85"/>
<path d="M330 312 q8 14 0 22 q-8 -8 0 -22 Z M314 350 q7 12 0 19 q-7 -7 0 -19 Z M340 362 q6 10 0 16 q-6 -6 0 -16 Z" fill="{RED}"/>
<path d="M200 392 q56 -14 112 0" fill="none" stroke="{DEEP}" stroke-width="6"/>""",
}


def main() -> None:
    out = os.path.join("art", "events")
    os.makedirs(out, exist_ok=True)
    for event_id, art in ART.items():
        svg = FRAME.replace("{ring}", ring_marks()).replace("{art}", art.strip())
        with open(os.path.join(out, event_id + ".svg"), "w", encoding="utf-8", newline="\n") as handle:
            handle.write(svg)
    print("wrote", len(ART), "emblems to", out)


if __name__ == "__main__":
    main()

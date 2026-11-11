# Icon style guide (BG:EE / BG2:EE spellbook glyphs)

Target look: the vanilla Baldur's Gate spellbook icons. Flat single-color glyphs on a TRANSPARENT
background, one bold symbol, shown on papyrus (spellbook) and on a dark stone bar (action bar).
NOT painted scenes, NOT multicolor. See /home/claude/preview/vanilla_zoom.png for vanilla icons and
/home/claude/preview/batch1_zoom.png + batch1.py for 8 finished icons in the approved style.

## Library

`/home/claude/glyph.py` (do NOT edit it; put your own helpers in your own script):
- `g=Glyph()` gives four 512x512 drawing layers (16 px of canvas = 1 game pixel):
  - `g.f` body (fill=255), `g.c` cut-outs (holes, transparent), `g.d` dark details, `g.l` light details.
- `g.render(color, "B24XXXXX")` reduces to 32x32, adds the emboss (light top-left edge, shadow
  bottom-right edge), saves `/home/claude/art/icons/B24XXXXX.png` (64x64, nearest-doubled) and returns the 32px image.
- `preview(list_of_(name, img), path)` papyrus comparison sheet; build an 8x zoom sheet like the end of batch1.py.
- `T(pts,s,dx,dy)` scale/shift points around the center; `fist(g,s,dx,dy)` a clenched fist.

## Colors (pick ONE per icon) — rule by what the ability does

- `red`: offense — damage, attack buffs, rage, smites, fear/frighten, enmity, offensive cantrips.
- `teal`: defense and restoration — healing, temp HP, protection, AC, resistance, invisibility/hiding, movement, shielding.
- `cream`: divine light/radiant, divination/seeing, and the "choose something" pickers (ASI, Subclass, Spellbook, Cantrip, Class Feature, Fighting Style, Weapon Mastery, Expertise...).

## Rules learned so far

1. The glyph must FILL the frame: roughly 26-30 of 32 pixels in its larger dimension. Use most of 0..512.
2. Bold shapes only. Anything narrower than ~32 canvas px (2 game px) vanishes or becomes noise.
   Spikes and rays must have wide bases. Flames = fat tongues, not needles.
3. Max 2-3 elements per icon. One main symbol, at most one secondary element.
4. Details: on teal, dark details barely show — use cut-outs (`g.c`) or light details (`g.l`).
   On red, dark details and light (peach) details both work. Cut-outs need >= 2 game px width.
5. Families share a motif:
   - Battle Master maneuvers: each has a small die (a square/diamond d6-ish shape, ~6x6 game px) in the lower-right corner, the rest is the maneuver.
   - Starry Forms (Archer/Chalice/Dragon): constellation look — a few big star dots (>=3 px) joined by lines, shaped as the figure.
   - Create Spell Slot 1-5: the same gem/crystal glyph, with 1..5 dots (pips) under it.
   - Psionic abilities (Psionic Strike, Guarded Mind, Bulwark, Psychic Blades, Psychic Veil): share a small "mind spiral/eye" accent.
6. No text, letters or numbers. A die may show pips.
7. Always look at your 8x zoom sheet (Read the PNG) and fix what doesn't read. Iterate until every icon
   is recognizable at 32x32. Typically 2-3 passes. Avoid duplicates of vanilla-looking simple crosses unless it is healing.

The motif ideas in /mnt/user-data/uploads/Icon_prompts.md are painterly scenes — simplify each to ONE glyph.
The ability descriptions are in /mnt/user-data/uploads/Icon_briefs.md.

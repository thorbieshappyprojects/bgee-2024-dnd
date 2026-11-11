# Icon prompts

Image prompts for the 171 icons of the mod's spells, cantrips and abilities (168 images; the
others are copies). Generated from `art/icon-prompts.txt` by `tools/icon-prompts.pl`: edit a motif
there and run the script again.

## How to use

1. Copy the prompt of an icon (each one is complete: motif and style) into the image generator.
   Where the tool has a separate field for it, use the negative prompt below.
2. Settings: square (1:1), 512x512 or 1024x1024, PNG. Generate a few and pick the one whose
   shape still reads when you shrink it to 32x32 pixels: the game shows icons that small.
3. Save the image as `art/icons/<file name>` exactly as given in the heading (for example
   `art/icons/B24SWIND.png`).
4. Run `perl tools/png2bam.pl art/icons icons`, then install (`.\deploy.ps1`). The spell or ability
   uses its new icon in both games; icons you haven't made yet keep their borrowed vanilla icon.

Copies (marked "same image as") need no image of their own: copy the other PNG under the new name.

## Shared style

Every prompt below ends with this style text, so all icons look like one set:

> Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.

**Negative prompt:**

> text, letters, numbers, watermark, signature, border, frame, button, user interface, photograph, 3D render, blurry, multiple separate subjects, cluttered background, tiny details, white background

Colors follow the ability's theme (fire orange-red, cold pale blue, lightning white-blue, acid and
poison green, radiant gold-white, necrotic purple-black or sickly green, psychic violet, healing
green-white, martial steel and red, nature brown-green). Recurring motifs keep families together:
Battle Master maneuvers show a small golden die, psionic abilities are violet, Starry Forms are
constellations, Create Spell Slot shows one to five points of light.

## Species and origin feats (8)

### 1. Adrenaline Rush - `B24ADREN.png`

```text
A roaring orc warrior's face with glowing red eyes, red veins pulsing on the temples, speed streaks behind the head; blood red and dark green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 2. Battle Medic - `B24HEALR.png`

```text
A battlefield healer's hands wrapping a clean linen bandage around a wounded forearm, a small leather satchel of herbs beside it; earthy brown, white and soft green glow. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 3. Healing Hands - `B24HEALH.png`

```text
Two open hands radiating soft golden-white light, tiny white feathers drifting upward from the palms; gold and pearl white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 4. Fire's Burn - `B24GLFIR.png`

```text
A huge grey stone-skinned fist wreathed in roaring flames; fiery orange and red on charcoal. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 5. Frost's Chill - `B24GLFRO.png`

```text
A giant's hand gripping a battleaxe whose blade is coated in thick frost and jagged ice shards; pale icy blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 6. Hill's Tumble - `B24GLHIL.png`

```text
A massive earthen club slamming into the ground, a small figure toppling backward in a burst of dust and pebbles; ochre and brown. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 7. Stone's Endurance - `B24GLSTO.png`

```text
A muscular forearm turning to grey granite as a sword blade breaks against it, chips of stone flying; grey stone with a faint blue sheen. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 8. Storm's Thunder - `B24GLSTM.png`

```text
A raised giant's fist crackling with a branching lightning bolt that arcs up into dark storm clouds; electric white-blue on deep slate. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Core rules (4)

### 9. Short Rest - `B24SREST.png`

```text
A small campfire at dusk with a rolled bedroll and a sword leaning against a log, thin smoke curling upward; warm orange firelight on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 10. Turn-Based Combat - `B24TURNS.png`

```text
An hourglass standing on a battle map with small carved figures lined up in a row before it; gold sand, dark wood and parchment. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 11. End Turn - `B24TEND.png`

```text
An hourglass laid on its side with the sand stopped, a hand resting flat beside it; dull gold and grey. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 12. Escape Grapple - `B24ESCGR.png`

```text
A hand wrenching free from a larger gripping hand, the fingers slipping apart with a burst of motion lines; tan skin and bright orange. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Class features (58)

### 13. Second Wind - `B24SWIND.png`

```text
A battle-worn warrior's silhouette taking a deep breath, a swirl of pale green wind coiling around the chest and lifting the cloak; steel grey and soft green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 14. Action Surge - `B24ASURG.png`

```text
A sword caught mid-swing leaving three golden afterimage arcs, sparks bursting at the tip; bright gold on dark steel. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 15. Tactical Master - `B24TMAST.png`

```text
A sword, an axe and a mace crossed in a star pattern around a small glowing compass rose; polished steel and crimson. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 16. Ability Score Improvement - `B24ASI.png`

```text
A glowing golden arrow rising out of a carved stone pedestal set with six small colored gemstones; gold and deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 17. Fighting Style - `B24FSTY.png`

```text
A sword and a round shield crossed in front of an old parchment sketch of a fencing stance; steel, brown parchment and red. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 18. Weapon Mastery - `B24WMAS.png`

```text
A single gleaming longsword standing upright, a line of glowing runes running along its fuller; polished steel with cold blue light. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 19. Subclass - `B24SUBC.png`

```text
A stone path that splits into three glowing branches like a crossroads, seen from above; gold light on dark earth. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 20. Rage - `B24RAGE.png`

```text
A screaming barbarian's face with red war paint and glowing red eyes, a crimson aura flaring around the head; blood red and black. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 21. Reckless Attack - `B24RECKL.png`

```text
A huge two-handed greataxe swung overhead in a wild arc, red sparks and torn air trailing the blade; red and dark steel. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 22. Intimidating Presence - `B24INTIM.png`

```text
A towering horned warrior silhouette casting an enormous dark shadow, tiny figures fleeing at its feet; black and blood red. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 23. Cunning Action - `B24CUNNG.png`

```text
A hooded rogue dashing to the side, long motion blur streaks behind, a dagger glinting in one hand; charcoal grey with yellow highlights. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 24. Steady Aim - `B24STAIM.png`

```text
A close-up of a drawn crossbow with an eye aligned along the bolt, a faint glowing aiming circle at the tip; wood brown and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 25. Expertise - `B24EXPRT.png`

```text
A master's hands holding a set of lockpicks above an open book, a small bright star shining over them; deep blue and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 26. Flurry of Blows - `B24FLURY.png`

```text
Several bare fists punching outward in a fan, orange impact bursts and motion lines; tan skin tones and fiery orange. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 27. Patient Defense - `B24PDEF.png`

```text
A monk in a calm defensive stance with palms raised, a translucent blue circle of calm around the body; serene blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 28. Step of the Wind - `B24STEPW.png`

```text
A bare foot leaping off swirling white wind currents, loose cloth fluttering; white and pale teal. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 29. Stunning Strike - `B24STUN.png`

```text
A fist striking a forehead, a bright shockwave ring and small yellow stars bursting from the impact; yellow and orange. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 30. Uncanny Metabolism - `B24UMETA.png`

```text
A meditating monk with a glowing amber spiral at the belly, warm energy rising up the spine; amber and bronze. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 31. Wholeness of Body - `B24WHOLE.png`

```text
A seated meditating figure outlined in soft green light, a glowing lotus flower floating before the chest; green and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 32. Superior Defense - `B24SUPDF.png`

```text
A monk silhouette inside a shimmering crystalline aura, arrows and blades bouncing off its surface; violet and silver. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 33. Quivering Palm - `B24QPALM.png`

```text
An open palm pressed against a chest, concentric violet vibration rings rippling outward from the touch; deep violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 34. Lay on Hands - `B24LOH.png`

```text
An armored gauntlet laid gently on a wounded shoulder, warm golden light flowing from the palm; gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 35. Divine Smite - `B24SMITE.png`

```text
A longsword striking downward, the blade wreathed in blinding holy light and a burst of golden rays; brilliant gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 36. Sacred Weapon - `B24SACWP.png`

```text
A longsword raised high, its blade glowing with radiant white light that spills over the hilt; white and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 37. Abjure Foes - `B24ABJUR.png`

```text
A holy symbol held aloft casting a cone of golden light, dark shadowy shapes recoiling from it; gold on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 38. Holy Nimbus - `B24NIMBS.png`

```text
An armored paladin silhouette inside a blazing ring of sunlight, rays streaming outward; brilliant gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 39. Hunter's Mark - `B24HMARK.png`

```text
A glowing green hunter's sigil hovering over the silhouette of a running stag; emerald green on dark forest. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 40. Tireless - `B24TIRLS.png`

```text
A ranger's worn leather boots striding along a forest path, a green-gold glow of vigor around them; green and brown. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 41. Nature's Veil - `B24NVEIL.png`

```text
A ranger fading into foliage, half of the body dissolving into swirling green leaves; leaf green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 42. Bardic Inspiration - `B24BINSP.png`

```text
A lute with glowing musical notes spiraling upward from its strings; royal purple and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 43. Divine Spark - `B24DSPRK.png`

```text
A single bright spark of light floating between two cupped hands, one half glowing healing green, the other radiant gold; green, gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 44. Turn Undead - `B24TURNU.png`

```text
A raised holy symbol blazing with light, skeletal hands recoiling and crumbling in its glare; gold and sickly green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 45. Preserve Life - `B24PRSLF.png`

```text
A glowing heart of warm light sending rays to three small kneeling figures; warm white and green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 46. Land's Aid - `B24LAID.png`

```text
A ring of thorny vines bursting from cracked earth, a soft green healing glow in the center of the ring; dark green and brown. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 47. Innate Sorcery - `B24INSOR.png`

```text
A sorcerer's hand with veins glowing with arcane energy, purple sparks crackling between the fingers; purple and magenta. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 48. Class Feature - `B24OPTN.png`

```text
An ornate golden key set with a glowing gem, hovering above two diverging paths; gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 49. Cantrip - `B24CANTP.png`

```text
A small dancing spark of magic floating above an outstretched fingertip, a thin trail of light; bright blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 50. Spellbook - `B24SPBK.png`

```text
An open leather-bound spellbook with one freshly glowing page, a quill writing glowing runes onto it; brown leather and arcane blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 51. Class Feature Choice - `B24PICK.png`

```text
An ornate scroll unrolling with three glowing wax seals; parchment and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 52. Careful Spell - `B24MMCAR.png`

```text
A glowing violet spell orb held inside two cupped hands that shield a small figure behind them from its sparks; violet and soft gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 53. Empowered Spell - `B24MMEMP.png`

```text
A crackling arcane fireball swelling larger, extra jagged energy bursting from its surface; deep violet and orange. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 54. Extended Spell - `B24MMEXT.png`

```text
An arcane rune circle stretched long like a ribbon unrolling through the air, an hourglass motif at its center; violet and silver. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 55. Heightened Spell - `B24MMHEI.png`

```text
A spell sigil blazing intensely above an outstretched palm, sharp rays piercing downward; white-hot violet on black. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 56. Quickened Spell - `B24MMQUI.png`

```text
A spell rune streaking forward with motion blur lines like a shooting star; violet and electric blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 57. Seeking Spell - `B24MMSEE.png`

```text
A glowing magical bolt curving around an obstacle toward a target, a bright trail behind it; violet and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 58. Transmuted Spell - `B24MMTRA.png`

```text
A single orb of energy split into four colored quarters of fire, frost, lightning and acid swirling into each other; red, pale blue, white and green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 59. Innate Sorcery (Sorcery Incarnate) - `B24INSO2.png`

```text
A sorcerer's silhouette blazing with arcane energy from within, sorcery points like violet sparks spiraling inward; violet and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 60. Divine Intervention - `B24CDIVI.png`

```text
A beam of radiant light breaking through dark clouds onto a kneeling cleric with raised arms; gold and white on dark blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 61. Wild Companion - `B24WCOMP.png`

```text
A translucent spirit wolf made of green light padding beside a druid's staff; emerald green and silver. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 62. Wild Resurgence: Spell Slot to Wild Shape - `B24WRES1.png`

```text
A glowing spell rune dissolving into the silhouette of a leaping beast; green and violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 63. Wild Resurgence: Wild Shape to Spell Slot - `B24WRES2.png`

```text
The silhouette of a beast dissolving into a glowing spell rune; violet and green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 64. Nature Magician - `B24NMAGI.png`

```text
An ancient druid's hands weaving vines and leaves into a glowing arcane circle; green and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 65. Cunning Strike: Poison - `B24RCPOI.png`

```text
A dagger blade dripping with thick green poison; dark steel and toxic green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 66. Cunning Strike: Trip - `B24RCTRP.png`

```text
A booted foot sweeping an opponent's legs out from under them; leather brown and grey. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 67. Cunning Strike: Withdraw - `B24RCWTH.png`

```text
A cloaked rogue leaping backward out of reach in a swirl of shadow; dark grey and deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 68. Devious Strike: Daze - `B24RCDAZ.png`

```text
A stunned face with small spinning stars circling the head; pale yellow and purple. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 69. Devious Strike: Knock Out - `B24RCKNO.png`

```text
A dagger pommel striking the back of a head, a burst of white impact lines; steel and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 70. Devious Strike: Obscure - `B24RCOBS.png`

```text
A rogue flinging a cloud of dark dust into an enemy's eyes; charcoal and grey. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Spells (10)

### 71. Healing Word - `B24HWORD.png`

```text
A softly glowing rune of green-white light flying like a small bird toward a distant figure; green and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 72. Healing Word (bard copy) - `B24HWBRD.png`

Same image as **Healing Word** (`B24HWORD.png`): copy that PNG as `B24HWBRD.png`.

### 73. Cure Wounds (bard copy) - `B24CWBRD.png`

```text
A hand pressed on a bleeding wound that closes under green-white light; green, white and skin tones. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 74. Guiding Bolt - `B24GBOLT.png`

```text
A bolt of brilliant white-gold light streaking diagonally toward a target, sparkles trailing it; white and gold on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 75. Thunderwave - `B24THWAV.png`

```text
A concussive blue-grey shockwave ring blasting outward from a caster's open palms, dust and debris thrown back; slate blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 76. Thunderwave (druid copy) - `B24THWVD.png`

Same image as **Thunderwave** (`B24THWAV.png`): copy that PNG as `B24THWVD.png`.

### 77. Shatter - `B24SHATR.png`

```text
A crystal sphere exploding into sharp shards, visible sound-wave rings rippling out; silver and icy blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 78. Spirit Guardians - `B24SPGRD.png`

```text
Translucent angelic spirits holding spears, circling around a central figure; radiant gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 79. Mass Healing Word - `B24MHWRD.png`

```text
Several small glowing green-white runes flying outward in all directions toward small figures; green and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 80. Mass Healing Word (bard copy) - `B24MHWBD.png`

Same image as **Mass Healing Word** (`B24MHWRD.png`): copy that PNG as `B24MHWBD.png`.

## Cantrips (14)

### 81. Acid Splash - `B24CACID.png`

```text
A globe of bubbling green acid bursting apart, droplets splashing outward and smoking; acid green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 82. Chill Touch - `B24CCHIL.png`

```text
A ghostly skeletal hand made of pale mist reaching forward; pale green and white on black. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 83. Fire Bolt - `B24CFIRE.png`

```text
A streaking bolt of fire with a white-hot core and a trail of embers; orange, red and yellow. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 84. Poison Spray - `B24CPOIS.png`

```text
A jet of noxious green-yellow mist spraying from an open palm; sickly green and yellow. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 85. Ray of Frost - `B24CFROS.png`

```text
A pale blue beam shooting forward, ice crystals forming along its length; icy blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 86. Shocking Grasp - `B24CSHOC.png`

```text
An outstretched hand crackling with branching white-blue lightning arcs; electric blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 87. Sorcerous Burst - `B24CBURS.png`

```text
An orb of raw magic exploding in sparks, streaks of red, blue and green flying outward; multicolored on dark. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 88. Sacred Flame - `B24CSACR.png`

```text
A column of radiant white-gold flame descending from above onto a small figure; gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 89. Toll the Dead - `B24CTOLL.png`

```text
A spectral iron bell swinging and tolling, sickly green ripples of sound spreading out; grey iron and sickly green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 90. Word of Radiance - `B24CWORD.png`

```text
A burst of golden light radiating in a ring from a raised holy symbol; brilliant gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 91. Produce Flame - `B24CFLAM.png`

```text
A small steady flame flickering in an open palm, lighting the fingers from below; warm orange. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 92. Thorn Whip - `B24CTHRN.png`

```text
A thorny green vine lashing through the air like a whip; deep green and brown. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 93. Starry Wisp - `B24CWISP.png`

```text
A small mote of starlight with a sparkling trail crossing a night sky; silver-white on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 94. Vicious Mockery - `B24CMOCK.png`

```text
A grinning jester's mask with violet psychic sparks crackling around it; violet and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Subclass features (74)

### 95. Trip Attack - `B24MTRIP.png`

```text
A sword sweeping the legs of a falling enemy, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 96. Pushing Attack - `B24MPUSH.png`

```text
A shield bash shoving an enemy backward with a shockwave, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 97. Menacing Attack - `B24MMENA.png`

```text
A sword strike throwing off a menacing red skull-shaped spark, a small glowing golden die in the lower corner; steel, red and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 98. Disarming Attack - `B24MDISA.png`

```text
A sword knocking a weapon spinning out of an enemy's hand, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 99. Distracting Strike - `B24MDIST.png`

```text
A sword feint flashing light toward an enemy's eyes while an ally's spear comes in from the side, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 100. Goading Attack - `B24MGOAD.png`

```text
A sword pointing at a snarling enemy, red taunting sparks between them, a small glowing golden die in the lower corner; steel, red and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 101. Feinting Attack - `B24MFEIN.png`

```text
A sword thrust shown as two overlapping images, one false and one real, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 102. Precision Attack - `B24MPREC.png`

```text
A sword tip striking the exact center of a tiny glowing bullseye, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 103. Lunging Attack - `B24MLUNG.png`

```text
A fencer lunging far forward with a long motion streak behind, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 104. Sweeping Attack - `B24MSWEE.png`

```text
A wide arcing sword slash cutting across two enemies at once, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 105. Parry - `B24MPARR.png`

```text
Two blades crossing with sparks bursting at the point of contact, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 106. Rally - `B24MRALY.png`

```text
A raised war banner and a curved horn, a warm golden glow around them, a small glowing golden die in the lower corner; red cloth and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 107. Evasive Footwork - `B24MEVAS.png`

```text
Armored boots sidestepping with faint afterimages, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 108. Commander's Strike - `B24MCOMM.png`

```text
A commander's gauntlet pointing forward while an ally's sword strikes past it, a small glowing golden die in the lower corner; steel and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 109. Psionic Strike - `B24PSTRK.png`

```text
A sword blade glowing with violet psionic energy at the moment of impact, a burst of violet force; violet and steel. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 110. Guarded Mind - `B24PGMND.png`

```text
The silhouette of a head with a glowing violet shield around the mind; violet on dark. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 111. Bulwark of Force - `B24PBULW.png`

```text
A translucent violet dome of force over a small group of figures, its surface shimmering; violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 112. Branches of the Tree - `B24WTBRN.png`

```text
Glowing green-gold tree branches lashing out of the ground and snaring a figure; green and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 113. Warrior of the Gods - `B24ZWARG.png`

```text
A battered warrior bathed in a beam of divine light from above, wounds closing; gold and red. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 114. Zealous Presence - `B24ZPRES.png`

```text
A roaring warrior with a golden divine aura, a war-cry shockwave spreading from the mouth; gold and crimson. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 115. Beguiling Magic - `B24GBEGU.png`

```text
A beautiful fey mask in a shimmering pink haze, a frightened eye peering out from behind it; rose pink and violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 116. Mantle of Inspiration - `B24GMANT.png`

```text
A shimmering cloak billowing outward, sparkles of pink-gold fey light streaming from its hem; pink and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 117. Mantle of Majesty - `B24GMAJE.png`

```text
A radiant fey crown floating above a figure, beams of soft pink light; pink, gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 118. Command - `B24GCMND.png`

```text
A hand pointing downward with a regal pink glow, a small figure kneeling before it; pink and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 119. Unbreakable Majesty - `B24GUNBR.png`

```text
A regal figure behind a radiant crystalline aura, a thrown spear shattering against it; pink, white and silver. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 120. Radiance of the Dawn - `B24LRADI.png`

```text
A sunrise bursting from a raised holy symbol, golden rays driving back darkness; brilliant gold and orange. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 121. Warding Flare - `B24LWARD.png`

```text
A blinding flash of white light erupting from the face of a shield; white and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 122. Corona of Light - `B24LCORO.png`

```text
A blazing halo ring of sunlight hovering in the darkness; gold on black. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 123. Blessing of the Trickster - `B24TBLES.png`

```text
A hooded figure fading into shadow, a sly green sparkle at the fingertips; dark grey and green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 124. Invoke Duplicity - `B24TDUPL.png`

```text
A cloaked figure and its translucent shimmering illusory double standing side by side; dark grey and pale cyan. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 125. Guided Strike - `B24WGSTR.png`

```text
A sword guided by a ghostly divine hand wrapped around the hilt, golden light along the blade; gold and steel. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 126. War God's Blessing - `B24WGBLS.png`

```text
A war god's huge gauntleted hand blessing an ally's raised sword with red-gold fire; red and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 127. War Priest - `B24WPRST.png`

```text
A war mace and a holy symbol crossed, a red-gold glow behind them; red, gold and steel. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 128. Wrath of the Sea - `B24SWRAT.png`

```text
A churning sea-green wave curling around a figure, salt spray and foam flying; sea green and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 129. Starry Form: Archer - `B24STARC.png`

```text
A glowing constellation shaped like an archer drawing a bow, bright stars joined by thin lines; silver stars on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 130. Starry Form: Chalice - `B24STCHL.png`

```text
A glowing constellation shaped like a chalice, bright stars joined by thin lines; silver stars on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 131. Starry Form: Dragon - `B24STDRG.png`

```text
A glowing constellation shaped like a coiled dragon, bright stars joined by thin lines; silver stars on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 132. Luminous Arrow - `B24STARW.png`

```text
An arrow made of starlight streaking diagonally, a sparkling trail behind it; silver-white on deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 133. Hand of Harm - `B24MHARM.png`

```text
A striking hand wreathed in dark necrotic purple-black energy; purple and black. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 134. Hand of Healing - `B24MHHEL.png`

```text
An open hand touching a figure with warm green healing light; green and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 135. Shadow Arts - `B24MSART.png`

```text
A monk dissolving into darkness, wisps of shadow rising from the body; black and deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 136. Cloak of Shadows - `B24MCLOA.png`

```text
A figure wrapped in a cloak of living shadow, only the eyes faintly visible; black and dark violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 137. Shadow Step - `B24MSSTP.png`

```text
A figure stepping out of one pool of shadow into another a short distance away; black and deep blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 138. Elemental Attunement - `B24MATTN.png`

```text
Two fists wrapped in swirling icy wind and frost; icy blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 139. Elemental Burst - `B24MBRST.png`

```text
An explosion of icy elemental energy bursting outward from a single point; icy blue and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 140. Inspiring Smite - `B24GINSP.png`

```text
A sword strike bursting into a golden laurel wreath of light; gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 141. Nature's Wrath - `B24ANWRA.png`

```text
Spectral green vines erupting from the ground and binding a figure; ghostly green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 142. Vow of Enmity - `B24VVOWE.png`

```text
A glowing red sigil burning over an enemy's silhouette, a sword pointing at it; red and black. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 143. Living Legend - `B24GLEGD.png`

```text
A heroic armored silhouette standing in a golden laurel aura; gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 144. Elder Champion - `B24AELDR.png`

```text
A figure crowned with antlers of green light and blossoming flowers; green, gold and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 145. Avenging Angel - `B24VANGL.png`

```text
Dark feathered wings unfolding behind an armored figure; black and dark red. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 146. Primal Companion - `B24BEAST.png`

```text
A spectral wolf howling, wrapped in green primal energy; green and silver-grey. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 147. Psychic Blades - `B24PSBLA.png`

```text
A translucent violet blade of psychic energy materializing in a hand; violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 148. Psychic Veil - `B24PSVEL.png`

```text
A figure fading behind a shimmering violet veil; violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 149. Create Spell Slot (1) - `B24FOM1.png`

```text
A violet arcane gem cracking open into a glowing crystal sphere, one small glowing point of light beneath it; violet and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 150. Create Spell Slot (2) - `B24FOM2.png`

```text
A violet arcane gem cracking open into a glowing crystal sphere, two small glowing points of light beneath it; violet and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 151. Create Spell Slot (3) - `B24FOM3.png`

```text
A violet arcane gem cracking open into a glowing crystal sphere, three small glowing points of light beneath it; violet and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 152. Create Spell Slot (4) - `B24FOM4.png`

```text
A violet arcane gem cracking open into a glowing crystal sphere, four small glowing points of light beneath it; violet and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 153. Create Spell Slot (5) - `B24FOM5.png`

```text
A violet arcane gem cracking open into a glowing crystal sphere, five small glowing points of light beneath it; violet and white. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 154. Revelation in Flesh - `B24AREVL.png`

```text
An eye opening in the palm of a tentacled hand; sickly purple and green. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 155. Warping Implosion - `B24AWARP.png`

```text
Space collapsing inward into a black-violet singularity, debris spiraling in; black and violet. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 156. Restore Balance - `B24CBALN.png`

```text
A golden clockwork balance scale with both pans perfectly level; brass and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 157. Bastion of Law - `B24CBAST.png`

```text
A shield built from interlocking brass gears; brass and bronze. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 158. Trance of Order - `B24CTRAN.png`

```text
A meditating figure inside slowly rotating brass clockwork rings; brass and pale blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 159. Clockwork Cavalcade - `B24CCAVL.png`

```text
Spectral brass clockwork horses charging forward; brass and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 160. Tides of Chaos - `B24WTIDE.png`

```text
A swirling vortex of chaotic multicolored magic; multicolored on dark. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 161. Portent - `B24PORTN.png`

```text
Two dice floating before a glowing all-seeing eye; arcane blue and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 162. The Third Eye - `B24THEYE.png`

```text
A glowing third eye opening on a forehead; arcane blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 163. Dragon Wings - `B24DRWNG.png`

```text
Great leathery dragon wings unfurling from a sorcerer's back, scales glinting; deep red and bronze. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 164. Overchannel - `B24OVCHN.png`

```text
A wizard's hand overflowing with uncontrolled arcane lightning, veins glowing as the power hurts; electric blue and dark red. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 165. Nature's Sanctuary - `B24NSANC.png`

```text
A ring of spectral trees and roots rising around a small group of figures, sheltering them; forest green and gold light. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 166. Hand of Ultimate Mercy - `B24MULTM.png`

```text
A monk's open hand glowing with soft white light over a fallen figure, life returning as golden motes; white and gold. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 167. Tamed Surge - `B24WTAME.png`

```text
A wild swirl of chaotic multicolored magic held still inside a sorcerer's grasp; rainbow colors on black. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 168. Phantasmal Creatures - `B24IPHAN.png`

```text
A translucent shimmering wolf made of illusion, its edges dissolving into mist; pale lavender and silver. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Feats (3)

### 169. Speedy Recovery - `B24GDURB.png`

```text
A hardy warrior shrugging off wounds, a green glow of vitality around the body; green and steel. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 170. Grapple - `B24GGRAP.png`

```text
Two strong hands locking an opponent's arm in a grapple; skin tones and leather brown. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 171. Telekinetic Shove - `B24GTELE.png`

```text
An outstretched hand pushing a figure backward with a translucent rippling wave of force; pale blue. Hand-painted fantasy RPG spell icon in the style of the Baldur's Gate (Infinity Engine) spellbook and ability icons. One bold subject centered and filling most of the square frame, dark vignette background fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

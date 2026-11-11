# Portrait icon prompts

Image prompts for the 20 portrait icons of the mod's states: the tiny icons on a party
member's portrait while they rage, concentrate, are grappled and so on. Generated from
`art/portrait-prompts.txt` by `tools/icon-prompts.pl --portrait`: edit a motif there and run the
script again.

## How to use

1. Copy the prompt of an icon (each one is complete: motif and style) into the image generator.
   Where the tool has a separate field for it, use the negative prompt below.
2. Settings: square (1:1), 512x512 or 1024x1024, PNG. Portrait icons are only **13x13 pixels**:
   shrink each candidate to 13x13 (or look at it from across the room) and keep the one whose
   shape is still clear. A simple, chunky symbol beats a detailed picture every time. Pixel art
   drawn at 13x13 works too.
3. Save the image as `art/portraits/<file name>` exactly as given in the heading (for example
   `art/portraits/B24PRAGE.png`). The black background stays: the icons are small dark squares,
   like the game's own. To make it see-through instead, erase it (transparent PNG).
4. Run `perl tools/png2bam.pl --portrait art/portraits portraits`, then install (`.\deploy.ps1`).
   Icons you haven't made yet keep their colored placeholder disc.

To check them in the game: `.\tools\ingame-test.ps1 -Mode Icons -ShotDir <folder>` puts the
protagonist into every state (all but Prone and Portent) and takes a screenshot of the portrait.

## Shared style

Every prompt below ends with this style text, so all icons look like one set:

> Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.

**Negative prompt:**

> text, letters, numbers, watermark, signature, border, frame, button, user interface, photograph, 3D render, scene, landscape, multiple objects, small subject, thin lines, fine detail, soft gradients, textured background, white background

Colors follow the state's theme, matching the spell and ability icons: rage red, holy gold-white,
nature green, arcane violet and blue, stars silver on indigo, conditions in dull earthy tones.
Each icon needs a shape of its own, since at 13x13 the outline is all that reads.

## Core rules (9)

### 1. Concentrating - `B24PCONC.png`

```text
The side profile of a head with a bright glowing ring circling the brow; violet ring on a pale grey head. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 2. Exhaustion - `B24PEXHA.png`

```text
A half-closed drooping eye with heavy dark bags beneath it; dull grey-brown with a pale blue tear. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 3. Prone - `B24PPRON.png`

```text
A small stick figure lying flat on its back on a ground line; tan figure, brown ground. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 4. Grappled - `B24PGRAP.png`

```text
A large clenched hand gripping a smaller wrist; tan skin with dark orange outline. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 5. Restrained - `B24PREST.png`

```text
A heavy iron chain bent into a tight closed loop; steel grey with rust brown. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 6. Temporary Hit Points - `B24PTHP.png`

```text
A red heart covered by a translucent pale blue shield shape; red and light blue. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 7. Dying - `B24PDYIN.png`

```text
A small skull with a single drop of blood falling from it; bone white and deep red. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 8. Stable - `B24PSTAB.png`

```text
A heart with a short flat heartbeat line running through it; muted red heart, pale green line. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 9. Your turn - `B24PTURN.png`

```text
An hourglass with glowing golden sand running through it; gold sand in a dark wooden frame. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Barbarian (2)

### 10. Raging - `B24PRAGE.png`

```text
A snarling face with bared teeth and blazing eyes; crimson red with yellow eyes. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 11. Reckless Attack - `B24PRECK.png`

```text
A two-handed axe tilted diagonally with a jagged red spark at its edge; dark steel and bright red. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Ranger (1)

### 12. Hunter's Mark - `B24PHMRK.png`

```text
A target ring with a crosshair and an arrowhead at its center; forest green and white. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Bard (1)

### 13. Bardic Inspiration - `B24PBINS.png`

```text
A single musical note with a small star spark above it; gold on deep blue. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Paladin (3)

### 14. Divine Smite ready - `B24PSMIT.png`

```text
A sword pointing straight down with a burst of light at its tip; bright gold and white. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 15. Sacred Weapon - `B24PSACW.png`

```text
An upright sword blade wrapped in a white halo of holy light; white and pale gold. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

### 16. Holy Nimbus - `B24PNIMB.png`

```text
A radiant sun disc with short straight rays; bright gold and white. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Monk (1)

### 17. Dodging - `B24PDODG.png`

```text
A small figure leaning to the side with two fading afterimages behind it; pale blue-grey. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Druid (1)

### 18. Starry Form - `B24PSTAR.png`

```text
Three bright stars joined by thin lines like a constellation; silver-white on indigo. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Sorcerer (1)

### 19. Innate Sorcery - `B24PINSO.png`

```text
A swirling spiral flame; violet core with electric blue edges. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

## Wizard (Diviner) (1)

### 20. Portent - `B24PPORT.png`

```text
A crystal ball with a swirl of golden mist inside; cyan glass and gold. Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the character portraits in Baldur's Gate (Infinity Engine). One simple bold symbol, centered and filling the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, no numbers, no border, no frame, no UI.
```

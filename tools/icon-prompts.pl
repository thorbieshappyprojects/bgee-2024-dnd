#!/usr/bin/perl
# BG 2024 Rules Mod: builds docs/Icon prompts.md (one ready-to-paste image prompt per icon) from
# art/icon-prompts.txt. Edit the motifs there and run: perl tools/icon-prompts.pl
# With --portrait: docs/Portrait icon prompts.md (the 13x13 state icons on the party portraits)
# from art/portrait-prompts.txt.

use strict;
use warnings;

my $PORTRAIT = @ARGV && $ARGV[0] eq '--portrait' ? shift : 0;

my ($SOURCE, $TARGET, $STYLE, $NEGATIVE);
if ($PORTRAIT) {
	($SOURCE, $TARGET) = ('art/portrait-prompts.txt', 'docs/Portrait icon prompts.md');
	# 13x13 pixels leave room for one symbol: flat, bold, few colors, no painterly scene.
	$STYLE = 'Tiny status effect icon for a fantasy RPG party portrait, like the small status icons on the '
		. 'character portraits in Baldur\'s Gate (Infinity Engine). One simple bold symbol, centered and filling '
		. 'the whole square, thick dark outline, flat colors, two or three colors at most, very high contrast on a '
		. 'plain solid black background, no fine detail, readable when shrunk to 13x13 pixels. No text, no letters, '
		. 'no numbers, no border, no frame, no UI.';
	$NEGATIVE = 'text, letters, numbers, watermark, signature, border, frame, button, user interface, photograph, '
		. '3D render, scene, landscape, multiple objects, small subject, thin lines, fine detail, soft gradients, '
		. 'textured background, white background';
} else {
	($SOURCE, $TARGET) = ('art/icon-prompts.txt', 'docs/Icon prompts.md');
	$STYLE = 'Hand-painted fantasy RPG spell icon in the style of the Baldur\'s Gate (Infinity Engine) spellbook '
		. 'and ability icons. One bold subject centered and filling most of the square frame, dark vignette background '
		. 'fading to black at the edges, strong silhouette, dramatic rim lighting, rich saturated colors, painterly '
		. 'texture, readable when shrunk to 32x32 pixels. No text, no letters, no numbers, no border, no frame, no UI.';
	$NEGATIVE = 'text, letters, numbers, watermark, signature, border, frame, button, user interface, photograph, '
		. '3D render, blurry, multiple separate subjects, cluttered background, tiny details, white background';
}

my (@entries, %name);
open my $in, '<', $SOURCE or die "$SOURCE: $!\n";
while (<$in>) {
	chomp;
	s/\r$//;
	next if /^\s*(#|$)/;
	my ($res, $title, $group, $motif, $same) = map { s/^\s+|\s+$//gr } split /\|/;
	push @entries, { res => $res, title => $title, group => $group, motif => $motif, same => $same };
	$name{$res} = $title;
}
close $in;

my @groups;
my %seen;
for (@entries) { push @groups, $_->{group} unless $seen{$_->{group}}++; }
my $images = grep { !$_->{same} } @entries;

my $out;
if ($PORTRAIT) {
	$out = <<"MD";
# Portrait icon prompts

Image prompts for the ${\ scalar @entries} portrait icons of the mod's states: the tiny icons on a party
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
4. Run `perl tools/png2bam.pl --portrait art/portraits portraits`, then install (`.\\deploy.ps1`).
   Icons you haven't made yet keep their colored placeholder disc.

To check them in the game: `.\\tools\\ingame-test.ps1 -Mode Icons -ShotDir <folder>` puts the
protagonist into every state (all but Prone and Portent) and takes a screenshot of the portrait.

## Shared style

Every prompt below ends with this style text, so all icons look like one set:

> $STYLE

**Negative prompt:**

> $NEGATIVE

Colors follow the state's theme, matching the spell and ability icons: rage red, holy gold-white,
nature green, arcane violet and blue, stars silver on indigo, conditions in dull earthy tones.
Each icon needs a shape of its own, since at 13x13 the outline is all that reads.
MD
} else {
	$out = <<"MD";
# Icon prompts

Image prompts for the ${\ scalar @entries} icons of the mod's spells, cantrips and abilities ($images images; the
others are copies). Generated from `art/icon-prompts.txt` by `tools/icon-prompts.pl`: edit a motif
there and run the script again.

## How to use

1. Copy the prompt of an icon (each one is complete: motif and style) into the image generator.
   Where the tool has a separate field for it, use the negative prompt below.
2. Settings: square (1:1), 512x512 or 1024x1024, PNG. Generate a few and pick the one whose
   shape still reads when you shrink it to 32x32 pixels: the game shows icons that small.
3. Save the image as `art/icons/<file name>` exactly as given in the heading (for example
   `art/icons/B24SWIND.png`).
4. Run `perl tools/png2bam.pl art/icons icons`, then install (`.\\deploy.ps1`). The spell or ability
   uses its new icon in both games; icons you haven't made yet keep their borrowed vanilla icon.

Copies (marked "same image as") need no image of their own: copy the other PNG under the new name.

## Shared style

Every prompt below ends with this style text, so all icons look like one set:

> $STYLE

**Negative prompt:**

> $NEGATIVE

Colors follow the ability's theme (fire orange-red, cold pale blue, lightning white-blue, acid and
poison green, radiant gold-white, necrotic purple-black or sickly green, psychic violet, healing
green-white, martial steel and red, nature brown-green). Recurring motifs keep families together:
Battle Master maneuvers show a small golden die, psionic abilities are violet, Starry Forms are
constellations, Create Spell Slot shows one to five points of light.
MD
}

my $n = 0;
for my $group (@groups) {
	my @in = grep { $_->{group} eq $group } @entries;
	$out .= "\n## $group (" . scalar(@in) . ")\n";
	for my $e (@in) {
		$n++;
		$out .= "\n### $n. $e->{title} - `$e->{res}.png`\n\n";
		if ($e->{same}) {
			$out .= "Same image as **$name{$e->{same}}** (`$e->{same}.png`): copy that PNG as `$e->{res}.png`.\n";
			next;
		}
		my $motif = ucfirst $e->{motif};
		# The motif alone: a name in the prompt tempts image tools to write it into the picture.
		$out .= "```text\n$motif. $STYLE\n```\n";
	}
}

open my $fh, '>', $TARGET or die "$TARGET: $!\n";
print $fh $out;
close $fh;
print "$TARGET: $n icons, $images images\n";

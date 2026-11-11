#!/usr/bin/perl
# BG 2024 Rules Mod: balance report. Compares the vanilla game (a clean copy) with the modded one
# by expected-value combat math: how hard monsters hit the party, how fast the party kills them,
# how many hits a character survives, how often monsters save. No game launch needed; old and new
# numbers both come from each game's own files (creatures, items and rule tables), so the report
# follows whatever the install changed.
#
#   perl tools/balance.pl                        # BG:EE, clean copy C:/BG/BGEE-clean vs C:/BG/BGEE
#   perl tools/balance.pl --old DIR --new DIR    # other game folders
#   perl tools/balance.pl --html FILE            # also write the report as an HTML page
#   perl tools/balance.pl --dump RESREF          # one creature, old and new, every number
#   perl tools/balance.pl --table RESREF         # a 2DA table, old and new
#   perl tools/balance.pl --areas               # only the encounters
#   perl tools/balance.pl --hp-scale 1.5        # what if: new monsters with 1.5 times the HP
#
# What it can't see: AI and spell use, terrain, pausing, player skill. It points at the fights to
# playtest, it doesn't replace them.

use strict;
use warnings;

my %opt = (old => 'C:/BG/BGEE-clean', new => 'C:/BG/BGEE');
for (my $i = 0; $i < @ARGV; $i++) {
	if ($ARGV[$i] =~ /^--(old|new|html|dump|table|find|hp-scale)$/) { $opt{$1} = $ARGV[++$i]; }
	elsif ($ARGV[$i] eq "--areas") { $opt{areas} = 1; }
	else { die "unknown argument $ARGV[$i]\n"; }
}

# ---------------------------------------------------------------------------------------------
# Binary helpers

sub slurp { my ($p) = @_; open(my $fh, '<:raw', $p) or return undef; local $/; my $d = <$fh>; close $fh; return $d; }
sub u8  { unpack('C', substr($_[0], $_[1], 1)) }
sub s8  { unpack('c', substr($_[0], $_[1], 1)) }
sub u16 { unpack('v', substr($_[0], $_[1], 2)) }
sub s16 { unpack('s<', substr($_[0], $_[1], 2)) }
sub u32 { unpack('V', substr($_[0], $_[1], 4)) }
sub s32 { unpack('l<', substr($_[0], $_[1], 4)) }
sub res { my $r = substr($_[0], $_[1], 8); $r =~ s/\0.*//s; return uc $r; }

# Resource type numbers in chitin.key.
my %TYPE = (ITM => 0x3ed, CRE => 0x3f1, ARE => 0x3f2, '2DA' => 0x3f4, SPL => 0x3ee, IDS => 0x3f0, WMP => 0x3f7, MOS => 0x3ec, BAM => 0x3e8, BMP => 0x001);

# All resrefs of one type (override and chitin.key).
sub allRes {
	my ($g, $ext) = @_;
	my %seen;
	for (keys %{$g->{ov}}) { $seen{$1} = 1 if /^(.+)\.\Q$ext\E$/i; }
	my $t = $TYPE{uc $ext};
	for (keys %{$g->{key}}) { $seen{$1} = 1 if /^(.+)\.(\d+)$/ && $2 == $t; }
	return sort keys %seen;
}

# ---------------------------------------------------------------------------------------------
# A game folder: override first, then the BIFF files listed in chitin.key.

sub openGame {
	my ($dir) = @_;
	my $g = { dir => $dir, ov => {}, key => {}, biffs => [], cache => {} };
	if (opendir(my $dh, "$dir/override")) {
		for my $f (readdir $dh) { $g->{ov}{uc $f} = "$dir/override/$f" if $f =~ /\./; }
		closedir $dh;
	}
	my $key = slurp("$dir/chitin.key") or die "$dir/chitin.key: $!\n";
	die "$dir/chitin.key: not a KEY V1 file\n" unless substr($key, 0, 8) eq 'KEY V1  ';
	my ($nbif, $nres, $boff, $roff) = (u32($key, 8), u32($key, 12), u32($key, 16), u32($key, 20));
	for my $i (0 .. $nbif - 1) {
		my $o = $boff + $i * 12;
		my $name = substr($key, u32($key, $o + 4), u16($key, $o + 8));
		$name =~ s/\0.*//s;
		$name =~ s{\\}{/}g;
		push @{$g->{biffs}}, $name;
	}
	for my $i (0 .. $nres - 1) {
		my $o = $roff + $i * 14;
		$g->{key}{res($key, $o) . '.' . u16($key, $o + 8)} = u32($key, $o + 10);
	}
	my $tlk = slurp("$dir/lang/en_US/dialog.tlk");
	$g->{tlk} = $tlk if $tlk && substr($tlk, 0, 4) eq 'TLK ';
	return $g;
}

# Contents of RES.EXT, or undef.
sub load {
	my ($g, $res, $ext) = @_;
	my $name = uc "$res.$ext";
	return $g->{cache}{$name} if exists $g->{cache}{$name};
	my $data;
	if (my $p = $g->{ov}{$name}) { $data = slurp($p); }
	elsif (defined(my $loc = $g->{key}{uc($res) . '.' . $TYPE{uc $ext}})) {
		my ($bi, $fi) = ($loc >> 20, $loc & 0x3fff);
		my $biff = $g->{biffCache}{$bi} //= slurp("$g->{dir}/$g->{biffs}[$bi]") // '';
		if (substr($biff, 0, 8) eq 'BIFFV1  ') {
			my ($nfiles, $foff) = (u32($biff, 8), u32($biff, 16));
			for my $k (0 .. $nfiles - 1) {
				my $e = $foff + $k * 16;
				next unless (u32($biff, $e) & 0x3fff) == $fi;
				$data = substr($biff, u32($biff, $e + 4), u32($biff, $e + 8));
				last;
			}
		}
	}
	return $g->{cache}{$name} = $data;
}

sub str {
	my ($g, $ref) = @_;
	my $t = $g->{tlk};
	return '' if !$t || $ref < 0 || $ref >= u32($t, 10);
	my $e = 18 + $ref * 26;
	my $s = substr($t, u32($t, 14) + u32($t, $e + 18), u32($t, $e + 22));
	$s =~ s/\s+/ /g;
	return $s;
}

# 2DA as { cols => [...], rows => { LABEL => [values] }, order => [labels] }.
sub table {
	my ($g, $res) = @_;
	my $text = load($g, $res, '2DA') // return undef;
	my @lines = grep { /\S/ } split /\r?\n/, $text;
	return undef unless @lines >= 3 && $lines[0] =~ /^\s*2DA/i;
	my $t = { cols => [split ' ', $lines[2]], rows => {}, order => [] };
	for my $l (@lines[3 .. $#lines]) {
		my @f = split ' ', $l;
		next unless @f;
		my $label = uc shift @f;
		push @{$t->{order}}, $label unless $t->{rows}{$label};
		$t->{rows}{$label} = \@f;
	}
	return $t;
}

# Value of row/column (labels, case-insensitive).
sub cell {
	my ($t, $row, $col) = @_;
	return undef unless $t;
	my $r = $t->{rows}{uc $row} or return undef;
	for my $i (0 .. $#{$t->{cols}}) { return $r->[$i] if uc $t->{cols}[$i] eq uc $col; }
	return undef;
}

my $old = openGame($opt{old});
my $new = openGame($opt{new});
$old->{ver} = q(old);
$new->{ver} = q(new);

if ($opt{table}) {
	for my $g ($old, $new) { print "-- $g->{dir}\n", load($g, $opt{table}, '2DA') // "missing\n"; }
	exit 0;
}

if ($opt{find}) {
	for my $ext ('ITM', 'CRE') {
		for my $r (allRes($new, $ext)) {
			my $d = load($new, $r, $ext) // next;
			my $name = str($new, s32($d, $ext eq 'ITM' ? 0x0c : 0x08));
			$name = str($new, s32($d, 0x08)) if $ext eq 'ITM' && $name eq '';
			print "$ext $r: $name\n" if $name =~ /$opt{find}/i;
		}
	}
	exit 0;
}

# ---------------------------------------------------------------------------------------------
# What the report looks at. Edit freely.

# Typical characters. Old: rolled scores as BG players usually keep them, weapon proficiency
# stars ("pips"). New: 2024 point buy with the background's +2/+1 (as the chargen test makes them).
my @PARTY = (
	{ name => 'Fighter', class => 'FIGHTER', hp => 'FIGHTER', warrior => 1,
	  weapon => 'SW1H04', armor => 'CHAN01', shield => 'SHLD01',
	  old => { str => 18, strex => 50, dex => 16, con => 17, pips => 2 },
	  new => { str => 17, dex => 13, con => 15, style => "DEFENSE" } },
	{ name => 'Cleric', class => 'CLERIC', hp => 'CLERIC',
	  weapon => 'BLUN04', armor => 'CHAN01', shield => 'SHLD01',
	  old => { str => 16, dex => 12, con => 16, pips => 1 },
	  new => { str => 13, dex => 12, con => 15 } },
	{ name => 'Rogue', class => 'THIEF', hp => 'THIEF', finesse => 1,
	  weapon => 'SW1H07', armor => 'LEAT01',
	  old => { str => 14, dex => 18, con => 15, pips => 1 },
	  new => { str => 8, dex => 17, con => 14, sneak => 1 } },
	{ name => 'Wizard', class => 'MAGE', hp => 'MAGE',
	  weapon => 'STAF01',
	  old => { str => 10, dex => 16, con => 15, pips => 1, int => 18 },
	  new => { str => 8, dex => 13, con => 15, int => 17, cantrip => 10 } },
);
my @LEVELS = (1, 2, 3, 5, 8);

# Opponents and the party level they're usually met at.
my @MONSTERS = (
	[GIBBER => 1], [KOBOLD => 1], [XVART => 1], [DOGWI => 1], [HOBGOB => 1], [HOBGOBA => 1], [BANDIT => 1],
	[TARNES => 1], [WOLF => 2], [GNOLL => 2], [SKELET => 2], [ZOMBIE => 2], [KOBCOMM => 2], [NIMBUL => 2],
	[MULAHE => 3], [GHOUL => 3], [OGRE => 3], [CARRIO => 3], [SPIDGI => 3], [BEARBL => 3], [NEIRA => 3],
	[GREYWO => 4], [BASSIL => 4], [ANKHEG => 4], [WOLFDR => 4], [GNOLLSU => 4], [SPIDPH => 5], [ETTERC1 => 5],
	[MUTAMI => 5], [SIRINE => 5], [WOLFWI => 5], [DAVAEO => 6], [BATTHO => 6], [SKELWA => 7], [BASILG => 7],
	[DOOMGU => 7], [SILKE => 4], [SAREVO => 8],
);

# 2024 runtime rules the tables don't hold (the mod's Lua): Extra Attack.
my %EXTRA_ATTACKS = (FIGHTER => [[20, 4], [11, 3], [5, 2]], RANGER => [[5, 2]], PALADIN => [[5, 2]],
	MONK => [[5, 2]], BARBARIAN => [[5, 2]]);

# ---------------------------------------------------------------------------------------------
# Rules from a game's tables

sub prof { my ($l, $max) = @_; $max //= 20; $l = 1 if $l < 1; $l = $max if $l > $max; return 2 + int(($l - 1) / 4); }
sub abilityMod { my ($s) = @_; return int(($s - 10) / 2 + ($s < 10 ? -0.5 : 0)); }

sub strHit {
	my ($g, $str, $strex) = @_;
	my $v = cell(table($g, 'STRMOD'), $str, 'TO_HIT') // 0;
	$v += cell(table($g, 'STRMODEX'), $strex, 'TO_HIT') // 0 if $str == 18 && $strex;
	return $v;
}
sub strDmg {
	my ($g, $str, $strex) = @_;
	my $v = cell(table($g, 'STRMOD'), $str, 'DAMAGE') // 0;
	$v += cell(table($g, 'STRMODEX'), $strex, 'DAMAGE') // 0 if $str == 18 && $strex;
	return $v;
}
sub dexAC      { my ($g, $dex) = @_; return cell(table($g, 'DEXMOD'), $dex, 'AC') // 0; }
sub dexMissile { my ($g, $dex) = @_; return cell(table($g, 'DEXMOD'), $dex, 'MISSILE') // 0; }

# Armor spell states of the mod (SPLSTATE.IDS): heavy armor ignores Dex, medium caps it at +2.
sub armorStates {
	my ($g) = @_;
	return $g->{armorStates} //= do {
		my %s;
		for (split /\r?\n/, load($g, 'SPLSTATE', 'IDS') // '') { $s{uc $2} = $1 if /^\s*(\d+)\s+(\S+)/; }
		{ heavy => $s{B24_ARMOR_HEAVY} // -1, medium => $s{B24_ARMOR_MEDIUM} // -1 };
	};
}

# ---------------------------------------------------------------------------------------------
# Items and creatures

sub item {
	my ($g, $res) = @_;
	return undef unless $res;
	my $d = load($g, $res, 'ITM') // return undef;
	return undef unless length($d) > 0x72 && substr($d, 0, 8) eq 'ITM V1  ';
	my $it = { res => uc $res, type => u16($d, 0x1c), state => {} };
	my ($hoff, $hnum, $foff, $fidx, $fnum) = (u32($d, 0x64), u16($d, 0x68), u32($d, 0x6a), u16($d, 0x6e), u16($d, 0x70));
	for my $h (0 .. $hnum - 1) {
		my $o = $hoff + $h * 0x38;
		my $t = u8($d, $o);
		next unless $t == 1 || $t == 2 || $t == 4;
		$it->{attack} = { type => $t, hit => s16($d, $o + 0x14), sides => u8($d, $o + 0x16), dice => u8($d, $o + 0x18),
			bonus => s16($d, $o + 0x1a) };
		last;
	}
	for my $k (0 .. $fnum - 1) {
		my $o = $foff + ($fidx + $k) * 0x30;
		my ($op, $p1, $p2) = (u16($d, $o), s32($d, $o + 4), u32($d, $o + 8));
		if ($op == 0 && $p2 == 16) { $it->{baseAC} //= $p1; }
		elsif ($op == 0 && $p2 == 0) { $it->{acBonus} //= $p1; }
		elsif ($op == 328) { $it->{state}{$p2} = 1; }
	}
	return $it;
}

# CRE attacks per round: 6-10 are 1/2 to 9/2.
sub aprDecode { my ($v) = @_; return $v >= 6 && $v <= 10 ? ($v - 5) - 0.5 : $v; }

my @RESIST = ([fire => 0x59], [cold => 0x5a], [electricity => 0x5b], [acid => 0x5c], [magic => 0x5d],
	[slashing => 0x60], [crushing => 0x61], [piercing => 0x62], [missile => 0x63]);

# Armor class from natural AC, armor, shield and other worn items, and Dex (capped by the mod's
# armor states in the new game). Engine AC (lower is better).
sub armorClass {
	my ($g, $natural, $dex, @worn) = @_;
	my ($base, $bonus, $cap) = ($natural, 0, undef);
	my $st = armorStates($g);
	for my $it (grep { defined } @worn) {
		$base = $it->{baseAC} if defined $it->{baseAC} && $it->{baseAC} < $base;
		$bonus += $it->{acBonus} // 0;
		$cap = 0 if $it->{state}{$st->{heavy}};
		$cap //= 2 if $it->{state}{$st->{medium}};
	}
	my $d = dexAC($g, $dex);
	$d = -$cap if defined $cap && -$d > $cap;
	return $base + $d - $bonus;
}

# Average damage of one hit, and of the dice alone (doubled by a 2024 critical hit).
sub weaponDamage {
	my ($a) = @_;
	return (1.5, 1.5) unless $a;   # fist 1d2
	my $dice = $a->{dice} * ($a->{sides} + 1) / 2;
	return ($dice + $a->{bonus}, $dice);
}

sub creature {
	my ($g, $res) = @_;
	return $g->{creatures}{uc $res} if exists $g->{creatures}{uc $res};
	return $g->{creatures}{uc $res} = creatureFrom($g, load($g, $res, 'CRE'), $res);
}

# From CRE data (a file, or embedded in an area).
sub creatureFrom {
	my ($g, $d, $res) = @_;
	return undef unless defined $d && length($d) > 0x2d3 && substr($d, 0, 8) eq 'CRE V1.0';
	my $c = { res => uc $res, name => str($g, s32($d, 0x08)), hp => s16($d, 0x26), xp => u32($d, 0x14), ea => u8($d, 0x270), ver => $g->{ver},
		thac0 => u8($d, 0x52), apr => aprDecode(u8($d, 0x53)), level => u8($d, 0x234) || 1,
		general => u8($d, 0x271), class => u8($d, 0x273), str => u8($d, 0x238), strex => u8($d, 0x239),
		dex => u8($d, 0x23c), con => u8($d, 0x23d), int => u8($d, 0x23a), wis => u8($d, 0x23b), cha => u8($d, 0x23e),
		saveSpell => u8($d, 0x58), saveBreath => u8($d, 0x57), resist => {} };
	$c->{resist}{$_->[0]} = s8($d, $_->[1]) for @RESIST;
	# Known spells: casters fight with spells, which the math leaves out.
	$c->{caster} = u32($d, 0x2a4) > 0 ? 1 : 0;
	# What if (--hp-scale): monsters of the new game with more hit points.
	$c->{hp} = int($c->{hp} * $opt{q(hp-scale)} + 0.5) if $opt{q(hp-scale)} && $g->{ver} eq q(new);
	my ($soff, $ioff, $icnt) = (u32($d, 0x2b8), u32($d, 0x2bc), u32($d, 0x2c0));
	my $slot = sub {
		my $i = u16($d, $soff + $_[0] * 2);
		return $i == 0xffff || $i >= $icnt ? undef : item($g, res($d, $ioff + $i * 20));
	};
	# Worn: helmet, armor, shield, gloves, rings, amulet, belt, boots (0-8) and cloak (17).
	$c->{ac} = armorClass($g, s16($d, 0x46), $c->{dex}, map { $slot->($_) } 0 .. 8, 17);
	my ($weapon) = grep { $_ && $_->{attack} } map { $slot->($_) } 9 .. 12;
	my $a = $weapon && $weapon->{attack};
	if ($a && $a->{type} == 4) {
		my ($ammo) = grep { $_ && $_->{attack} } map { $slot->($_) } 13 .. 16;
		my $launcher = $a;
		$a = $ammo ? { %{$ammo->{attack}}, hit => $ammo->{attack}{hit} + $launcher->{hit}, type => 2 } : undef;
	}
	$c->{weapon} = $weapon ? $weapon->{res} : 'fist';
	# Gazes, breath and the like: no attack roll (to-hit 32767) or no weapon damage. Not modeled.
	if ($a && (abs($a->{hit}) >= 100 || $a->{dice} == 0 && $a->{bonus} <= 0)) {
		$c->{special} = 1;
		$a = undef;
	}
	attackStats($g, $c, $a, $c->{str}, $c->{strex}, $c->{dex}, $c->{thac0}, 0, 0);
	return $c;
}

# Fills hit (attack bonus in 2024 terms, 20 - effective THAC0), dmg and dice (per hit).
sub attackStats {
	my ($g, $c, $a, $str, $strex, $dex, $thac0, $pipHit, $pipDmg, $finesse) = @_;
	my $ranged = $a && $a->{type} == 2;
	my ($hitAbility, $dmgAbility) = $ranged ? (dexMissile($g, $dex), 0) : (strHit($g, $str, $strex), strDmg($g, $str, $strex));
	if ($finesse && !$ranged) {
		my $m = dexMissile($g, $dex);
		($hitAbility, $dmgAbility) = ($m, $m) if $m > $hitAbility;
	}
	my ($dmg, $dice) = weaponDamage($a);
	$c->{hit} = 20 - $thac0 + $hitAbility + ($a ? $a->{hit} : 0) + $pipHit;
	$c->{dmg} = $dmg + $dmgAbility + $pipDmg;
	$c->{dice} = $dice;
	$c->{ranged} = $ranged ? 1 : 0;
}

# A party member at a level in one game ('old' or 'new' scores).
sub character {
	my ($g, $p, $level, $ver) = @_;
	my $s = $p->{$ver};
	my $c = { name => $p->{name}, level => $level, ver => $ver, %$s };
	# Hit points: HPCLASS names the class's table; level 1 is the maximum, later levels the average.
	my $hpTable = table($g, cell(table($g, 'HPCLASS'), $p->{hp}, 'TABLE') // 'HPWAR');
	my $hp = 0;
	for my $l (1 .. $level) {
		my ($sides, $rolls, $mod) = map { cell($hpTable, $l, $_) // 0 } qw(SIDES ROLLS MODIFIER);
		$hp += $l == 1 ? $rolls * $sides + $mod : $rolls * ($sides + 1) / 2 + $mod;
		$hp += cell(table($g, 'HPCONBON'), $s->{con}, $p->{warrior} ? 'WARRIOR' : 'OTHER') // 0 if $rolls > 0;
	}
	$c->{hp} = $hp;
	$c->{ac} = armorClass($g, 10, $s->{dex}, item($g, $p->{armor}), item($g, $p->{shield}));
	# Weapon proficiency stars (old game only: the mod empties these tables).
	my $pips = $s->{pips} // 0;
	my $wsp = table($g, 'WSPECIAL');
	my ($pipHit, $pipDmg) = map { cell($wsp, $pips, $_) // 0 } qw(HIT DAMAGE);
	my $weapon = item($g, $p->{weapon});
	my $thac0 = cell(table($g, 'THAC0'), $p->{class}, $level) // 20;
	attackStats($g, $c, $weapon && $weapon->{attack}, $s->{str}, $s->{strex} // 0, $s->{dex}, $thac0, $pipHit, $pipDmg,
		$ver eq 'new' && $p->{finesse});
	# Attacks per round: warriors from WSPATCK (old), Extra Attack (new).
	my $apr = 1;
	if ($p->{warrior}) {
		my $row = table($g, 'WSPATCK');
		my $v = $row && $row->{rows}{$pips} ? $row->{rows}{$pips}[$level - 1] // 0 : 0;
		$apr += $v > 0 ? $v : $v < 0 ? -$v - 0.5 : 0;
	}
	if ($ver eq 'new') {
		for my $step (@{$EXTRA_ATTACKS{$p->{class}} // []}) { if ($level >= $step->[0]) { $apr = $step->[1]; last; } }
	}
	$c->{apr} = $apr;
	# Class features of the mod's Lua that change the numbers.
	if ($ver eq 'new') {
		$c->{ac} -= 1 if ($s->{style} // '') eq 'DEFENSE' && $p->{armor};
		# Sneak Attack: 1d6 per two levels once per round (an ally next to the target, as usual in a party).
		$c->{sneak} = int(($level + 1) / 2) * 3.5 if $s->{sneak};
		# Attack cantrip (Fire Bolt): spell attack, one die more at 5, 11 and 17.
		if (my $die = $s->{cantrip}) {
			my $n = $level >= 17 ? 4 : $level >= 11 ? 3 : $level >= 5 ? 2 : 1;
			@$c{qw(hit dmg dice ranged apr)} = (prof($level) + abilityMod($s->{int}), $n * ($die + 1) / 2, $n * ($die + 1) / 2, 1, 1);
		}
	}
	return $c;
}

# ---------------------------------------------------------------------------------------------
# Combat math

# Chance that an attack with bonus $hit (2024 terms) hits engine AC $ac: natural 1 misses,
# natural 20 hits.
sub hitChance {
	my ($hit, $ac) = @_;
	my $need = (20 - $ac) - $hit;     # d20 roll needed
	my $p = (21 - $need) / 20;
	return $p < 0.05 ? 0.05 : $p > 0.95 ? 0.95 : $p;
}

# Expected damage per round of attacker against defender. Old critical hits double all damage,
# new ones the dice.
sub dpr {
	my ($a, $d, $ver) = @_;
	my $p = hitChance($a->{hit}, $d->{ac});
	my $crit = 0.05;
	my $critExtra = ($a->{ver} // $ver) eq q(old) ? $a->{dmg} : $a->{dice};
	return 0 if $a->{special};
	my $total = $a->{apr} * ($p * $a->{dmg} + $crit * $critExtra);
	# Sneak Attack: once per round if any attack hits.
	my $attacks = $a->{apr} < 1 ? 1 : int($a->{apr} + 0.5);
	$total += (1 - (1 - $p) ** $attacks) * $a->{sneak} if $a->{sneak};
	return $total;
}

# 2024 DMG table "Monster Statistics by Challenge Rating": CR, AC, HP max, attack bonus, DPR max.
my @CR_TABLE = (
	['0', 13, 6, 3, 1], ['1/8', 13, 35, 3, 3], ['1/4', 13, 49, 3, 5], ['1/2', 13, 70, 3, 8], ['1', 13, 85, 3, 14],
	['2', 13, 100, 3, 20], ['3', 13, 115, 4, 26], ['4', 14, 130, 5, 32], ['5', 15, 145, 6, 38], ['6', 15, 160, 6, 44],
	['7', 15, 175, 6, 50], ['8', 16, 190, 7, 56], ['9', 16, 205, 7, 62], ['10', 17, 220, 7, 68], ['11', 17, 235, 8, 74],
	['12', 17, 250, 8, 80], ['13', 18, 265, 8, 86], ['14', 18, 280, 8, 92], ['15', 18, 295, 8, 98], ['16', 18, 310, 9, 104],
	['17', 19, 325, 10, 110], ['18', 19, 340, 10, 116], ['19', 19, 355, 10, 122], ['20', 19, 400, 10, 140],
);
my %CR_XP = ('0' => 10, '1/8' => 25, '1/4' => 50, '1/2' => 100, 1 => 200, 2 => 450, 3 => 700, 4 => 1100, 5 => 1800,
	6 => 2300, 7 => 2900, 8 => 3900, 9 => 5000, 10 => 5900, 11 => 7200, 12 => 8400, 13 => 10000, 14 => 11500,
	15 => 13000, 16 => 15000, 17 => 18000, 18 => 20000, 19 => 22000, 20 => 25000);

# Challenge rating by the DMG method: defensive CR from HP (resistant creatures count as having more
# HP), moved one step per 2 points of AC difference; offensive CR from damage per round, moved by
# attack bonus; the average of the two.
sub challenge {
	my ($c, $dprAll) = @_;
	my $idx = sub { my ($v, $col) = @_; for my $i (0 .. $#CR_TABLE) { return $i if $v <= $CR_TABLE[$i][$col]; } return $#CR_TABLE; };
	my $phys = 0;
	$phys++ for grep { ($c->{resist}{$_} // 0) >= 50 } qw(slashing crushing piercing);
	my $hp = $c->{hp} * ($phys >= 2 ? 1.5 : 1);
	my $def = $idx->($hp, 2);
	my $ac2024 = 20 - $c->{ac};
	$def += int(($ac2024 - $CR_TABLE[$def][1]) / 2);
	my $off = $idx->($dprAll, 4);
	$off += int(($c->{hit} - $CR_TABLE[$off][3]) / 2);
	for ($def, $off) { $_ = 0 if $_ < 0; $_ = $#CR_TABLE if $_ > $#CR_TABLE; }
	return $CR_TABLE[int(($def + $off) / 2 + 0.5)][0];
}

# Save: old d20 >= save vs spell; new d20 + ability modifier (+ proficiency) >= DC (B24SAVE.lua).
my %MONSTER_SAVES = (1 => [qw(DEX WIS)], 2 => [qw(STR DEX)], 4 => [qw(DEX WIS)], 5 => [qw(STR CON)], 7 => [qw(CON WIS)]);
sub saveProficient {
	my ($g, $c, $ability) = @_;
	my $row = $c->{class} <= 21 ? table($g, 'B24CLASS') && table($g, 'B24CLASS')->{rows}{$c->{class}} : undef;
	my @s = $row ? (cell(table($g, 'B24CLASS'), $c->{class}, 'SAVE1'), cell(table($g, 'B24CLASS'), $c->{class}, 'SAVE2'))
		: @{$MONSTER_SAVES{$c->{general}} // [qw(CON WIS)]};
	return grep { defined && $_ eq $ability } @s;
}
sub saveChance {
	my ($g, $c, $ver, $ability, $dc) = @_;
	if ($ver eq 'old') { my $p = (21 - $c->{saveSpell}) / 20; return $p < 0.05 ? 0.05 : $p > 0.95 ? 0.95 : $p; }
	my $score = $c->{lc $ability};
	my $bonus = abilityMod($score) + (saveProficient($g, $c, $ability) ? prof($c->{level}, 30) : 0);
	my $p = (21 - ($dc - $bonus)) / 20;
	return $p < 0 ? 0 : $p > 1 ? 1 : $p;
}

# ---------------------------------------------------------------------------------------------
# Report

my @out;
sub line { push @out, join('', @_); }
sub pct { return $_[0] > 1 ? sprintf(q(x%.1f), $_[0]) : sprintf(q(%d%%), $_[0] * 100 + 0.5); }
sub ch  { my ($o, $n, $fmt) = @_; $fmt //= '%s'; return sprintf("$fmt>$fmt", $o, $n); }
sub sign { return $_[0] >= 0 ? "+$_[0]" : $_[0]; }

sub run {
	my %pc;
	for my $ver ('old', 'new') {
		my $g = $ver eq 'old' ? $old : $new;
		for my $p (@PARTY) { $pc{$ver}{$p->{name}}{$_} = character($g, $p, $_, $ver) for @LEVELS; }
	}

	line('== Party: old > new (AC and attack in 2024 terms: AC = 20 - engine AC) ==');
	line(sprintf('%-8s %3s  %-9s %-7s %-9s %-9s %-11s %-13s', 'class', 'lvl', 'HP', 'AC', 'attack', 'APR', 'dmg/hit',
		'DPR vs AC 15'));
	my $dummy = { ac => 5 };
	for my $p (@PARTY) {
		for my $l (@LEVELS) {
			my ($o, $n) = ($pc{old}{$p->{name}}{$l}, $pc{new}{$p->{name}}{$l});
			line(sprintf('%-8s %3d  %-9s %-7s %-9s %-9s %-11s %-13s', $p->{name}, $l, ch($o->{hp}, $n->{hp}, '%g'),
				ch(20 - $o->{ac}, 20 - $n->{ac}), ch(sign($o->{hit}), sign($n->{hit})), ch($o->{apr}, $n->{apr}, '%g'),
				ch($o->{dmg}, $n->{dmg}, '%.1f'), ch(dpr($o, $dummy, 'old'), dpr($n, $dummy, 'new'), '%.1f')));
		}
	}

	line('');
	line('== Monsters at the party level they are met: old > new ==');
	line('Damage is unchanged by the mod. "hits" = hits that take a party member from full to 0 (Fighter / Wizard).');
	line('"party kills it" = expected rounds for the four characters together; "it kills" = rounds to kill the Fighter / the Wizard.');
	line('"-" = the creature fights with something the math does not cover (gaze, breath, spells).');
	line(q(* = casts spells, which the math leaves out: its real threat and CR are higher.));
	line(sprintf('%-18s %3s %-8s %-7s %-9s %-11s %-11s %-11s %-13s %-17s %-5s', 'monster', 'lvl', 'HP', 'AC', 'attack',
		'max dmg/rnd', 'hit Fighter', 'hits F/W', 'party kills', 'it kills F / W', 'CR'));
	my @cr;
	for my $m (@MONSTERS) {
		my ($res, $l) = @$m;
		my ($o, $n) = (creature($old, $res), creature($new, $res));
		next unless $o && $n;
		my %at = map { my ($v, $cls) = @$_; ("$v$cls" => $pc{$v}{$cls}{$l} // $pc{$v}{$cls}{$LEVELS[-1]}) }
			map { my $cls = $_->{name}; (['old', $cls], ['new', $cls]) } @PARTY;
		my ($fo, $fn, $wo, $wn) = @at{qw(oldFighter newFighter oldWizard newWizard)};
		my $hits = sub {
			my ($c, $pcx) = @_;
			return '-' if $c->{special} || !$c->{dmg};
			my $h = $pcx->{hp} / $c->{dmg};
			return $h == int($h) ? $h : int($h) + 1;
		};
		my $rounds = sub { my ($att, $def, $ver) = @_; my $x = dpr($att, $def, $ver); return $x > 0 ? sprintf('%.1f', $def->{hp} / $x) : '-'; };
		my $partyRounds = sub {
			my ($ver, $c) = @_;
			my $sum = 0;
			$sum += dpr($at{"$ver$_->{name}"}, $c, $ver) for @PARTY;
			return $c->{hp} / $sum;
		};
		my $crNew = $n->{special} ? '?' : challenge($n, $n->{apr} * $n->{dmg});
		push @cr, [$n->{name}, $res, $n->{xp}, $crNew];
		line(sprintf('%-18s %3d %-8s %-7s %-9s %-11s %-11s %-11s %-13s %-17s %-5s', substr($n->{name}, 0, 17) . ($n->{caster} ? q(*) : q()), $l, ch($o->{hp}, $n->{hp}),
			ch(20 - $o->{ac}, 20 - $n->{ac}), $n->{special} ? '-' : ch(sign($o->{hit}), sign($n->{hit})),
			$n->{special} ? '-' : ch($o->{apr} * $o->{dmg}, $n->{apr} * $n->{dmg}, '%g'),
			$n->{special} ? '-' : ch(pct(hitChance($o->{hit}, $fo->{ac})), pct(hitChance($n->{hit}, $fn->{ac}))),
			sprintf('%s/%s>%s/%s', $hits->($o, $fo), $hits->($o, $wo), $hits->($n, $fn), $hits->($n, $wn)),
			ch($partyRounds->('old', $o), $partyRounds->('new', $n), '%.1f'),
			sprintf('%s/%s>%s/%s', $rounds->($o, $fo, 'old'), $rounds->($o, $wo, 'old'), $rounds->($n, $fn, 'new'),
				$rounds->($n, $wn, 'new')),
			$crNew));
	}

	line('');
	line('== Saves against a Wizard of the meeting level (Int 18 old, 17 new): chance to resist, old > new ==');
	line('Old: save vs spell. New: DC 8 + proficiency + 3 against the creature\'s Dex / Con / Wis save.');
	line(sprintf('%-18s %3s %-4s %-9s %-9s %-9s  %s', 'monster', 'lvl', 'DC', 'Dex', 'Con', 'Wis', 'resistances'));
	for my $m (@MONSTERS) {
		my ($res, $l) = @$m;
		my ($o, $n) = (creature($old, $res), creature($new, $res));
		next unless $o && $n;
		my $dc = 8 + prof($l) + 3;
		my $old = pct(saveChance($old, $o, 'old', 'WIS', $dc));
		my @r = map { "$_ $n->{resist}{$_}%" } grep { $n->{resist}{$_} } map { $_->[0] } @RESIST;
		line(sprintf('%-18s %3d %-4d %-9s %-9s %-9s  %s', substr($n->{name}, 0, 18), $l, $dc,
			map({ "$old>" . pct(saveChance($new, $n, 'new', $_, $dc)) } qw(DEX CON WIS)), join(', ', @r)));
	}

	line('');
	line('== Experience: BG XP vs 2024 XP of the computed CR ==');
	line(sprintf('%-18s %-9s %6s %5s %7s', 'monster', 'resref', 'BG XP', 'CR', '2024 XP'));
	line(sprintf('%-18s %-9s %6d %5s %7d', substr($_->[0], 0, 18), $_->[1], $_->[2], $_->[3], $CR_XP{$_->[3]} // 0)) for @cr;
}

if ($opt{dump}) {
	for my $ver ('old', 'new') {
		my $g = $ver eq 'old' ? $old : $new;
		my $c = creature($g, $opt{dump}) or do { print "$ver: not found\n"; next; };
		print "$ver ($g->{dir}):\n";
		for my $k (sort keys %$c) {
			my $v = $c->{$k};
			$v = join(', ', map { "$_ $v->{$_}" } grep { $v->{$_} } sort keys %$v) if ref $v eq 'HASH';
			print "  $k: $v\n";
		}
	}
	exit 0;
}

# ---------------------------------------------------------------------------------------------
# Encounters in the areas (BG1: AR####)

# Party level an area is usually visited at, by the first four characters of the resref (AR33 =
# Beregost and its buildings). A rough guide; edit freely. Areas not listed are skipped.
my %AREA_LEVEL = (
	AR26 => 1, AR23 => 1, AR25 => 2, AR33 => 2, AR34 => 2, AR47 => 2, AR48 => 2, AR49 => 2,
	AR24 => 3, AR27 => 3, AR28 => 3, AR29 => 3, AR30 => 3, AR31 => 3, AR32 => 3, AR50 => 3, AR53 => 3,
	AR54 => 3, AR55 => 3, AR19 => 4, AR37 => 4, AR38 => 4, AR40 => 4, AR41 => 4, AR42 => 4, AR43 => 4,
	AR44 => 4, AR46 => 4, AR51 => 4, AR52 => 4, AR16 => 5, AR17 => 5, AR21 => 5, AR22 => 5, AR35 => 5,
	AR36 => 5, AR39 => 5, AR45 => 5, AR13 => 5, AR14 => 5, AR18 => 6, AR15 => 6, AR20 => 6,
	AR01 => 7, AR02 => 7, AR03 => 7, AR04 => 7, AR06 => 7, AR07 => 7, AR08 => 7, AR09 => 7, AR10 => 7,
	AR11 => 7, AR12 => 7, AR05 => 8,
);
# Candlekeep's catacombs and the later Candlekeep chapter.
my %AREA_LEVEL_EXACT = (map { ("AR26$_" => 7) } qw(15 16 17 18 19));

# 2024 encounter XP budget per character (Low, Moderate, High) by level.
my %BUDGET = (1 => [50, 75, 100], 2 => [100, 150, 200], 3 => [150, 225, 400], 4 => [250, 375, 500],
	5 => [500, 750, 1100], 6 => [600, 1000, 1400], 7 => [750, 1300, 1700], 8 => [1000, 1700, 2100]);

# Hostile creatures placed close together count as one encounter.
my $CLUSTER_DISTANCE = 400;

my %partyCache;
sub party {
	my ($ver, $level) = @_;
	return $partyCache{"$ver$level"} //= [map { character($ver eq 'old' ? $old : $new, $_, $level, $ver) } @PARTY];
}

sub areaNames {
	my %name;
	my $d = load($new, 'WORLDMAP', 'WMP') // return \%name;
	my ($nmaps, $moff) = (u32($d, 8), u32($d, 12));
	for my $m (0 .. $nmaps - 1) {
		my $o = $moff + $m * 0xb8;
		my ($n, $aoff) = (u32($d, $o + 0x20), u32($d, $o + 0x24));
		for my $a (0 .. $n - 1) {
			my $e = $aoff + $a * 0xf0;
			my $label = str($new, s32($d, $e + 0x40));
			$name{substr(res($d, $e), 0, 4)} = $label if $label ne '';
		}
	}
	return \%name;
}

# Hostile actors of an area as [x, y, old creature, new creature].
sub hostileActors {
	my ($are) = @_;
	my @found;
	my %data;
	for my $ver ('old', 'new') {
		my $g = $ver eq 'old' ? $old : $new;
		my $d = load($g, $are, 'ARE') // return ();
		my ($aoff, $acnt) = (u32($d, 0x54), u16($d, 0x58));
		for my $i (0 .. $acnt - 1) {
			my $o = $aoff + $i * 0x110;
			my $res = res($d, $o + 0x80);
			my $c = $res ne '' ? creature($g, $res) : undef;
			$c //= creatureFrom($g, substr($d, u32($d, $o + 0x88), u32($d, $o + 0x8c)), "$are#$i") if u32($d, $o + 0x8c);
			$data{$ver}[$i] = [u16($d, $o + 0x20), u16($d, $o + 0x22), $c];
		}
	}
	for my $i (0 .. $#{$data{new}}) {
		my ($x, $y, $n) = @{$data{new}[$i]};
		my $o = $data{old}[$i] && $data{old}[$i][2];
		next unless $n && $o && $n->{ea} >= 200 && $n->{hp} > 0;
		push @found, [$x, $y, $o, $n];
	}
	return @found;
}

# Single-linkage groups of actors within $CLUSTER_DISTANCE.
sub clusters {
	my @actors = @_;
	my @group = (0 .. $#actors);
	my $root = sub { my $i = shift; $i = $group[$i] while $group[$i] != $i; return $i; };
	for my $i (0 .. $#actors) {
		for my $j ($i + 1 .. $#actors) {
			my ($dx, $dy) = ($actors[$i][0] - $actors[$j][0], $actors[$i][1] - $actors[$j][1]);
			next if $dx * $dx + $dy * $dy > $CLUSTER_DISTANCE ** 2;
			$group[$root->($i)] = $root->($j);
		}
	}
	my %by;
	push @{$by{$root->($_)}}, $actors[$_] for 0 .. $#actors;
	return values %by;
}

# Expected share of the party's HP lost: the party kills the quickest kill first (all four on one
# target), every opponent hits a random party member until it dies.
sub attrition {
	my ($ver, $level, @monsters) = @_;   # $ver: the party (monsters bring their own)
	my $party = party($ver, $level);
	my $partyHP = 0;
	$partyHP += $_->{hp} for @$party;
	my @m = map {
		my $c = $_;
		my $out = 0;
		$out += dpr($_, $c, $ver) for @$party;
		my $in = 0;
		$in += dpr($c, $_, $ver) / @$party for @$party;
		{ kill => $out > 0 ? $c->{hp} / $out : 1e9, dpr => $in };
	} @monsters;
	my ($t, $lost) = (0, 0);
	for my $x (sort { $a->{kill} <=> $b->{kill} } @m) {
		$t += $x->{kill};
		$lost += $x->{dpr} * $t;
	}
	return ($lost / $partyHP, $t);
}

sub encounters {
	my $names = areaNames();
	my @rows;
	for my $are (allRes($new, 'ARE')) {
		next unless $are =~ /^AR\d{4}$/;
		my $level = $AREA_LEVEL_EXACT{$are} // $AREA_LEVEL{substr($are, 0, 4)} // next;
		for my $cl (clusters(hostileActors($are))) {
			my @o = map { $_->[2] } @$cl;
			my @n = map { $_->[3] } @$cl;
			my ($lossOld, $tOld) = attrition('old', $level, @o);
			my ($lossNew, $tNew) = attrition('new', $level, @n);
			# Which side made the difference: old party against the new monsters, new party against the old.
			my ($lossOldParty) = attrition(q(old), $level, @n);
			my ($lossNewParty) = attrition(q(new), $level, @o);
			my $xp = 0;
			$xp += $CR_XP{$_->{special} ? '0' : challenge($_, $_->{apr} * $_->{dmg})} // 0 for @n;
			my $budget = $BUDGET{$level};
			my $per = $xp / 4;
			my $rating = $per <= $budget->[0] ? q(Low) : $per <= $budget->[1] ? q(Moderate) : $per <= $budget->[2] ? q(High) : sprintf(q(High x%.1f), $per / $budget->[2]);
			my %count;
			$count{$_->{name} . ($_->{caster} ? '*' : '') . ($_->{special} ? '-' : '')}++ for @n;
			my $who = join(', ', map { ($count{$_} > 1 ? "$count{$_} " : '') . $_ } sort { $count{$b} <=> $count{$a} || $a cmp $b } keys %count);
			my ($x, $y) = @{$cl->[0]};
			push @rows, { area => $are, name => $names->{substr($are, 0, 4)} // '', level => $level, who => $who,
				n => scalar @n, lossOld => $lossOld, lossNew => $lossNew, lossOldParty => $lossOldParty, lossNewParty => $lossNewParty, tOld => $tOld, tNew => $tNew, rating => $rating,
				xp => $xp, at => "$x,$y", unmodeled => scalar(grep { $_->{caster} || $_->{special} } @n) };
		}
	}
	return @rows;
}

sub areaReport {
	my @rows = encounters();
	my @harder = grep { $_->{lossNew} > 0.25 && $_->{lossNew} > 1.5 * $_->{lossOld} } @rows;
	line('');
	line('== Encounters (placed hostile creatures; spawn points not included) ==');
	line(sprintf('%d encounters in %d areas. Party: the four characters above at the area\'s usual level.', scalar @rows,
		scalar keys %{{ map { $_->{area} => 1 } @rows }}));
	line('"HP lost" = expected share of the party\'s HP lost, old > new; x2.0 = twice the party\'s HP (a wipe without');
	line('spells, healing or retreat). "rounds" = until the last one falls.');
	line('2024: the XP of the computed CRs against the 2024 budget for four characters. * casts spells, - gaze/breath');
	line('(not modeled: the fight is harder than shown).');
	my $fmt = '%-6s %-17s %3s %-15s %-11s %-16s %s';
	my $row = sub {
		my ($r) = @_;
		line(sprintf($fmt, $r->{area}, substr($r->{name}, 0, 17), $r->{level}, ch(pct($r->{lossOld}), pct($r->{lossNew})),
			ch($r->{tOld} > 99 ? 99 : $r->{tOld}, $r->{tNew} > 99 ? 99 : $r->{tNew}, '%.1f'), $r->{rating}, $r->{who}));
	};
	line('');
	line('-- Hardest fights in the new rules (by HP lost) --');
	line(sprintf($fmt, 'area', 'name', 'lvl', 'HP lost', 'rounds', '2024', 'opponents'));
	$row->($_) for (sort { $b->{lossNew} <=> $a->{lossNew} } @rows)[0 .. 24];
	line('');
	line(sprintf('-- Much harder than before: over 25%% of the party\'s HP and 1.5 times the old loss (%d) --', scalar @harder));
	line(sprintf($fmt, 'area', 'name', 'lvl', 'HP lost', 'rounds', '2024', 'opponents'));
	$row->($_) for sort { $b->{lossNew} / ($b->{lossOld} || 0.01) <=> $a->{lossNew} / ($a->{lossOld} || 0.01) } @harder;
	my @easier = grep { $_->{lossOld} > 0.25 && $_->{lossNew} < $_->{lossOld} / 1.5 } @rows;
	line('');
	line(sprintf('-- Much easier than before: old loss over 25%%, new under two thirds of it (%d) --', scalar @easier));
	line(sprintf($fmt, 'area', 'name', 'lvl', 'HP lost', 'rounds', '2024', 'opponents'));
	$row->($_) for sort { $a->{lossNew} / $a->{lossOld} <=> $b->{lossNew} / $b->{lossOld} } @easier;
	# Per area level: how the typical fight changed.
	line('');
	line('-- By party level: median HP lost per encounter --');
	line('Which side changed it: "monsters only" = old party against the new monsters, "party only" = new party');
	line('against the old monsters.');
	line(sprintf('%-6s %4s  %-6s %-14s %-11s %-6s  %s', 'level', 'fights', 'old', 'monsters only', 'party only', 'new', '2024 rating'));
	for my $l (sort { $a <=> $b } keys %{{ map { $_->{level} => 1 } @rows }}) {
		my @r = grep { $_->{level} == $l } @rows;
		my $median = sub { my @v = sort { $a <=> $b } @_; return $v[int($#v / 2)]; };
		my %ratings;
		$ratings{$_->{rating} =~ /^High x/ ? 'above High' : $_->{rating}}++ for @r;
		line(sprintf('%-6d %4d    %-6s %-14s %-11s %-6s  %s', $l, scalar @r,
			map({ my $k = $_; pct($median->(map { $_->{$k} } @r)) } qw(lossOld lossOldParty lossNewParty lossNew)),
			join(', ', map { "$ratings{$_} $_" } grep { $ratings{$_} } 'Low', 'Moderate', 'High', 'above High')));
	}
}

if ($opt{areas}) {
	areaReport();
} else {
	run();
	areaReport();
}
print "$_\n" for @out;

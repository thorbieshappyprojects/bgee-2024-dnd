#!/usr/bin/perl
# Offline data checks for an installed BG 2024 Rules Mod: reads the game's override folder,
# chitin.key and dialog.tlk (no game needed) and checks the installed files against the 2024
# rules the components are meant to write. Every check mirrors one install step in lib/*.tpa, so
# a failure means the install did not do what the source says (or the source changed and this
# check needs the same change).
#
# Usage: perl tools/datacheck.pl [-v] [game folder ...]   (default: C:/BG/BGEE C:/BG/BG2EE)
# Exit code 1 if any check fails.
use strict;
use warnings;

my $verbose = 0;
my @games;
for (@ARGV) { if ($_ eq '-v') { $verbose = 1 } else { push @games, $_ } }
@games = ('C:/BG/BGEE', 'C:/BG/BG2EE') unless @games;
(my $modRoot = $0) =~ s{[\\/]tools[\\/][^\\/]+$}{};
$modRoot = '.' if $modRoot eq $0;

my $MAX_SHOWN = 12;     # failures listed per check
my $totalFailed = 0;

# ---------------------------------------------------------------------------------------------
# Helpers

sub slurp { my ($p) = @_; open(my $fh, '<:raw', $p) or return undef; local $/; my $d = <$fh>; close $fh; return $d; }
sub u8  { unpack('C', substr($_[0], $_[1], 1)) }
sub s8  { unpack('c', substr($_[0], $_[1], 1)) }
sub u16 { unpack('v', substr($_[0], $_[1], 2)) }
sub s16 { unpack('s<', substr($_[0], $_[1], 2)) }
sub u32 { unpack('V', substr($_[0], $_[1], 4)) }
sub s32 { unpack('l<', substr($_[0], $_[1], 4)) }
sub res { my $r = substr($_[0], $_[1], 8); $r =~ s/\0.*//s; return uc $r; }

sub abilityMod { my ($s) = @_; return $s >= 10 ? int(($s - 10) / 2) : -int((11 - $s) / 2); }
sub profBonus  { my ($l, $max) = @_; $max //= 20; $l = 1 if $l < 1; $l = $max if $l > $max; return 2 + int(($l - 1) / 4); }

# 2DA: { default, cols => [names], rows => [[label, v1, ...], ...], byLabel => {LABEL => row} }
sub parse2da {
	my ($text) = @_;
	return undef unless defined $text;
	my @lines = grep { /\S/ } split /\r?\n/, $text;
	return undef unless @lines >= 3 && $lines[0] =~ /^\s*2DA/i;
	my %t = (default => (split ' ', $lines[1])[0] // '', cols => [split ' ', $lines[2]], rows => [], byLabel => {});
	for my $l (@lines[3 .. $#lines]) {
		my @f = split ' ', $l;
		push @{$t{rows}}, \@f;
		$t{byLabel}{uc $f[0]} //= \@f;
	}
	return \%t;
}

# ---------------------------------------------------------------------------------------------
# Check bookkeeping

my %result;      # check => [failures]
my %knownHit;    # check => [known issues seen]
my @order;

# Known, accepted problems: check => [message prefix, reason]. They are listed, but don't fail.
my %known = (
	'text: no 2e save wording in item/spell texts' => [
		['BDBLUN01 ', 'SoD item with a school save bonus (op346), which B24SAVE.lua does not apply yet'],
	],
);

sub check { my ($name) = @_; unless (exists $result{$name}) { $result{$name} = []; $knownHit{$name} = []; push @order, $name; } }
sub fail {
	my ($name, $msg) = @_;
	check($name);
	for my $k (@{$known{$name} || []}) {
		if (index($msg, $k->[0]) == 0) { push @{$knownHit{$name}}, "$msg (known: $k->[1])"; return; }
	}
	push @{$result{$name}}, $msg;
}

sub report {
	my ($game) = @_;
	my ($pass, $failc) = (0, 0);
	for my $c (@order) {
		my @f = @{$result{$c}};
		if (@f) {
			$failc++;
			printf "  FAIL  %-34s %d problem%s\n", $c, scalar @f, @f == 1 ? '' : 's';
			my $n = 0;
			for (@f) { last if ++$n > ($verbose ? 1e9 : $MAX_SHOWN); print "          $_\n"; }
			print "          ... and ", @f - $MAX_SHOWN, " more (-v lists all)\n" if !$verbose && @f > $MAX_SHOWN;
		} else {
			$pass++;
			printf "  ok    %s\n", $c;
		}
		print "          $_\n" for @{$knownHit{$c}};
	}
	print "  $game: $pass passed, $failc failed\n\n";
	$totalFailed += $failc;
	%result = (); %knownHit = (); @order = ();
}

# ---------------------------------------------------------------------------------------------
# Per game

for my $game (@games) {
	print "=== $game ===\n";
	my $ov = "$game/override";
	unless (-d $ov) { print "  no override folder, skipped\n\n"; next; }

	# Resource index: override file names, plus chitin.key names.
	my (%ovFile, %exists);
	opendir(my $dh, $ov) or die "$ov: $!";
	for my $f (readdir $dh) {
		next unless $f =~ /^(.+)\.([^.]+)$/;
		$ovFile{uc "$1.$2"} = "$ov/$f";
		$exists{uc $1} = 1;
	}
	closedir $dh;
	my $key = slurp("$game/chitin.key");
	if ($key && substr($key, 0, 8) eq 'KEY V1  ') {
		my ($nres, $roff) = (u32($key, 12), u32($key, 20));
		for my $i (0 .. $nres - 1) { $exists{res($key, $roff + $i * 14)} = 1; }
	}
	my $ovText = sub { my $p = $ovFile{uc $_[0]}; return defined $p ? slurp($p) : undef; };
	my $ov2da = sub { return parse2da($ovText->($_[0])); };

	# dialog.tlk
	my $tlk = slurp("$game/lang/en_US/dialog.tlk");
	my ($tlkCount, $tlkStr) = $tlk ? (u32($tlk, 10), u32($tlk, 14)) : (0, 0);
	my $str = sub {
		my ($ref) = @_;
		return '' if !$tlk || $ref < 0 || $ref >= $tlkCount;
		my $e = 18 + $ref * 26;
		return substr($tlk, $tlkStr + u32($tlk, $e + 18), u32($tlk, $e + 22));
	};

	# --- Install ---------------------------------------------------------------------------
	{
		my $c = 'install: WeiDU.log components';
		check($c);
		my $log = slurp("$game/WeiDU.log") // '';
		my %inst;
		for (split /\r?\n/, $log) { $inst{$1} = 1 if m{^~BG2024[\\/]BG2024\.TP2~\s+#\d+\s+#(\d+)}i; }
		for my $comp (1 .. 5) { fail($c, "component $comp is not installed") unless $inst{$comp}; }

		$c = 'install: no BG2024 warnings';
		check($c);
		my $dbg = slurp("$game/setup-bg2024.debug") // '';
		my %seen;
		for (split /\r?\n/, $dbg) { fail($c, $_) if /BG2024 warning/ && !$seen{$_}++; }
	}

	# --- Core tables -----------------------------------------------------------------------
	{
		my $c = 'tables: STRMOD';
		check($c);
		my $t = $ov2da->('strmod.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) {
				next unless $r->[0] =~ /^\d+$/;
				my $m = abilityMod($r->[0]);
				fail($c, "Str $r->[0]: to-hit $r->[1], damage $r->[2], expected $m") if $r->[1] != $m || $r->[2] != $m;
			}
		}

		$c = 'tables: STRMODEX zeroed';
		check($c);
		$t = $ov2da->('strmodex.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) { fail($c, "row $r->[0]: @$r[1,2]") if $r->[1] != 0 || $r->[2] != 0; }
		}

		$c = 'tables: DEXMOD';
		check($c);
		$t = $ov2da->('dexmod.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) {
				next unless $r->[0] =~ /^\d+$/;
				my $m = abilityMod($r->[0]);
				fail($c, "Dex $r->[0]: missile $r->[2], AC $r->[3], expected $m / " . -$m) if $r->[2] != $m || $r->[3] != -$m;
			}
		}

		$c = 'tables: HPCONBON';
		check($c);
		$t = $ov2da->('hpconbon.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) {
				next unless $r->[0] =~ /^\d+$/;
				my $m = abilityMod($r->[0]);
				fail($c, "Con $r->[0]: @$r[1,2], expected $m") if $r->[1] != $m || $r->[2] != $m;
			}
		}

		$c = 'tables: THAC0 = 20 - proficiency';
		check($c);
		$t = $ov2da->('thac0.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) {
				for my $col (1 .. $#$r) {
					my $want = 20 - profBonus($col);
					fail($c, "$r->[0] level $col: $r->[$col], expected $want") if $r->[$col] != $want;
				}
			}
		}

		$c = 'tables: WSPATCK Extra Attack at 5';
		check($c);
		$t = $ov2da->('wspatck.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) {
				for my $col (1 .. $#$r) {
					my $want = $col >= 5 ? 1 : 0;
					fail($c, "row $r->[0] level $col: $r->[$col], expected $want") if $r->[$col] != $want;
				}
			}
		}

		# Tables whose value columns are all set to one value.
		my @flat = (
			['skilldex.2da', 0, 'tables: SKILLDEX zeroed'],
			['stylbonu.2da', 0, 'tables: STYLBONU zeroed'],
			['mxsplwis.2da', 0, 'tables: MXSPLWIS zeroed'],
			['abracead.2da', 0, 'tables: ABRACEAD zeroed'],
			['abclasrq.2da', 0, 'tables: ABCLASRQ zeroed'],
			['backstab.2da', 1, 'tables: BACKSTAB x1'],
		);
		for my $f (@flat) {
			my ($file, $want, $name) = @$f;
			check($name);
			$t = $ov2da->($file);
			if (!$t) { fail($name, 'missing from override'); next; }
			for my $r (@{$t->{rows}}) {
				for my $col (1 .. $#$r) { fail($name, "row $r->[0] column $col: $r->[$col]") if $r->[$col] ne $want; }
			}
		}

		$c = 'tables: WSPECIAL no bonuses';
		check($c);
		$t = $ov2da->('wspecial.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) { fail($c, "row $r->[0]: @$r[1,2]") if $r->[1] != 0 || $r->[2] != 0; }
		}

		$c = 'tables: ABRACERQ limits 3-20';
		check($c);
		$t = $ov2da->('abracerq.2da');
		if (!$t) { fail($c, 'missing from override') } else {
			for my $r (@{$t->{rows}}) {
				for my $col (1 .. 12) {
					my $want = ($col % 2) ? 3 : 20;
					fail($c, "$r->[0] column $col: " . ($r->[$col] // '(none)')) if ($r->[$col] // -1) != $want;
				}
			}
		}

		$c = 'tables: RACETHAC zeroed';
		check($c);
		$t = $ov2da->('racethac.2da');
		if ($t) {
			for my $r (@{$t->{rows}}) {
				for my $col (2 .. $#$r) { fail($c, "row $r->[0] column $col: $r->[$col]") if $r->[$col] ne '0'; }
			}
		}

		$c = 'tables: HP tables (2024 averages)';
		check($c);
		my $hp = parse2da(slurp("$modRoot/tables/b24hp.2da"));
		if (!$hp) { fail($c, 'tables/b24hp.2da not readable') } else {
			for my $spec (@{$hp->{rows}}) {
				my ($table, $l1, $even, $odd) = @$spec;
				my $ht = $ov2da->("$table.2da");
				next unless $ht;     # table not in this game
				for my $r (@{$ht->{rows}}) {
					next unless $r->[0] =~ /^\d+$/;
					my $lvl = $r->[0];
					my $want = $lvl == 1 ? $l1 : $lvl <= 20 ? (($lvl % 2) ? $odd : $even) : 0;
					my $got = $r->[1] * $r->[2] + $r->[3];
					fail($c, "$table level $lvl: $r->[1]x$r->[2]+$r->[3] = $got, expected $want")
						if $got != $want || $r->[3] != 0 || ($want > 0 && $r->[1] != 1);
				}
			}
			# Every HP table in HPCLASS must be one the mod converts.
			my $hc = $ov2da->('hpclass.2da');
			my %known = map { uc($_->[0]) => 1 } @{$hp->{rows}};
			if ($hc) { for my $r (@{$hc->{rows}}) { fail($c, "HPCLASS uses unconverted table $r->[1] ($r->[0])") unless $known{uc $r->[1]}; } }
		}

		$c = 'tables: spell slots match mod tables';
		check($c);
		my %slotFiles = map { ($_ => $_) } qw(mxsplwiz mxsplsrc mxsplbrd mxsplprs mxspldru mxsplpal mxsplran splsrckn);
		$slotFiles{mxspldd} = 'mxsplsrc';
		for my $game2da (sort keys %slotFiles) {
			my $src = slurp("$modRoot/tables/b24_$slotFiles{$game2da}.2da");
			my $inst = $ovText->("$game2da.2da");
			next unless defined $inst || $game2da ne 'mxspldd';
			if (!defined $inst) { fail($c, "$game2da.2da missing from override"); next; }
			my $norm = sub { my $s = shift; $s =~ s/\s+/ /g; $s =~ s/^ | $//g; return $s; };
			fail($c, "$game2da.2da differs from tables/b24_$slotFiles{$game2da}.2da") if $norm->($src) ne $norm->($inst);
		}
	}

	# --- Mod data tables well-formed -----------------------------------------------------------
	{
		my $c = 'tables: B24*.2DA well-formed';
		check($c);
		for my $f (sort grep { /^B24.*\.2DA$/ } keys %ovFile) {
			my $t = parse2da(slurp($ovFile{$f}));
			if (!$t) { fail($c, "$f: not a 2DA"); next; }
			my $ncol = @{$t->{cols}};
			# A row label listed twice is fine if both rows say the same (the engine reads the first).
			my %first;
			for my $r (@{$t->{rows}}) {
				fail($c, "$f row $r->[0]: " . (@$r - 1) . " values, header has $ncol") if @$r - 1 < $ncol;
				my $vals = join ' ', @$r[1 .. $#$r];
				my $prev = $first{uc $r->[0]};
				fail($c, "$f: row $r->[0] twice with different values ($prev / $vals)") if defined $prev && $prev ne $vals;
				$first{uc $r->[0]} //= $vals;
			}
		}
	}

	# --- Lua runtime ---------------------------------------------------------------------------
	{
		my $c = 'lua: installed files match source';
		check($c);
		my %installedBy;    # which Lua files a component copies, from the tpa sources
		for my $tpa (glob("$modRoot/lib/*.tpa")) {
			my $src = slurp($tpa);
			$installedBy{uc $1} = 1 while $src =~ m{~bg2024/lua/([^~]+\.(?:lua|menu))~}gi;
		}
		for my $f (sort keys %installedBy) {
			my $src = slurp("$modRoot/lua/$f") // slurp("$modRoot/lua/" . lc $f);
			my ($name) = grep { uc($_) eq $f } map { s{.*/}{}r } glob("$modRoot/lua/*");
			$src = slurp("$modRoot/lua/$name") if $name;
			my $inst = $ovText->($f);
			if (!defined $inst) { fail($c, "$f not in override"); next; }
			next if $f =~ /\.MENU$/;    # menus are patched at install time
			(my $a = $src // '') =~ s/\r//g;
			(my $b = $inst) =~ s/\r//g;
			fail($c, "$f differs from lua/$f (stale install? run deploy.ps1)") if $a ne $b;
		}
		for my $f (map { s{.*/}{}r } glob("$modRoot/lua/*.lua")) {
			fail($c, "lua/$f is not installed by any component") unless $installedBy{uc $f};
		}

		$c = 'lua: referenced resources exist';
		check($c);
		my %missing;
		for my $file (glob("$modRoot/lua/*.lua")) {
			my $src = slurp($file);
			(my $short = $file) =~ s{.*/}{};
			my $ln = 0;
			for my $line (split /\n/, $src) {
				$ln++;
				next if $line =~ /^\s*--/;
				# Fields and calls that take a resref; a string followed by ".." is a name prefix.
				while ($line =~ /(?:\b(?:res|spell|resref)\s*=|\b(?:Infinity_DoFile|LoadTable|EEex_Resource_Demand)\s*\()\s*"([A-Za-z0-9_#]{3,8})"(?!\s*\.\.)/g) {
					my $r = uc $1;
					next if $exists{$r} || $missing{$r}++;
					fail($c, "$short:$ln: \"$r\"");
				}
			}
		}

		$c = 'ui: UI.MENU patched';
		check($c);
		my $menu = $ovText->('ui.menu') // '';
		for my $needle ('B24UI_AC(characters[id].AC.current)', 'B24UI_ACDetails(id)', 'B24UI_AttackDetails(id)', 'B24CG_') {
			fail($c, "no \"$needle\"") if index($menu, $needle) < 0;
		}
		fail($c, 'unpatched "characters[id].AC.current" left') if $menu =~ /"characters\[id\]\.AC\.current"/;

		$c = 'scripts: global script hooked';
		check($c);
		my $baf = slurp("$modRoot/lib/b24baldr.baf") // '';
		my @calls = $baf =~ /EEex_Lua(?:Trigger|Action)\("([^"(]+)/g;
		my $found = 0;
		for my $bcs (qw(BALDUR.BCS BALDUR25.BCS BDBALDUR.BCS)) {
			my $b = $ovText->($bcs);
			next unless defined $b;
			$found++;
			for my $call (@calls) { fail($c, "$bcs has no $call") if index($b, $call) < 0; }
		}
		fail($c, 'no patched BALDUR.BCS in override') unless $found;
	}

	# --- Items ---------------------------------------------------------------------------------
	{
		my @c = ('items: weapon bonuses <= +5', 'items: armor AC in 2024 range', 'items: shield AC +1..+7',
			'items: ring/amulet AC <= +2', 'items: no +6..+9 in names', 'items: structure');
		check($_) for @c;
		for my $f (sort grep { /\.ITM$/ } keys %ovFile) {
			my $d = slurp($ovFile{$f});
			next unless length($d) > 0x72 && substr($d, 0, 8) eq 'ITM V1  ';
			(my $res = $f) =~ s/\.ITM$//;
			my ($type, $hoff, $hnum, $foff, $fidx, $fnum) = (u16($d, 0x1c), u32($d, 0x64), u16($d, 0x68), u32($d, 0x6a), u16($d, 0x6e), u16($d, 0x70));
			my $len = length $d;
			if ($hoff + $hnum * 0x38 > $len) { fail($c[5], "$res: extended headers past end of file"); next; }
			my $maxFx = 0;
			for my $h (0 .. $hnum - 1) {
				my $o = $hoff + $h * 0x38;
				my ($n, $i) = (u16($d, $o + 0x1e), u16($d, $o + 0x20));
				$maxFx = $i + $n if $i + $n > $maxFx;
				my $atype = u8($d, $o);
				if ($atype == 1 || $atype == 2 || $atype == 4) {
					my ($hit, $dmg) = (s16($d, $o + 0x14), s16($d, $o + 0x1a));
					fail($c[0], "$res header $h: to-hit $hit") if $hit > 5 && $hit < 100;
					fail($c[0], "$res header $h: damage bonus $dmg") if $dmg > 5;
				}
			}
			$maxFx = $fidx + $fnum if $fidx + $fnum > $maxFx;
			if ($foff + $maxFx * 0x30 > $len) { fail($c[5], "$res: effects past end of file"); next; }

			# First set-base-AC and first AC-bonus equipping effects (as the install patch reads them).
			my ($base, $bonus);
			for my $k (0 .. $fnum - 1) {
				my $o = $foff + ($fidx + $k) * 0x30;
				next unless u16($d, $o) == 0;
				my $p2 = u32($d, $o + 8);
				$base  //= s32($d, $o + 4) if $p2 == 16;
				$bonus //= s32($d, $o + 4) if $p2 == 0;
			}
			my ($a0, $a1) = (u8($d, 0x22), u8($d, 0x23));
			if ($type == 2 && defined $base && ($a1 == 65 && $a0 >= 50 && $a0 <= 52 || $a1 == 87)) {
				my $ac = 20 - $base;
				fail($c[1], "$res: AC $ac") if $ac < 10 || $ac > 21;
			} elsif ($type == 12 && defined $bonus) {
				fail($c[2], "$res: shield +$bonus") if $bonus < 1 || $bonus > 7;
			} elsif ($type != 2 && $type != 12) {
				fail($c[3], "$res: AC bonus +$bonus") if defined $bonus && $bonus > 2;
				fail($c[3], "$res: sets base AC " . (20 - $base)) if defined $base && $base < 5;
			}
			my $prof = u8($d, 0x31);
			if ($type == 2 || $type == 12 || $prof > 0 || $type == 5 || $type == 14 || $type == 31) {
				for my $off (0x08, 0x0c) {
					my $name = $str->(s32($d, $off));
					fail($c[4], "$res: \"$name\"") if $name =~ / \+[6-9]\b/;
				}
			}
		}
	}

	# --- Creatures -----------------------------------------------------------------------------
	{
		my @c = ('creatures: monster AC 10-22', 'creatures: ability scores <= 25, no 18/xx', 'creatures: THAC0 1-25');
		check($_) for @c;
		my %party;
		my $pd = $ov2da->('pdialog.2da');
		if ($pd) { $party{uc $_->[0]} = 1 for @{$pd->{rows}}; }
		for my $f (sort grep { /\.CRE$/ } keys %ovFile) {
			my $d = slurp($ovFile{$f});
			next unless length($d) > 0x2d3 && substr($d, 0, 8) eq 'CRE V1.0';
			(my $res = $f) =~ s/\.CRE$//;
			my $dv = substr($d, 0x280, 32); $dv =~ s/\0.*//s;
			next if $party{uc $dv} || u8($d, 0x270) == 2 || $res =~ /^CHARBASE/ || $res =~ /^B24/;
			for my $off (0x46, 0x48) {
				my $ac = s16($d, $off);
				fail($c[0], "$res: engine AC $ac (2024 AC " . (20 - $ac) . ")") if $ac < -2 || $ac > 10;
			}
			fail($c[1], "$res: 18/" . u8($d, 0x239)) if u8($d, 0x239) != 0;
			for my $off (0x238 .. 0x23e) {
				next if $off == 0x239;
				fail($c[1], "$res: score " . u8($d, $off)) if u8($d, $off) > 25;
			}
			my $t = u8($d, 0x52);
			fail($c[2], "$res: THAC0 $t") if $t < 1 || $t > 25;
		}
	}

	# --- Spells --------------------------------------------------------------------------------
	{
		my @c = ('spells: catalog levels', 'spells: dropped spells hidden', 'spells: re-filed spells',
			'spells: upcast versions', 'spells: catalog names', 'spells: priest list flags',
			'spells: save and concentration tables', 'spells: catalog damage dice', 'spells: structure',
			'spells: effect resources exist', 'spells: SPELL.IDS has re-filed spells', 'spells: 2024 ranges');
		check($_) for @c;
		my $cat = parse2da(slurp("$modRoot/tables/b24spell.2da"));
		my $hide = $ov2da->('hidespl.2da');
		my %hidden = $hide ? map { (uc($_->[0]) => $_->[1]) } @{$hide->{rows}} : ();
		my $moved = $ov2da->('b24moved.2da');
		my %movedTo = $moved ? map { (uc($_->[0]) => uc($_->[1])) } @{$moved->{rows}} : ();
		my $sv = $ov2da->('b24saves.2da');
		my %saves = $sv ? map { (uc($_->[0]) => uc($_->[1])) } @{$sv->{rows}} : ();
		my $cc = $ov2da->('b24conc.2da');
		my %conc = $cc ? map { (uc($_->[0]) => 1) } @{$cc->{rows}} : ();
		# Touch range: Cure Wounds' (SPPR103), as the install takes it.
		my $cure = $ovText->('sppr103.spl') // $ovText->('SPPR103.SPL');
		my $touch = ($cure && length($cure) >= 0x72) ? u16($cure, u32($cure, 0x64) + 0x0e) : undef;
		my $ids = $ovText->('spell.ids') // '';
		my %ids;
		$ids{uc $2} = $1 while $ids =~ /^\s*(\d+)\s+(\S+)/mg;

		my $spl = sub {
			my $d = $ovText->("$_[0].spl");
			return (defined $d && length($d) >= 0x72 && substr($d, 0, 8) eq 'SPL V1  ') ? $d : undef;
		};
		# op12 dice of the first damage effect in the first header.
		my $dice = sub {
			my ($d) = @_;
			my ($hoff, $hnum, $foff) = (u32($d, 0x64), u16($d, 0x68), u32($d, 0x6a));
			for my $h (0 .. $hnum - 1) {
				my ($n, $i) = (u16($d, $hoff + $h * 0x28 + 0x1e), u16($d, $hoff + $h * 0x28 + 0x20));
				for my $k (0 .. $n - 1) {
					my $o = $foff + ($i + $k) * 0x30;
					my $op = u16($d, $o);
					return ('D', u32($d, $o + 0x1c), u32($d, $o + 0x20), s32($d, $o + 4)) if $op == 12;
					return ('H', u32($d, $o + 4), u32($d, $o + 8), s32($d, $o + 0x2c)) if $op == 402 && res($d, $o + 0x14) eq 'B24HEAL';
					return ('D', u32($d, $o + 4), u32($d, $o + 8), s32($d, $o + 0x2c)) if $op == 402 && res($d, $o + 0x14) =~ /^B24(SATK|RAYS|DART)$/;
				}
			}
			return ();
		};
		my $parseDice = sub {
			my ($t) = @_;
			my ($n, $s, $flat, $heal) = (0, 0, 0, 0);
			$heal = 1 if $t =~ s/^H//;
			if ($t =~ s/^F//) { return (0, 0, $t + 0, 1); }
			$flat = $1 if $t =~ s/\+(\d+)$//;
			($n, $s) = ($1, $2) if $t =~ /^(\d+)d(\d+)$/;
			return ($n, $s, $flat, $heal);
		};

		for my $row ($cat ? @{$cat->{rows}} : ()) {
			my ($res, $action, $level, $lists, $concF, $save, $diceT, $upcast, $range, $name) = @$row;
			$res = uc $res;
			my $d = $spl->($res);
			next unless $d || $ovFile{"$res.SPL"};
			if (!$d) { fail($c[8], "$res: not an SPL V1"); next; }
			if ($action eq 'DROP') {
				fail($c[1], "$res is not in HIDESPL.2DA") unless $hidden{$res};
				next;
			}
			my $lvl = u32($d, 0x34);
			fail($c[0], "$res: level $lvl, catalog $level") if $lvl != $level;
			if ($res =~ /^SP(WI|PR)(\d)/ && $2 != $level) {
				my $new = $movedTo{$res};
				if (!$new) { fail($c[2], "$res (level $level) has no B24MOVED.2DA entry"); }
				else {
					my $nd = $spl->($new);
					if (!$nd) { fail($c[2], "$res -> $new: $new.SPL missing"); }
					else {
						fail($c[2], "$res -> $new: new name is not level $level") unless $new =~ /^SP(?:WI|PR)$level\d\d$/;
						fail($c[2], "$res -> $new: SPL level " . u32($nd, 0x34)) if u32($nd, 0x34) != $level;
					}
					fail($c[2], "$res: original not hidden") unless $hidden{$res};
					fail($c[10], "$new not in SPELL.IDS") unless $ids{"B24_$res"};
				}
			}
			if ($name ne '-') {
				(my $want = $name) =~ s/_/ /g;
				my $got = $str->(s32($d, 0x08));
				fail($c[4], "$res: \"$got\", expected \"$want\"") if $got ne $want;
			}
			# The 2024 range on the headers that target a creature or a point (feet, capped at 300; T: touch).
			if (defined $range && $range ne '-') {
				my $want = $range eq 'T' ? $touch : ($range > 300 ? 300 : $range);
				my ($hoff, $hnum) = (u32($d, 0x64), u16($d, 0x68));
				for my $h (0 .. $hnum - 1) {
					my $t = u8($d, $hoff + $h * 0x28 + 0x0c);
					next if $t == 5 || $t == 7;
					my $got = u16($d, $hoff + $h * 0x28 + 0x0e);
					fail($c[11], "$res header $h: range $got, catalog $range") if defined $want && $got != $want;
				}
			}
			if (u16($d, 0x1c) == 2) {
				my $excl = u32($d, 0x1e);
				my ($cl, $dr) = ($lists =~ /C/ ? 1 : 0, $lists =~ /D/ ? 1 : 0);
				# Bit 30: not for clerics and paladins, bit 31: not for druids and rangers.
				my $notCleric = ($excl & 0x40000000) ? 1 : 0;
				my $notDruid  = ($excl & 0x80000000) ? 1 : 0;
				fail($c[5], "$res: lists $lists, but excluded for clerics") if $cl && $notCleric;
				fail($c[5], "$res: lists $lists, but excluded for druids") if $dr && $notDruid;
				fail($c[5], "$res: lists $lists, but clerics can learn it") if !$cl && $dr && !$notCleric;
				fail($c[5], "$res: lists $lists, but druids can learn it") if !$dr && $cl && !$notDruid;
			}
			fail($c[6], "$res: save $save, B24SAVES has " . ($saves{$res} // 'nothing')) if $save ne '-' && ($saves{$res} // '') ne $save;
			fail($c[6], "$res: concentration, not in B24CONC") if $concF eq '1' && !$conc{$res};
			fail($c[6], "$res: in B24CONC, catalog says no concentration") if $concF ne '1' && $conc{$res};

			my ($bn, $bs, $bflat, $bheal) = $diceT ne '-' ? $parseDice->($diceT) : (0, 0, 0, 0);
			if ($diceT ne '-') {
				my ($kind, $n, $s, $flat) = $dice->($d);
				if (!$kind) { fail($c[7], "$res: catalog $diceT, no damage, B24HEAL, B24SATK, B24RAYS or B24DART effect"); }
				elsif ($bheal && $kind ne 'H') { fail($c[7], "$res: catalog $diceT is healing, spell has op12"); }
				elsif ($n != $bn || $s != $bs || $flat != $bflat) { fail($c[7], "$res: ${n}d$s+$flat, catalog $diceT"); }
			}
			if ($upcast ne '-') {
				my ($un, $us, $uflat) = $parseDice->($upcast);
				my $max = u16($d, 0x1c) == 2 ? 7 : 9;
				for my $up ($level + 1 .. $max) {
					my $ur = "$res$up";
					my $ud = $spl->($ur);
					if (!$ud) { fail($c[3], "$ur missing"); next; }
					fail($c[3], "$ur: level " . u32($ud, 0x34)) if u32($ud, 0x34) != $up;
					if ($diceT ne '-') {
						my $steps = $up - $level;
						my ($kind, $n, $s, $flat) = $dice->($ud);
						my ($wn, $wflat) = ($bn + $steps * $un, $bflat + $steps * $uflat);
						fail($c[3], "$ur: " . ($kind ? "${n}d$s+$flat" : 'no damage') . ", expected ${wn}d$bs+$wflat")
							if !$kind || $n != $wn || $s != $bs || $flat != $wflat;
					}
					fail($c[6], "$ur: no B24SAVES row") if $save ne '-' && ($saves{$ur} // '') ne $save;
					fail($c[6], "$ur: no B24CONC row") if $concF eq '1' && !$conc{$ur};
					if (u16($d, 0x1c) != 2) { fail($c[3], "$ur: not hidden") unless $hidden{$ur}; }
					else { fail($c[3], "$ur: priest version not filed under an SPPR$up name") unless ($movedTo{$ur} // '') =~ /^SPPR$up\d\d$/; }
				}
			}
		}

		# Structure and resource references of the mod's own spells (B24*) and the catalog.
		my %catRes = $cat ? map { (uc($_->[0]) => 1) } @{$cat->{rows}} : ();
		# Opcodes whose resource is cast or applied (op206 and similar only name a spell to block,
		# and vanilla files block missing ones harmlessly).
		my %resOps = (146 => 1, 148 => 1, 326 => 1, 177 => 1, 183 => 1, 232 => 1, 333 => 1);
		for my $f (sort grep { /\.SPL$/ } keys %ovFile) {
			(my $res = $f) =~ s/\.SPL$//;
			next unless $res =~ /^B24/ || $catRes{substr($res, 0, 7)};
			my $d = slurp($ovFile{$f});
			if (length($d) < 0x72 || substr($d, 0, 8) ne 'SPL V1  ') { fail($c[8], "$res: not an SPL V1"); next; }
			my ($hoff, $hnum, $foff, $fidx, $fnum) = (u32($d, 0x64), u16($d, 0x68), u32($d, 0x6a), u16($d, 0x6e), u16($d, 0x70));
			my $len = length $d;
			if ($hoff + $hnum * 0x28 > $len) { fail($c[8], "$res: extended headers past end of file"); next; }
			fail($c[8], "$res: no extended header") if $hnum == 0 && $res =~ /^B24/;
			my @groups = ([$fidx, $fnum]);
			push @groups, [u16($d, $hoff + $_ * 0x28 + 0x20), u16($d, $hoff + $_ * 0x28 + 0x1e)] for 0 .. $hnum - 1;
			for my $g (@groups) {
				my ($i, $n) = @$g;
				if ($foff + ($i + $n) * 0x30 > $len) { fail($c[8], "$res: effects past end of file"); last; }
				for my $k (0 .. $n - 1) {
					my $o = $foff + ($i + $k) * 0x30;
					my $op = u16($d, $o);
					next unless exists $resOps{$op} && $resOps{$op};
					my $r = res($d, $o + 0x14);
					fail($c[9], "$res: op$op -> \"$r\" does not exist") if $r ne '' && !$exists{$r};
				}
			}
		}
	}

	# --- Texts ---------------------------------------------------------------------------------
	{
		my $c = 'text: no 2e save wording in item/spell texts';
		check($c);
		my %seen;
		for my $f (sort grep { /\.(ITM|SPL)$/ } keys %ovFile) {
			my $d = slurp($ovFile{$f});
			next unless length($d) > 0x58;
			my @refs = $f =~ /\.ITM$/ ? (0x50, 0x54) : (0x50);
			for my $off (@refs) {
				my $ref = s32($d, $off);
				next if $ref <= 0 || $seen{$ref}++;
				my $t = $str->($ref);
				if ($t =~ /(save (?:vs\.?|versus) [a-z][a-z ]*)/i) { my $w = $1; (my $r = $f) =~ s/\..*//; fail($c, "$r (strref $ref): \"$w\""); }
			}
		}
	}

	report($game);
}

print $totalFailed ? "FAILED: $totalFailed check(s)\n" : "All checks passed\n";
exit($totalFailed ? 1 : 0);

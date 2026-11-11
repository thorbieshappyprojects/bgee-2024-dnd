#!/usr/bin/perl
# BG 2024 Rules Mod: PNG to BAM icon converter for spell and ability icons.
#
#   perl tools/png2bam.pl art/icons/B24SWIND.png icons/B24SWIND.bam
#   perl tools/png2bam.pl art/icons icons          # every PNG of a folder
#   perl tools/png2bam.pl --portrait art/portraits icons   # portrait (status) icons, 13x13
#
# The game's icons are BAM files of at most 32x32 pixels with two cycles (the icon and a darker
# pressed state), 256 colors, palette index 0 transparent. Any PNG works as input (8-bit RGB or
# RGBA, also larger art): it is scaled down to fit 32x32, pixels under half opacity become
# transparent, and the colors are reduced to 127 by median cut. Name the PNG after the spell or
# innate it belongs to (B24SWIND.png for Second Wind): the install (lib/b24_util.tpa,
# b24_install_icons) copies icons/<RESREF>.bam and makes that spell use it.

use strict;
use warnings;
use Compress::Zlib;

# --portrait: portrait (status) icons, 13x13 with one frame.
my $PORTRAIT = @ARGV && $ARGV[0] eq '--portrait' ? shift : 0;
my $SIZE = $PORTRAIT ? 13 : 32;

sub readPng {
	my ($file) = @_;
	open my $fh, '<:raw', $file or die "$file: $!\n";
	local $/;
	my $d = <$fh>;
	close $fh;
	die "$file: not a PNG\n" unless substr($d, 0, 8) eq "\x89PNG\r\n\x1a\n";
	my ($pos, $idat, %h, $plte, $trns) = (8, '');
	while ($pos < length $d) {
		my ($len, $type) = unpack('Na4', substr($d, $pos, 8));
		my $data = substr($d, $pos + 8, $len);
		if ($type eq 'IHDR') { @h{qw(w h depth color comp filter interlace)} = unpack('NNCCCCC', $data); }
		elsif ($type eq 'PLTE') { $plte = $data; }
		elsif ($type eq 'tRNS') { $trns = $data; }
		elsif ($type eq 'IDAT') { $idat .= $data; }
		$pos += 12 + $len;
	}
	die "$file: only 8-bit PNGs are supported\n" unless $h{depth} == 8;
	die "$file: interlaced PNGs are not supported\n" if $h{interlace};
	my %channels = (0 => 1, 2 => 3, 3 => 1, 4 => 2, 6 => 4);
	my $bpp = $channels{$h{color}} // die "$file: unknown color type $h{color}\n";
	my $raw = uncompress($idat) // die "$file: bad image data\n";
	my $stride = $h{w} * $bpp;
	my ($prev, @pixels) = ("\0" x $stride);
	for my $y (0 .. $h{h} - 1) {
		my $filter = ord substr($raw, $y * ($stride + 1), 1);
		my @line = unpack('C*', substr($raw, $y * ($stride + 1) + 1, $stride));
		my @up = unpack('C*', $prev);
		for my $i (0 .. $#line) {
			my $a = $i >= $bpp ? $line[$i - $bpp] : 0;
			my $b = $up[$i];
			my $c = $i >= $bpp ? $up[$i - $bpp] : 0;
			my $add = $filter == 1 ? $a : $filter == 2 ? $b : $filter == 3 ? int(($a + $b) / 2)
				: $filter == 4 ? do { my $p = $a + $b - $c; my ($pa, $pb, $pc) = (abs($p - $a), abs($p - $b), abs($p - $c));
					$pa <= $pb && $pa <= $pc ? $a : $pb <= $pc ? $b : $c } : 0;
			$line[$i] = ($line[$i] + $add) & 0xff;
		}
		$prev = pack('C*', @line);
		for my $x (0 .. $h{w} - 1) {
			my @v = @line[$x * $bpp .. $x * $bpp + $bpp - 1];
			my @rgba = $h{color} == 6 ? @v : $h{color} == 2 ? (@v, 255) : $h{color} == 4 ? ($v[0], $v[0], $v[0], $v[1])
				: $h{color} == 0 ? ($v[0], $v[0], $v[0], 255)
				: (unpack('C3', substr($plte, $v[0] * 3, 3)), defined $trns && $v[0] < length $trns ? ord(substr($trns, $v[0], 1)) : 255);
			push @pixels, \@rgba;
		}
	}
	return ($h{w}, $h{h}, \@pixels);
}

# Box filter down to fit SIZE x SIZE, aspect kept (never scaled up).
sub fit {
	my ($w, $h, $px) = @_;
	my $scale = $w > $SIZE || $h > $SIZE ? ($w > $h ? $SIZE / $w : $SIZE / $h) : 1;
	my ($nw, $nh) = (int($w * $scale + 0.5) || 1, int($h * $scale + 0.5) || 1);
	return ($w, $h, $px) if $scale == 1;
	my @out;
	for my $y (0 .. $nh - 1) {
		for my $x (0 .. $nw - 1) {
			my ($x0, $x1, $y0, $y1) = (int($x / $scale), int(($x + 1) / $scale) - 1, int($y / $scale), int(($y + 1) / $scale) - 1);
			$x1 = $x0 if $x1 < $x0;
			$y1 = $y0 if $y1 < $y0;
			my @sum = (0, 0, 0, 0);
			my ($n, $wsum) = (0, 0);
			for my $sy ($y0 .. $y1) {
				for my $sx ($x0 .. $x1) {
					my $p = $px->[$sy * $w + $sx];
					my $alpha = $p->[3] / 255;
					$sum[$_] += $p->[$_] * $alpha for 0 .. 2;
					$sum[3] += $p->[3];
					$wsum += $alpha;
					$n++;
				}
			}
			push @out, [map({ $wsum > 0 ? int($sum[$_] / $wsum + 0.5) : 0 } 0 .. 2), int($sum[3] / $n + 0.5)];
		}
	}
	return ($nw, $nh, \@out);
}

# Median cut over the opaque pixels: at most 127 colors (index 0 transparent, 128-254 the darker
# copies for the pressed frame).
sub palette {
	my ($px) = @_;
	my @boxes = ([grep { $_->[3] >= 128 } @$px]);
	return ([], {}) unless @{$boxes[0]};
	while (@boxes < 127) {
		my ($best, $bestRange, $bestChannel) = (-1, 0, 0);
		for my $i (0 .. $#boxes) {
			next if @{$boxes[$i]} < 2;
			for my $ch (0 .. 2) {
				my @v = map { $_->[$ch] } @{$boxes[$i]};
				my ($lo, $hi) = (255, 0);
				for (@v) { $lo = $_ if $_ < $lo; $hi = $_ if $_ > $hi; }
				($best, $bestRange, $bestChannel) = ($i, $hi - $lo, $ch) if $hi - $lo > $bestRange;
			}
		}
		last if $best < 0 || $bestRange == 0;
		my @sorted = sort { $a->[$bestChannel] <=> $b->[$bestChannel] } @{$boxes[$best]};
		my $mid = int(@sorted / 2);
		splice @boxes, $best, 1, [@sorted[0 .. $mid - 1]], [@sorted[$mid .. $#sorted]];
	}
	my (@colors, %index);
	for my $i (0 .. $#boxes) {
		my @avg = map { my $ch = $_; my $s = 0; $s += $_->[$ch] for @{$boxes[$i]}; int($s / @{$boxes[$i]} + 0.5) } 0 .. 2;
		push @colors, \@avg;
		$index{"$_"} = $i + 1 for @{$boxes[$i]};
	}
	return (\@colors, \%index);
}

sub writeBam {
	my ($file, $w, $h, $px) = @_;
	my ($colors, $index) = palette($px);
	# Palette: 0 transparent (BG's green), then the icon's colors, then the same colors darker for
	# the pressed frame where there is room (otherwise the pressed frame reuses the normal colors).
	my @pal = ([0, 255, 0]);
	push @pal, @$colors;
	my $dark = @pal + @$colors <= 256;
	push @pal, map { [map { int($_ * 0.7) } @$_] } @$colors if $dark;
	push @pal, [0, 0, 0] while @pal < 256;
	my $frame = join '', map { $_->[3] >= 128 ? chr($index->{"$_"}) : "\0" } @$px;
	my $pressed = $dark ? join('', map { my $c = ord; $c ? chr($c + @$colors) : "\0" } split //, $frame) : $frame;
	# Spell icons: the icon and a pressed frame, a cycle each. Portrait icons: one frame.
	my $frames = $PORTRAIT ? 1 : 2;
	my $hdr = 0x18;
	my $frameOff = $hdr;
	my $cycleOff = $frameOff + $frames * 12;
	my $palOff = $cycleOff + $frames * 4;
	my $lookOff = $palOff + 1024;
	my $dataOff = $lookOff + $frames * 2;
	my $bam = 'BAM V1  ' . pack('vCCVVV', $frames, $frames, 0, $frameOff, $palOff, $lookOff);
	$bam .= pack('vvvvV', $w, $h, 0, 0, 0x80000000 | $dataOff);
	$bam .= pack('vvvvV', $w, $h, 0, 0, 0x80000000 | ($dataOff + length $frame)) if $frames == 2;
	$bam .= join '', map { pack('vv', 1, $_) } 0 .. $frames - 1;
	$bam .= join '', map { pack('CCCC', $_->[2], $_->[1], $_->[0], 0) } @pal;
	$bam .= pack('v*', 0 .. $frames - 1);
	$bam .= $frames == 2 ? $frame . $pressed : $frame;
	open my $fh, '>:raw', $file or die "$file: $!\n";
	print $fh $bam;
	close $fh;
	printf "%s: %dx%d, %d colors\n", $file, $w, $h, scalar @$colors;
}

# As a library (tools/stone-icons.pl), only the functions above.
return 1 if caller;

die "usage: perl tools/png2bam.pl IN.png OUT.bam | IN_DIR OUT_DIR\n" unless @ARGV == 2;
my ($in, $out) = @ARGV;
if (-d $in) {
	mkdir $out unless -d $out;
	opendir(my $dh, $in) or die "$in: $!\n";
	for my $f (sort grep { /\.png$/i } readdir $dh) {
		(my $res = uc $f) =~ s/\.PNG$//;
		die "$f: resref $res is longer than 8 characters\n" if length $res > 8;
		writeBam("$out/$res.bam", fit(readPng("$in/$f")));
	}
} else {
	writeBam($out, fit(readPng($in)));
}

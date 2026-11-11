#!/usr/bin/perl
# BG 2024 Rules Mod: copies of the companions for the Companions test mode, without dialogue and
# scripts (some companions start talking the moment they appear). Writes override/B24TCnn.cre for
# each companion of tools/ingame/companions.txt (the script name stays, so the conversion still
# sees a companion) and prints "copy original" per line.
# Usage: perl companion-copies.pl <game dir> <BGEE|BG2EE>
use strict;
use warnings;

my ($dir, $game) = @ARGV;
die "usage: companion-copies.pl <game dir> <game>\n" unless $dir && $game;
# Windows or POSIX paths (Git for Windows' perl gets both).
$dir =~ tr{\\}{/};
(my $here = __FILE__) =~ tr{\\}{/};
$here = $here =~ m{/} ? ($here =~ s{/[^/]*$}{}r) : '.';

my @list;
open my $l, '<', "$here/companions.txt" or die "companions.txt: $!";
while (<$l>) {
	s/\r?\n$//;
	next if /^\s*(#|$)/;
	my ($g, $names) = split /:\s*/, $_, 2;
	@list = split ' ', $names if $g eq $game;
}
close $l;

open my $f, '<:raw', "$dir/chitin.key" or die "$dir/chitin.key: $!";
my $key = do { local $/; <$f> };
my ($nb, $nr, $ob, $or) = unpack('x8 V V V V', $key);
my @biffs;
for my $i (0 .. $nb - 1) {
	my ($len, $noff, $nlen) = unpack('V V v', substr($key, $ob + $i * 12, 10));
	my $name = unpack('Z*', substr($key, $noff, $nlen));
	$name =~ tr{\\}{/};
	push @biffs, $name;
}
my %loc;
for my $i (0 .. $nr - 1) {
	my ($name, $type, $loc) = unpack('Z8 v V', substr($key, $or + $i * 14, 14));
	$loc{uc $name} = $loc if $type == 0x3f1;
}

sub creature {
	my ($name) = @_;
	for my $path ("$dir/override/$name.cre", "$dir/override/" . lc($name) . '.cre') {
		if (-f $path) { open my $o, '<:raw', $path or next; return do { local $/; <$o> }; }
	}
	my $loc = $loc{uc $name};
	return undef unless defined $loc;
	my ($bi, $fi) = ($loc >> 20, $loc & 0x3fff);
	open my $b, '<:raw', "$dir/$biffs[$bi]" or return undef;
	my $bd = do { local $/; <$b> };
	my ($nf, $nt, $fo) = unpack('x8 V V V', $bd);
	for my $j (0 .. $nf - 1) {
		my ($loc2, $off, $size) = unpack('V V V', substr($bd, $fo + $j * 16, 12));
		return substr($bd, $off, $size) if ($loc2 & 0x3fff) == $fi;
	}
	return undef;
}

my $n = 0;
for my $name (@list) {
	my $d = creature($name);
	next unless defined $d && substr($d, 0, 8) eq 'CRE V1.0';
	$n++;
	my $copy = sprintf 'B24TC%02d', $n;
	# Scripts: override, class, race, general, default (0x248-0x26f); dialogue (0x2cc).
	substr($d, 0x248, 40) = "\0" x 40;
	substr($d, 0x2cc, 8) = "\0" x 8;
	open my $out, '>:raw', "$dir/override/$copy.cre" or die "$copy.cre: $!";
	print $out $d;
	close $out;
	print "$copy $name\n";
}

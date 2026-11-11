#!/usr/bin/perl
# Structural Lua check for the mod's scripts (no Lua interpreter on the build machine):
# tokenizes strings and comments, then checks that blocks (function/if/for/while/do/repeat
# against end/until) and brackets balance. Also reports calls that run at load time (outside any
# function) to a function the same file only defines further down. Usage: perl tools/luacheck.pl lua/*.lua
use strict;
use warnings;

my $failed = 0;
for my $file (@ARGV) {
	open(my $fh, '<', $file) or die "$file: $!";
	local $/;
	my $src = <$fh>;
	close $fh;
	my @stack;     # [kind, line]
	my $line = 1;
	my $pendingLoop = 0;  # a for/while waiting for its "do"
	my $errors = 0;
	my (%defined, @loadCalls);   # name -> line of "function name"; [name, line] called at load time
	my $report = sub { print "$file:$_[0]: $_[1]\n"; $errors++; };
	pos($src) = 0;
	while (pos($src) < length($src)) {
		if ($src =~ /\G--\[(=*)\[/gc) {              # long comment
			my $eq = $1;
			my $start = $line;
			if ($src =~ /\G(.*?)\]$eq\]/gcs) { $line += ($1 =~ tr/\n//); }
			else { $report->($start, "unterminated long comment"); last; }
		} elsif ($src =~ /\G--[^\n]*/gc) {           # line comment
		} elsif ($src =~ /\G\[(=*)\[/gc) {            # long string
			my $eq = $1;
			my $start = $line;
			if ($src =~ /\G(.*?)\]$eq\]/gcs) { $line += ($1 =~ tr/\n//); }
			else { $report->($start, "unterminated long string"); last; }
		} elsif ($src =~ /\G(["'])/gc) {               # quoted string
			my $q = $1;
			my $start = $line;
			if ($src =~ /\G((?:\\.|[^\\\n])*?)$q/gc) { }
			else { $report->($start, "unterminated string"); $src =~ /\G[^\n]*/gc; }
		} elsif ($src =~ /\G\n/gc) {
			$line++;
		} elsif ($src =~ /\G([A-Za-z_][A-Za-z0-9_]*)/gc) {
			my $word = $1;
			if ($word ne 'function' && $src =~ /\G((?:\.[A-Za-z_][A-Za-z0-9_]*)+)\s*\(/gc) {
				my $name = $word . $1;
				push @loadCalls, [$name, $line] unless grep { $_->[0] eq 'function' } @stack;
				push @stack, ['(', $line];
				next;
			}
			if ($word eq 'function' && $src =~ /\G\s+([A-Za-z_][A-Za-z0-9_.]*)/) { $defined{$1} //= $line; }
			if ($word eq 'function' || $word eq 'if' || $word eq 'repeat') {
				push @stack, [$word, $line];
			} elsif ($word eq 'for' || $word eq 'while') {
				push @stack, [$word, $line];
				$pendingLoop++;
			} elsif ($word eq 'do') {
				if ($pendingLoop > 0) { $pendingLoop--; } else { push @stack, ['do', $line]; }
			} elsif ($word eq 'end') {
				my $top = pop @stack;
				if (!$top) { $report->($line, "'end' without an open block"); }
				elsif ($top->[0] eq 'repeat') { $report->($line, "'end' closes 'repeat' from line $top->[1]"); }
				elsif ($top->[0] eq '(' || $top->[0] eq '{' || $top->[0] eq '[') { $report->($line, "'end' inside '$top->[0]' from line $top->[1]"); }
			} elsif ($word eq 'until') {
				my $top = pop @stack;
				if (!$top || $top->[0] ne 'repeat') { $report->($line, "'until' without 'repeat'"); }
			} elsif ($word eq 'elseif' || $word eq 'else' || $word eq 'then') {
				my $top = $stack[-1];
				if (!$top || $top->[0] ne 'if') { $report->($line, "'$word' outside an 'if' block"); }
			}
		} elsif ($src =~ /\G([\(\{\[])/gc) {
			push @stack, [$1, $line];
		} elsif ($src =~ /\G([\)\}\]])/gc) {
			my $close = $1;
			my %open = (')' => '(', '}' => '{', ']' => '[');
			my $top = pop @stack;
			if (!$top || $top->[0] ne $open{$close}) {
				$report->($line, "'$close' does not match " . ($top ? "'$top->[0]' from line $top->[1]" : "anything"));
			}
		} else {
			$src =~ /\G./gcs;
		}
	}
	for my $open (@stack) { $report->($open->[1], "'$open->[0]' is never closed"); }
	for my $call (@loadCalls) {
		my ($name, $at) = @$call;
		$report->($at, "$name is called at load time but only defined at line $defined{$name}")
			if defined $defined{$name} && $defined{$name} > $at;
	}
	$failed++ if $errors;
	print "$file: ok\n" unless $errors;
}
exit($failed ? 1 : 0);

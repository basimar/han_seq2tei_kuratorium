#!usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';
use Encode qw(encode decode);
my $enc = 'utf-8';

# Data::Dumper für Debugging
use Data::Dumper;

die "Argumente: $0 tei-xml file | outputpath  \n" unless @ARGV == 2;

# Unicode-Support innerhalb des Perl-Skripts / für Output
use utf8;
binmode STDOUT, ":utf8";

my $teifile = $ARGV[0] or die "Need to get tei file on the command line\n";

my $buffer;
my $signature;
my $sigpos;
my $i = 1;

my $outputpath = $ARGV[1];

open(my $teidata, '<', $teifile) or die "Could not open '$teifile' $!\n";
while (my $line = <$teidata>) {

    $buffer .= $line;
    
    if (($line =~ /<\/idno$/) && $sigpos) {
        $signature = $line;
	$signature =~ s/^>//g;
	$signature =~ s/<\/idno$//g;
	$signature =~ s/\s:\s/_/g;
	$signature =~ s/:/_/g;
	$signature =~ s/,/_/g;
	$signature =~ s/\s/_/g;
	$signature =~ s/\//_/g;
	$signature =~ s/-/_/g;
	$signature =~ s/__$//g;
	$signature =~ s/_$//g;

	$sigpos = 0;
    }

    if ($line =~ /^><idno$/) { 
        $sigpos = 1;
    }



    if ($line =~ /^>$/) {
        my $exportfile = "$outputpath/$signature.xml";             
        open(my $export, '>', $exportfile) or die "Could not open file '$exportfile' $!";
	print $export $buffer;
	print "File splitted: $exportfile\n";
	$buffer = "";
	$i++; 
    } 

}


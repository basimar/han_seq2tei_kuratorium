#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';

# Data::Dumper for debugging
use Data::Dumper;

# XML::Writer to write output file
use XML::Writer;
use IO::File;

# Unicode-support in the Perl script and for output
use utf8;
binmode STDOUT, ":utf8";

# Min Max functions
use List::Util qw(min max);

# Catmandu-Module for importin Aleph sequential
use Catmandu::Importer::MARC::ALEPHSEQ;

# Information about output file (tei-xml)
my $output = IO::File->new(">$ARGV[1]");

#my $xlink     = "http://www.w3.org/1999/xlink";
my $xmlns     = "http://www.tei-c.org/ns/1.0";
#my $xsi       = "http://www.w3.org/2001/XMLSchema-instance";
#my $xsischema = "urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd";
my $writer = XML::Writer->new(
    OUTPUT     => $output,
    NEWLINES   => 1,
    ENCODING   => "utf-8",
    NAMESPACES => 1,
    PREFIX_MAP => {

        # $xlink     => 'xlink',
        # $xsi       => 'xsi',
        # $xsischema => 'xsi:schemaLocation',
        $xmlns => ''
    }
);

# Check arguments
die "Argumente: $0 Input-Dokument (alephseq), Output Dokument\n"
  unless @ARGV == 2;

# Hash with concordance 852$n and country name
my %country = (
    "AT" => "Österreich",
    "CH" => "Schweiz",
    "DE" => "Deutschland",
    "DK" => "Dänemark",
    "EE" => "Estland",
    "FI" => "Finnland",
    "FR" => "Frankreich",
    "GB" => "Grossbritannien",
    "IT" => "Italien",
    "KB" => "Italien",
    "NL" => "Niedernlande",
    "RU" => "Russland",
    "SE" => "Schweden",
    "US" => "Vereinigte Staaten von Amerika"

);

# Hash with concordance 852$a and place name
my %place = (
    "Basel UB"                                    => "Basel",
    "Basel UB Wirtschaft - SWA"                   => "Basel",
    "Bern Gosteli-Archiv"                         => "Bern",
    "Bern UB Schweizerische Osteuropabibliothek"  => "Bern",
    "Bern UB Archives REBUS"                      => "Bern",
    "Bern UB Medizingeschichte: Rorschach-Archiv" => "Bern",
    "KB Appenzell Ausserrhoden"                   => "Trogen",
    "KB Thurgau"                                  => "Frauenfeld",
    "Luzern ZHB"                                  => "Luzern",
    "ZB Solothurn"                                => "Solothurn",
    "St. Gallen KB Vadiana"                       => "St. Gallen",
    "St. Gallen Stiftsbibliothek"                 => "St. Gallen",
);

# Array with relator codes which will be used for the tei export
my @relator = [
    "Annotator",        "Auftraggeber",
    "Buchbinder",       "Drucker",
    "Illustrator",      "Mitwirkender",
    "Papierhersteller", "Schreiber",
    "Übersetzer",       "Widmungsverfasser",
    "Zweifelhafter Autor",
];

my $formerowner  = 'Früherer Eigentümer';
my $author       = 'Autor';

# Hash with concordance MARC21 language codes and written language name
my %language = (
    afr => 'Afrikaans',
    alb => 'Albanisch',
    chu => 'Altbulgarisch, Kirchenslawisch',
    grc => 'Altgriechisch',
    san => 'Sanskrit',
    eng => 'Englisch',
    ara => 'Arabisch',
    arc => 'Aramäisch',
    arm => 'Armenisch',
    aze => 'Azeri',
    gez => 'Äthiopisch',
    baq => 'Baskisch',
    bel => 'Weissrussisch',
    ben => 'Bengali',
    bur => 'Burmesisch',
    cze => 'Tschechisch',
    bos => 'Bosnisch',
    bul => 'Bulgarisch',
    roh => 'Rätoromanisch',
    spa => 'Spanisch',
    chi => 'Chinesisch',
    dan => 'Dänisch',
    egy => 'Ägyptisch',
    ger => 'Deutsch',
    gsw => 'Schweizerdeutsch',
    gla => 'Gälisch',
    est => 'Estnisch',
    fin => 'Finnisch',
    dut => 'Niederländisch',
    fre => 'Französisch',
    gle => 'Gälisch',
    geo => 'Georgisch',
    gre => 'Neugriechisch',
    heb => 'Hebräisch',
    hin => 'Hindi',
    ind => 'Indonesisch',
    ice => 'Isländisch',
    ita => 'Italienisch',
    jpn => 'Japanisch',
    yid => 'Jiddisch',
    khm => 'Khmer',
    kaz => 'Kasachisch',
    kas => 'Kashmiri',
    kir => 'Kirisisch',
    swa => 'Swahili',
    ukr => 'Ukrainisch',
    cop => 'Koptisch',
    kor => 'Koreanisch',
    hrv => 'Kroatisch',
    kur => 'Kurdisch',
    lat => 'Lateinisch',
    lav => 'Lettisch',
    lit => 'Litauisch',
    hun => 'Ungarisch',
    mac => 'Mazedonisch',
    may => 'Malaiisch',
    rum => 'Rumänisch',
    mon => 'Mongolisch',
    per => 'Persisch',
    nor => 'Norwegisch',
    pol => 'Polnisch',
    por => 'Portugiesisch',
    rus => 'Russisch',
    swe => 'Schwedisch',
    srp => 'Serbisch',
    slo => 'Slowakisch',
    slv => 'Slowenisch',
    wen => 'Sorbisch',
    syr => 'Syrisch',
    tgk => 'Tadschikisch',
    tgl => 'Philippinisch',
    tam => 'Tamil',
    tha => 'Siamesisch',
    tur => 'Türkisch',
    tuk => 'Turkmenisch',
    urd => 'Urdu',
    uzb => 'Usbekisch',
    vie => 'Vietnamisch',
    rom => 'Romani'
);

# Sysnum-Array contains all the system numbers of all MARC records
my @sysnum;

# Hashes to store data form the bibliographic records

my (
    %date008,   %date008_hum,  %f046,    %f046_hum, %f130,
    %f245,      %f246,         %f250,    %f254,     %f260a,
    %f260c,     %f300a,        %f300c,   %f340,     %f500,
    %f500CA,    %f500CB,       %f500CC,  %f500La,   %f500Lb,
    %f500L3,    %f500DAa,      %f500DA3, %f500DBa,  %f500DB3,
    %f500DCa,   %f500DC3,      %f500Za,  %f500Z3,   %f505,
    %f505n,     %f505r,        %f505t,   %f505i,    %f505v,
    %f505s,     %f506,         %f510,    %f520,     %f525,
    %f533,      %f5420,        %f544,    %f545,     %f546,
    %f555,      %f561,         %f563,    %f581,     %f583,
    %f583b,     %f655,         %f700,    %f700a,    %f7001,
    %f700e,     %f700t,        %f710,    %f710a,    %f7101,
    %f710e,     %f711,         %f711a,   %f7111,    %f711j,
    %f730,      %f751a,        %f7511,   %f852A,    %f852E,
    %f852a,     %f852a_place,  %f852b,   %f852p,    %f852n,
    %f852Aa,    %f852Aa_place, %f852Ab,  %f852An,   %f852Ap,
    %f852Ea,    %f852Ea_place, %f852Eb,  %f852En,   %f852Ep,
    %f8561u,    %f8561z,       %f8562u,  %f8562z,   %f909,
    %languages, %langcodes,    %otherlang,
);

# Catmandu importer to read each MARC record and export the information needed to generate the xml file
my $importer = Catmandu::Importer::MARC::ALEPHSEQ->new( file => $ARGV[0] );
$importer->each(
    sub {
        my $data        = $_[0];
        my $sysnum      = $data->{'_id'};
        my $f008        = marc_map( $data, '008' );
        my $language008 = substr( $f008, 35, 3 );
        my $date0081    = substr( $f008, 7, 4 );
        my $date0082    = substr( $f008, 11, 4 );
        my $f041        = marc_map( $data, '041a' );
        my @f046a       = marc_map( $data, '046a' );
        my @f046b       = marc_map( $data, '046b' );
        my @f046c       = marc_map( $data, '046c' );
        my @f046d       = marc_map( $data, '046d' );
        my @f046e       = marc_map( $data, '046e' );
        my $f100a       = marc_map( $data, '100a' );
        my $f100b       = marc_map( $data, '100b' );
        $f100a = marc_map( $data, '110a' ) unless hasvalue($f100a);
        $f100b = marc_map( $data, '110b' ) unless hasvalue($f100b);
        my $f130    = marc_map( $data, '130a' );
        my $f245a   = marc_map( $data, '245a' );
        my $f245b   = marc_map( $data, '245b', '-join', ', ' );
        my @f246a   = marc_map( $data, '246a' );
        my @f246n   = marc_map( $data, '246n', '-join', ', ' );
        my @f246p   = marc_map( $data, '246p', '-join', ', ' );
        my $f250    = marc_map( $data, '250a' );
        my @f254    = marc_map( $data, '254a' );
        my $f260a   = marc_map( $data, '260a' );
        my $f260c   = marc_map( $data, '260c' );
        my $f300a   = marc_map( $data, '300a', '-join', ', ' );
        my $f300c   = marc_map( $data, '300c', '-join', ', ' );
        my $f300e   = marc_map( $data, '300e' );
        my @f340    = marc_map( $data, '340a', '-join', ', ' );
        my @f500    = marc_map( $data, '500[  ]a' );
        my @f500CA  = marc_map( $data, '500[CA]a' );
        my @f500CB  = marc_map( $data, '500[CB]a' );
        my @f500CC  = marc_map( $data, '500[CC]a' );
        my @f500DAa = marc_map( $data, '500[DA]a' );
        my @f500DA3 = marc_map( $data, '500[DA]3' );
        my @f500DBa = marc_map( $data, '500[DB]a' );
        my @f500DB3 = marc_map( $data, '500[DB]3' );
        my @f500DCa = marc_map( $data, '500[DC]a' );
        my @f500DC3 = marc_map( $data, '500[DC]3' );
        my @f500La  = marc_map( $data, '500[L ]a' );
        my @f500Lb  = marc_map( $data, '500[L ]b' );
        my @f500L3  = marc_map( $data, '500[L ]3' );
        my @f500Za  = marc_map( $data, '500[Z ]a' );
        my @f500Z3  = marc_map( $data, '500[Z ]3' );
        my @f505    = marc_map( $data, '505' );
        my @f505n   = marc_map( $data, '505n' );
        my @f505g   = marc_map( $data, '505g' );
        my @f505r   = marc_map( $data, '505r' );
        my @f505t   = marc_map( $data, '505t' );
        my @f505i   = marc_map( $data, '505i' );
        my @f505s   = marc_map( $data, '505s' );
        my @f505v   = marc_map( $data, '505v', '-join', ', ' );
        my @f506a   = marc_map( $data, '506a' );
        my @f506c   = marc_map( $data, '506c' );
        my @f510a   = marc_map( $data, '510a' );
        my @f510i   = marc_map( $data, '510i' );
        my @f520a   = marc_map( $data, '520a' );
        my @f520b   = marc_map( $data, '520b', '-join', ', ' );
        my @f5203   = marc_map( $data, '5203' );
        my @f525    = marc_map( $data, '525a' );
        my @f533a   = marc_map( $data, '533a' );
        my @f533b   = marc_map( $data, '533b' );
        my @f533c   = marc_map( $data, '533c' );
        my @f533d   = marc_map( $data, '533d' );
        my @f533n   = marc_map( $data, '533n' );
        my @f5420d  = marc_map( $data, '542[ 0]d' );
        my @f5420e  = marc_map( $data, '542[ 0]e' );
        my @f54201  = marc_map( $data, '542[ 0]1' );
        my @f544    = marc_map( $data, '544n' );
        my @f545a   = marc_map( $data, '545a' );
        my @f545b   = marc_map( $data, '545b', '-join', ', ' );
        my @f546    = marc_map( $data, '546a' );
        my @f555    = marc_map( $data, '555a' );
        my @f561    = marc_map( $data, '561a' );
        my @f563    = marc_map( $data, '563a' );
        my @f581i   = marc_map( $data, '581i' );
        my @f581a   = marc_map( $data, '581a' );
        my @f5813   = marc_map( $data, '5813', '-join', ', ' );
        my @f583b   = marc_map( $data, '583b' );
        my @f583i   = marc_map( $data, '583i' );
        my @f583c   = marc_map( $data, '583c' );
        my @f583f   = marc_map( $data, '583f' );
        my @f583k   = marc_map( $data, '583k' );
        my @f655    = marc_map( $data, '655a' );
        my @f700a   = marc_map( $data, '700a' );
        my @f700q   = marc_map( $data, '700q' );
        my @f700b   = marc_map( $data, '700b' );
        my @f700c   = marc_map( $data, '700c', '-join', ', ' );
        my @f700d   = marc_map( $data, '700d' );
        my @f700e   = marc_map( $data, '700e' );
        my @f700t   = marc_map( $data, '700t' );
        my @f700n   = marc_map( $data, '700n', '-join', ', ' );
        my @f700p   = marc_map( $data, '700p', '-join', ', ' );
        my @f700m   = marc_map( $data, '700m', '-join', ', ' );
        my @f700r   = marc_map( $data, '700r' );
        my @f700s   = marc_map( $data, '700s' );
        my @f700o   = marc_map( $data, '700o' );
        my @f700h   = marc_map( $data, '700h' );
        my @f7001   = marc_map( $data, '7001' );
        my @f710a   = marc_map( $data, '710a' );
        my @f710b   = marc_map( $data, '710b', '-join', ', ' );
        my @f7101   = marc_map( $data, '7101' );
        my @f710e   = marc_map( $data, '710e' );
        my @f711a   = marc_map( $data, '711a' );
        my @f711e   = marc_map( $data, '711e', '-join', ', ' );
        my @f7111   = marc_map( $data, '7111' );
        my @f711j   = marc_map( $data, '711j' );

#Fields 100, 110 and 111 are treated like 7##-fields and are therefore shifted into these arrays
        if ( marc_map( $data, '100' ) ne "" ) {
            unshift @f700a, marc_map( $data, '100a' );
            unshift @f700q, marc_map( $data, '100q' );
            unshift @f700b, marc_map( $data, '100b' );
            unshift @f700c, marc_map( $data, '100c', '-join', ', ' );
            unshift @f700d, marc_map( $data, '100d' );
            unshift @f700e, marc_map( $data, '100e' );
            unshift @f700t, undef;
            unshift @f700n, undef;
            unshift @f700p, undef;
            unshift @f700m, undef;
            unshift @f700r, undef;
            unshift @f700s, undef;
            unshift @f700o, undef;
            unshift @f700h, undef;
            unshift @f7001, marc_map( $data, '1001' );
        }

        if ( marc_map( $data, '110' ) ne "" ) {
            unshift @f710a, marc_map( $data, '110a' );
            unshift @f710b, marc_map( $data, '110b', '-join', ', ' );
            unshift @f710e, marc_map( $data, '110e' );
            unshift @f7101, marc_map( $data, '1101' );
        }

        if ( marc_map( $data, '111' ) ne "" ) {
            unshift @f711a, marc_map( $data, '111a' );
            unshift @f711e, marc_map( $data, '111e', '-join', ', ' );
            unshift @f7111, marc_map( $data, '1111' );
            unshift @f711j, marc_map( $data, '111j' );
        }

        my @f730   = marc_map( $data, '730a' );
        my @f751a  = marc_map( $data, '751a' );
        my @f7511  = marc_map( $data, '7511' );
        my $f852a  = marc_map( $data, '852[  ]a' );
        my $f852b  = marc_map( $data, '852[  ]b' );
        my $f852n  = marc_map( $data, '852[  ]n' );
        my $f852p  = marc_map( $data, '852[  ]p' );
        my @f852A  = marc_map( $data, '852[A ]' );
        my @f852Aa = marc_map( $data, '852[A ]a' );
        my @f852Ab = marc_map( $data, '852[A ]b' );
        my @f852An = marc_map( $data, '852[A ]n' );
        my @f852Ap = marc_map( $data, '852[A ]p' );
        my @f852E  = marc_map( $data, '852[E ]' );
        my @f852Ea = marc_map( $data, '852[E ]a' );
        my @f852Eb = marc_map( $data, '852[E ]b' );
        my @f852En = marc_map( $data, '852[E ]n' );
        my @f852Ep = marc_map( $data, '852[E ]p' );
        my @f8561u = marc_map( $data, '856[ 1]u' );
        my @f8561z = marc_map( $data, '856[ 1]z' );
        my @f8562u = marc_map( $data, '856[ 2]u' );
        my @f8562z = marc_map( $data, '856[ 2]z' );
        my $f909   = marc_map( $data, '909f' );

        # If 008 date fields contain four "u" or "-", empty them
        if ( $date0081 eq '----' ) {
            $date0081 = '';
        }

        if ( $date0082 eq '----' ) {
            $date0082 = '';
        }

        if ( $date0081 eq 'uuuu' ) {
            $date0081 = '';
        }

        if ( $date0082 eq 'uuuu' ) {
            $date0082 = '';
        }

# Paste the two 008 date fields together, both as a normalized (/) and a human readable form (-)
        my $date008;
        my $date008_hum;
        if ( hasvalue($date0081) && hasvalue($date0082) ) {
            $date008     = $date0081 . "/" . $date0082;
            $date008_hum = $date0081 . "-" . $date0082;
        }
        else {
            $date008 = $date008_hum = $date0081;
        }

# Delete special characters from 046 fields and make a copy for the human-readable form
        my @f046b_hum;
        for (@f046b) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @f046b_hum, $_;
        }

        my @f046c_hum;
        for (@f046c) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @f046c_hum, $_;
        }

        my @f046d_hum;
        for (@f046d) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @f046d_hum, $_;
        }

        my @f046e_hum;
        for (@f046e) {
            s/\.//g;
            s/\[//g;
            s/\]//g;
            s/ //g;
            push @f046e_hum, $_;
        }

        my $f046_max = maxarray( \@f046a, \@f046b, \@f046c, \@f046d, \@f046e );

        my @f046_hum;
        my @f046;

# Modify 046 based on their length.
# The normalised version has the format YYYY, YYYY-MM or YYYYMMDD, with - as a prefix for BC dates
# The human readable version hat the format YYYY, MM.YYYY or DD.MM.YYYY with v as a prefix for BC dates
        for my $i ( 0 .. ($f046_max) - 1 ) {
            if ( length( $f046b[$i] ) == 6 ) {
                $f046b_hum[$i] = "v"
                  . substr( $f046b_hum[$i], 4, 2 ) . "."
                  . substr( $f046b_hum[$i], 0, 4 );
                $f046b[$i] = "-"
                  . substr( $f046b[$i], 0, 4 ) . "-"
                  . substr( $f046b[$i], 4, 2 );
            }
            elsif ( length( $f046b[$i] ) == 8 ) {
                $f046b_hum[$i] = "v"
                  . substr( $f046b_hum[$i], 6, 2 ) . "."
                  . substr( $f046b_hum[$i], 4, 2 ) . "."
                  . substr( $f046b_hum[$i], 0, 4 );
                $f046b[$i] = "-" . $f046b[$i];
            }
            elsif ( $f046b[$i] ) {
                $f046b_hum[$i] = "v" . $f046b_hum[$i];
                $f046b[$i]     = "-" . $f046b[$i];
            }

            if ( length( $f046c[$i] ) == 6 ) {
                $f046c_hum[$i] = substr( $f046c_hum[$i], 4, 2 ) . "."
                  . substr( $f046c_hum[$i], 0, 4 );
                $f046c[$i] =
                  substr( $f046c[$i], 0, 4 ) . "-" . substr( $f046c[$i], 4, 2 );
            }
            elsif ( length( $f046c[$i] ) == 8 ) {
                $f046c_hum[$i] =
                    substr( $f046c_hum[$i], 6, 2 ) . "."
                  . substr( $f046c_hum[$i], 4, 2 ) . "."
                  . substr( $f046c_hum[$i], 0, 4 );
            }

            if ( length( $f046d[$i] ) == 6 ) {
                $f046d_hum[$i] = "v"
                  . substr( $f046d_hum[$i], 4, 2 ) . "."
                  . substr( $f046d_hum[$i], 0, 4 );
                $f046d[$i] = "-"
                  . substr( $f046d[$i], 0, 4 ) . "-"
                  . substr( $f046d[$i], 4, 2 );
            }
            elsif ( length( $f046d[$i] ) == 8 ) {
                $f046d_hum[$i] = "v"
                  . substr( $f046d_hum[$i], 6, 2 ) . "."
                  . substr( $f046d_hum[$i], 4, 2 ) . "."
                  . substr( $f046d_hum[$i], 0, 4 );
                $f046d[$i] = "-" . $f046d[$i];
            }
            elsif ( $f046d[$i] ) {
                $f046d_hum[$i] = "v" . $f046d_hum[$i];
                $f046d[$i]     = "-" . $f046d[$i];
            }

            if ( length( $f046e[$i] ) == 6 ) {
                $f046e_hum[$i] = substr( $f046e_hum[$i], 4, 2 ) . "."
                  . substr( $f046e_hum[$i], 0, 4 );
                $f046e[$i] =
                  substr( $f046e[$i], 0, 4 ) . "-" . substr( $f046e[$i], 4, 2 );
            }
            elsif ( length( $f046e[$i] ) == 8 ) {
                $f046e_hum[$i] =
                    substr( $f046e[$i], 6, 2 ) . "."
                  . substr( $f046e_hum[$i], 4, 2 ) . "."
                  . substr( $f046e_hum[$i], 0, 4 );
            }

# If BC dates exist (fields 046$b and $d, replace the AC fields with the BC dates
            $f046c[$i] = $f046b[$i] unless $f046c[$i];
            $f046e[$i] = $f046d[$i] unless $f046e[$i];

            $f046c_hum[$i] = $f046b_hum[$i] unless $f046c_hum[$i];
            $f046e_hum[$i] = $f046d_hum[$i] unless $f046e_hum[$i];

            # Create a human readable date field from field 046
            my $newf046_hum;
            $newf046_hum = $f046c_hum[$i] . "-" . $f046e_hum[$i]
              unless $f046e_hum[$i] eq "";
            push @f046_hum, $newf046_hum;

            # Create a normalized date field from field 046
            my $newf046;
            $newf046 = $f046c[$i] . "/" . $f046e[$i] unless $f046e[$i] eq "";

# Check if normalized date field matches the ead date regex, if not insert empty date
            if ( $newf046 =~
/^(-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|-((01|02|03|04|05|06|07|08|09|10|11|12)(\-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)(\/-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|-((01|02|03|04|05|06|07|08|09|10|11|12)(-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)?$/
              )
            {
                push @f046, $newf046;
            }
            else {
                push @f046, "";
            }
        }

        # Split field 041 into separate language codes
        my @langcodes;
        my @f041 = $f041 =~ m/(...)/g;

        # Remove first language codes (not necessary, as it is also present in field 008
        shift @f041;
        
	    my $otherlang = join( " ", ( shift @f041 ) );

        # Push language code from field 008 into langcodes array
        push @langcodes, $language008 unless $language008 =~ /(zxx|und)/;

        # Create array languages with human readable language names
        my @languages;
        foreach my $lang (@langcodes) {
            foreach my $lang1 ( keys %language ) {
                if ( $lang1 eq $lang ) {
                    push @languages, $language{$lang1};
                }
            }
        }

        # Generate title-field from subfields
        my $f245 = $f100a;
        isbd( $f245, $f100b, " " );
        isbd( $f245, $f245a, " : " );
        isbd( $f245, $f245b, ", " );
        $f245 =~ s/^\s//g;
        $f245 =~ s/^\s:\s//g;
        $f245 =~ s/<<//g;
        $f245 =~ s/>>//g;

        # Generate alt-title from subfields
        my @f246;
        my $f246_max = maxarray( \@f246a, \@f246n, \@f246p );
        for my $i ( 0 .. ($f246_max) - 1 ) {
            isbd( $f246[$i], $f246a[$i] );
            isbd( $f246[$i], $f246n[$i], ". " );
            isbd( $f246[$i], $f246p[$i], ". " );
            $f246[$i] =~ s/^.\s//;
        }

        # Construct place field from 260$a and 751 (only use 751$a if not identical to 250$a)
        if ( @f751a > 0 ) {
            $f260a .= " [";
            foreach (@f751a) {
                $f260a .= $_ . ", ";
            }
            $f260a .= "]";
            $f260a =~ s/,\s]$/]/;
        }

        # Generate page Dimensions
        isbd( $f300c, $f300e, "+ " );
        $f300c =~ s/^\+\s//;

        # Generate content note from field 505 subfields
        my $f505_max = maxarray( \@f505n, \@f505g );
        for my $i ( 0 .. ($f505_max) - 1 ) {
            isbd( $f505n[$i], $f505g[$i], ": " );
            $f505n[$i] =~ s/^:\s//;
        }

        # Generate content note from field 520 subfields
        my @f520;
        my $f520_max = maxarray( \@f520a, \@f520b, \@f5203 );
        for my $i ( 0 .. ($f520_max) - 1 ) {
            isbd( $f520[$i], $f5203[$i], "", ": " );
            isbd( $f520[$i], $f520a[$i] );
            isbd( $f520[$i], $f520b[$i], ". " );
            $f520[$i] =~ s/^,\s//;
        }

        # Generate access restriction from field 506 subfields
        my @f506;
        my $f506_max = maxarray( \@f506a, \@f506c );
        for my $i ( 0 .. ($f506_max) - 1 ) {
            isbd( $f506[$i], $f506a[$i] );
            isbd( $f506[$i], $f506c[$i], ". " );
            $f506[$i] =~ s/^,\s//;
        }

        # Generate bibliography note from field 510 subfields
        my @f510;
        my $f510_max = maxarray( \@f510a, \@f510i );
        for my $i ( 0 .. ($f510_max) - 1 ) {
            isbd( $f510[$i], $f510i[$i], ": " );
            isbd( $f510[$i], $f510a[$i] );
            $f510[$i] =~ s/^:\s//;
        }

        # Generate access fields from field 542 subfields
        my @f533;
        my $f533_max = maxarray( \@f533a, \@f533b, \@f533c, \@f533d, \@f533n );
        for my $i ( 0 .. ($f533_max) - 1 ) {
            isbd( $f533[$i], $f533a[$i], "",         "." );
            isbd( $f533[$i], $f533b[$i], " ",        "." );
            isbd( $f533[$i], $f533c[$i], " ",        "." );
            isbd( $f533[$i], $f533d[$i], " Datum: ", "." );
            isbd( $f533[$i], $f533n[$i], " " );
            $f533[$i] =~ s/^,\s//;
        }

        # Generate access fields from field 542 subfields
        my @f5420;
        my $f5420_max = maxarray( \@f5420d, \@f5420e, \@f54201 );
        for my $i ( 0 .. ($f5420_max) - 1 ) {
            $f5420[$i] = $f5420d[$i];
            isbd( $f5420[$i], $f5420e[$i], ", " );
            isbd( $f5420[$i], $f54201[$i], " " );
            $f5420[$i] =~ s/^,\s//;
        }

        # Generate a biographical history fields from field 545 subfields
        my @f545;
        my $f545_max = maxarray( \@f545a, \@f545b );
        for my $i ( 0 .. ($f545_max) - 1 ) {
            $f545[$i] = $f545a[$i];
            isbd( $f545[$i], $f545b[$i], ". " );
        }

        # Generate an literature note from field 581 subfields
        my @f581;
        my $f581_max = maxarray( \@f581i, \@f581a, \@f5813 );
        for my $i ( 0 .. ($f581_max) - 1 ) {
            isbd( $f581[$i], $f581i[$i], "",         ": " );
            isbd( $f581[$i], $f581a[$i] );
            isbd( $f581[$i], $f5813[$i], " (betr. ", ")" );
            $f581[$i] =~ s/^,\s//;
        }

        # Generate custodial note from field 583 subfields
        my @f583;
        my $f583_max = maxarray( \@f583i, \@f583c, \@f583k, \@f583f );
        for my $i ( 0 .. ($f583_max) - 1 ) {
            $f583[$i] = $f583i[$i];
            isbd( $f583[$i], $f583c[$i], " / " );
            isbd( $f583[$i], $f583f[$i], " / " );
            isbd( $f583[$i], $f583k[$i], " / " );
            $f583[$i] =~ s/^\s\/\s//;
        }

        # Generate an author field from the 700 and 100 subfields
        for (@f7001) { s/\(DE-588\)//g }
        my @f700;
        my $f700_max = maxarray(
            \@f700a, \@f700q, \@f700b, \@f700c, \@f700d, \@f700t, \@f700n,
            \@f700p, \@f700m, \@f700r, \@f700s, \@f700o, \@f700h
        );
        for my $i ( 0 .. ($f700_max) - 1 ) {
            $f700[$i] = $f700a[$i];
            isbd( $f700[$i], $f700q[$i], " (", ")" );
            isbd( $f700[$i], $f700b[$i], " " );
            isbd( $f700[$i], $f700c[$i], ", " );
            isbd( $f700[$i], $f700d[$i], " (", ")" );
            isbd( $f700[$i], $f700t[$i], " -- " );
            isbd( $f700[$i], $f700n[$i], ". " );
            isbd( $f700[$i], $f700p[$i], ". " );
            isbd( $f700[$i], $f700m[$i], ". " );
            isbd( $f700[$i], $f700r[$i], ". " );
            isbd( $f700[$i], $f700s[$i], ". " );
            isbd( $f700[$i], $f700o[$i], ". " );
            isbd( $f700[$i], $f700h[$i], ". " );
            $f700[$i] =~ s/<<//g;
            $f700[$i] =~ s/>>//g;
        }

        # Generate an author field from the 710 and 110 subfields
        for (@f7101) { s/\(DE-588\)//g }
        my @f710;
        my $f710_max = maxarray( \@f710a, \@f710b );
        for my $i ( 0 .. ($f710_max) - 1 ) {
            $f710[$i] = $f710a[$i];
            isbd( $f710[$i], $f710b[$i], ". " );
            $f710[$i] =~ s/<<//g;
            $f710[$i] =~ s/>>//g;
        }

        # Generate an author field from the 711 and 111 subfields
        for (@f7111) { s/\(DE-588\)//g }
        my @f711;
        my $f711_max = maxarray( \@f711a, \@f711e );
        for my $i ( 0 .. ($f711_max) - 1 ) {
            $f711[$i] = $f711a[$i];
            isbd( $f711[$i], $f711e[$i], ". " );
            $f711[$i] =~ s/<<//g;
            $f711[$i] =~ s/>>//g;
        }

        # Prepare origination field from field 751
        for (@f7511) { s/\(DE-588\)//g }

        # Translate country codes from 852$n into country name
        for my $country ( keys %country ) {
            if ( $f852n =~ $country ) {
                $f852n = $country{$country};
            }
            for (@f852An) {
                if ( $_ =~ $country ) {
                    $_ = $country{$country};
                }
            }
            for (@f852En) {
                if ( $_ =~ $country ) {
                    $_ = $country{$country};
                }
            }
        }

        # Extract placenames from 852$a
        my $f852a_place;
        my @f852Aa_place;
        my @f852Ea_place;
        for my $place ( keys %place ) {
            if ( $f852a eq $place ) {
                $f852a_place = $place{$place};
            }
            foreach my $i ( 0 .. ( @f852Aa - 1 ) ) {
                if ( $_ eq $place ) {
                    $f852Aa_place[$i] = $place{$place};
                }
            }
            foreach my $i ( 0 .. ( @f852Ea - 1 ) ) {
                if ( $_ eq $place ) {
                    $f852Ea_place[$i] = $place{$place};
                }
            }
        }

# Some records don't have to be exported as ead (records with 909-code hide this and some library specific records)
        unless ( $f909 =~ /hide_this/ ) {

# If a record has to be exported, we read in its field (already manipulated) into hashes (key = sysnum)
            push( @sysnum, $sysnum );
            $date008{$sysnum}      = $date008;
            $date008_hum{$sysnum}  = $date008_hum;
            $f046{$sysnum}         = [@f046];
            $f046_hum{$sysnum}     = [@f046_hum];
            $f130{$sysnum}         = ($f130);
            $f245{$sysnum}         = ($f245);
            $f246{$sysnum}         = [@f246];
            $f250{$sysnum}         = $f250;
            $f254{$sysnum}         = [@f254];
            $f260a{$sysnum}        = $f260a;
            $f260c{$sysnum}        = $f260c;
            $f300a{$sysnum}        = $f300a;
            $f300c{$sysnum}        = $f300c;
            $f340{$sysnum}         = [@f340];
            $f500{$sysnum}         = [@f500];
            $f500CA{$sysnum}       = [@f500CA];
            $f500CB{$sysnum}       = [@f500CB];
            $f500CC{$sysnum}       = [@f500CC];
            $f500DAa{$sysnum}      = [@f500DAa];
            $f500DA3{$sysnum}      = [@f500DA3];
            $f500DBa{$sysnum}      = [@f500DBa];
            $f500DB3{$sysnum}      = [@f500DB3];
            $f500DCa{$sysnum}      = [@f500DCa];
            $f500DC3{$sysnum}      = [@f500DC3];
            $f500La{$sysnum}       = [@f500La];
            $f500Lb{$sysnum}       = [@f500Lb];
            $f500L3{$sysnum}       = [@f500L3];
            $f500Za{$sysnum}       = [@f500Za];
            $f500Z3{$sysnum}       = [@f500Z3];
            $f505{$sysnum}         = [@f505];
            $f505n{$sysnum}        = [@f505n];
            $f505r{$sysnum}        = [@f505r];
            $f505t{$sysnum}        = [@f505t];
            $f505i{$sysnum}        = [@f505i];
            $f505v{$sysnum}        = [@f505v];
            $f505s{$sysnum}        = [@f505s];
            $f506{$sysnum}         = [@f506];
            $f510{$sysnum}         = [@f510];
            $f520{$sysnum}         = [@f520];
            $f525{$sysnum}         = [@f525];
            $f533{$sysnum}         = [@f533];
            $f5420{$sysnum}        = [@f5420];
            $f544{$sysnum}         = [@f544];
            $f545{$sysnum}         = [@f545];
            $f546{$sysnum}         = [@f546];
            $f555{$sysnum}         = [@f555];
            $f561{$sysnum}         = [@f561];
            $f563{$sysnum}         = [@f563];
            $f581{$sysnum}         = [@f581];
            $f583{$sysnum}         = [@f583];
            $f583b{$sysnum}        = [@f583b];
            $f655{$sysnum}         = [@f655];
            $f700{$sysnum}         = [@f700];
            $f700a{$sysnum}        = [@f700a];
            $f7001{$sysnum}        = [@f7001];
            $f700e{$sysnum}        = [@f700e];
            $f710{$sysnum}         = [@f710];
            $f710a{$sysnum}        = [@f710a];
            $f7101{$sysnum}        = [@f7101];
            $f710e{$sysnum}        = [@f710e];
            $f711{$sysnum}         = [@f711];
            $f711a{$sysnum}        = [@f711a];
            $f7111{$sysnum}        = [@f7111];
            $f711j{$sysnum}        = [@f711j];
            $f730{$sysnum}         = [@f730];
            $f751a{$sysnum}        = [@f751a];
            $f7511{$sysnum}        = [@f7511];
            $f852A{$sysnum}        = [@f852A];
            $f852E{$sysnum}        = [@f852E];
            $f852a{$sysnum}        = $f852a;
            $f852a_place{$sysnum}  = $f852a_place;
            $f852b{$sysnum}        = $f852b;
            $f852p{$sysnum}        = $f852p;
            $f852n{$sysnum}        = $f852n;
            $f852Aa{$sysnum}       = [@f852Aa];
            $f852Aa_place{$sysnum} = [@f852Aa_place];
            $f852Ab{$sysnum}       = [@f852Ab];
            $f852An{$sysnum}       = [@f852An];
            $f852Ap{$sysnum}       = [@f852Ap];
            $f852Ea{$sysnum}       = [@f852Ea];
            $f852Ea_place{$sysnum} = [@f852Ea_place];
            $f852Eb{$sysnum}       = [@f852Eb];
            $f852En{$sysnum}       = [@f852En];
            $f852Ep{$sysnum}       = [@f852Ep];
            $f8561u{$sysnum}       = [@f8561u];
            $f8561z{$sysnum}       = [@f8561z];
            $f8562u{$sysnum}       = [@f8562u];
            $f8562z{$sysnum}       = [@f8562z];
            $f909{$sysnum}         = $f909;
            $languages{$sysnum}    = [@languages];
            $langcodes{$sysnum}    = [@langcodes];
            $otherlang{$sysnum}    = $otherlang;
        }
    }
);

#Now we're ready to being creating ead-files. First we select all records with level=Bestand and build up an ead-file
#containint their children records. Exception: The pseudo records for unlinked records.

foreach (@sysnum) {
    intro($_);
    tei($_);
    extro();
}

# Creates the beginning of an tei-file
sub intro {
    $writer->xmlDecl("UTF-8");

    $writer->startTag("TEI");

    $writer->startTag("teiHeader");
    $writer->startTag("fileDesc");
    $writer->startTag("sourceDesc");
    $writer->startTag("msDesc");
}

# Writes the end of an tei-file
sub extro {
    $writer->endTag("msDesc");
    $writer->endTag("sourceDesc");
    $writer->endTag("fileDesc");
    $writer->endTag("teiHeader");
    $writer->endTag("TEI");
    $writer->end();
}

# Writes the body of an ead-file
sub tei {

# The sub is executed with the system number of the records we're currently transforming
    my $sysnum = $_[0];

    $writer->startTag("msIdentifier");

    simpletag( $f852n{$sysnum},       "country" );
    simpletag( $f852a_place{$sysnum}, "settlement" );
    simpletag( $f852a{$sysnum},       "institution" );
    simpletag( $f852b{$sysnum},       "repository" );
    simpletag( $f852p{$sysnum},       "idno" );

    foreach my $i ( 0 .. ( @{ $f852A{$sysnum} } - 1 ) ) {
        if ( hasvalue( $f852A{$sysnum}[$i] ) ) {
            $writer->startTag( "altIdentifier", "type" => "former" );
            simpletag( $f852An{$sysnum}[$i],       "country" );
            simpletag( $f852Aa_place{$sysnum}[$i], "settlement" );
            simpletag( $f852Aa{$sysnum}[$i],       "institution" );
            simpletag( $f852Ab{$sysnum}[$i],       "repository" );
            simpletag( $f852Ap{$sysnum}[$i],       "idno" );
            $writer->endTag( "altIdentifier" );
        }
    }

    foreach my $i ( 0 .. ( @{ $f852E{$sysnum} } - 1 ) ) {
        if ( hasvalue( $f852E{$sysnum}[$i] ) ) {
            $writer->startTag( "altIdentifier", "type" => "alternative" );
            simpletag( $f852En{$sysnum}[$i],       "country" );
            simpletag( $f852Ea_place{$sysnum}[$i], "settlement" );
            simpletag( $f852Ea{$sysnum}[$i],       "institution" );
            simpletag( $f852Eb{$sysnum}[$i],       "repository" );
            simpletag( $f852Ep{$sysnum}[$i],       "idno" );
            $writer->endTag( "altIdentifier" );
        }
    }

    $writer->endTag("msIdentifier");

    $writer->startTag("head");
    simpletag( $f245{$sysnum},  "title" );
    simpletag( $f246{$sysnum},  "title" );
    simpletag( $f130{$sysnum},  "title" );
    simpletag( $f730{$sysnum},  "title" );
    simpletag( $f700t{$sysnum}, "title" );
    simpletag( $f655{$sysnum},  "title", "type", "supplied" );

    foreach my $i ( 0 .. ( @{ $f700{$sysnum} } - 1 ) ) {
        if ( $f700e{$sysnum}[$i] eq $author ) {
            simpletag( $f700{$sysnum}[$i], "author" );
        }
        elsif ( $f700e{$sysnum}[$i] ~~ @relator ) {
            $writer->startTag("respStmt");
            simpletag( $f700e{$sysnum}[$i], "resp" );
            simpletag( $f700{$sysnum}[$i],  "name" );
            $writer->endTag("respStmt");
        }
    }

    foreach my $i ( 0 .. ( @{ $f710{$sysnum} } - 1 ) ) {
        if ( $f710e{$sysnum}[$i] eq $author ) {
            simpletag( $f710{$sysnum}[$i], "author" );
        }
        elsif ( $f710e{$sysnum}[$i] ~~ @relator ) {
            $writer->startTag("respStmt");
            simpletag( $f710e{$sysnum}[$i], "resp" );
            simpletag( $f710{$sysnum}[$i],  "name" );
            $writer->endTag("respStmt");
        }
    }

    foreach my $i ( 0 .. ( @{ $f711{$sysnum} } - 1 ) ) {
        if ( $f711j{$sysnum}[$i] eq $author ) {
            simpletag( $f711{$sysnum}[$i], "author" );
        }
        elsif ( $f711j{$sysnum}[$i] ~~ @relator ) {
            $writer->startTag("respStmt");
            simpletag( $f711j{$sysnum}[$i], "resp" );
            simpletag( $f711{$sysnum}[$i],  "name" );
            $writer->endTag("respStmt");
        }
    }

    simpletag( $f260a{$sysnum}, "origPlace" );

# Generate unitdate element for dates
# For the attribute normal use field 046 (if only one field 046 is present) or field 008 (if multiple fields 046 are present).
    if ( hasvalue( $f046{$sysnum}[0] ) && @{ $f046{$sysnum} } == 1 ) {
        $writer->startTag( "origDate", "whenIso" => $f046{$sysnum}[0] );
    }
    elsif ( hasvalue( $date008{$sysnum} ) ) {
        $writer->startTag( "origDate", "whenIso" => $date008{$sysnum} );
    }
    else {
        $writer->startTag("origDate");
    }

# For the human readable date use field 260 (if present) else field 046 (if only one field 046 is present), else field 008

    if ( hasvalue( $f260c{$sysnum} ) ) {
        $writer->characters( $f260c{$sysnum} );
    }
    elsif ( hasvalue( $f046_hum{$sysnum}[0] )
        && @{ $f046_hum{$sysnum} } == 1 )
    {
        $writer->characters( $f046_hum{$sysnum}[0] );
    }
    elsif ( hasvalue( $date008_hum{$sysnum} ) ) {
        $writer->characters( $date008_hum{$sysnum} );
    }
    $writer->endTag("origDate");
    $writer->endTag("head");

    $writer->startTag("msContents");

    simpletag( $f520{$sysnum}, "summary" );

    $writer->startTag("summary");
    simpletag( $f500{$sysnum}, "note" );
    $writer->endTag("summary");

# Write langmaterial element for language information, both codes and human readable
    foreach my $i ( 0 .. ( @{ $f546{$sysnum} } - 1 ) ) {
        $writer->startTag(
            "textLang",
            "mainLang"  => $langcodes{$sysnum}[0],
            "otherLang" => $otherlang{$sysnum}
        );
        $writer->characters( $f546{$sysnum}[$i] );
        $writer->endTag("textLang");
    }

    foreach my $i ( 0 .. ( @{ $f505{$sysnum} } - 1 ) ) {
        $writer->startTag("msItem");
        simpletag( $f505{$sysnum}[$i], "locus" );
        simpletag( $f505r{$sysnum}[$i], "author" );
        simpletag( $f505t{$sysnum}[$i], "title" );
        simpletag( $f505i{$sysnum}[$i], "quote" );
        simpletag( $f505v{$sysnum}[$i], "bibl" );
        simpletag( $f505s{$sysnum}[$i], "note" );
        $writer->endTag("msItem");
    }

    $writer->endTag("msContents");

    $writer->startTag("physDesc");
    $writer->startTag("objectDesc");
    $writer->startTag("supportDesc");

    simpletag( $f500CA{$sysnum}, "support" );
    simpletag( $f340{$sysnum},   "support" );

    $writer->startTag("extent");
    simpletag( $f300a{$sysnum}, "measure", "type", "extent" );
    simpletag( $f300c{$sysnum}, "measure", "type", "pageDimensions" );
    $writer->endTag("extent");

    simpletag( $f500CC{$sysnum}, "foliation" );
    simpletag( $f500CB{$sysnum}, "collation" );

    $writer->endTag("supportDesc");

    $writer->startTag("layoutDesc");

    foreach my $i ( 0 .. ( @{ $f500La{$sysnum} } - 1 ) ) {
        $writer->startTag("layout");
        if ( hasvalue( $f500L3{$sysnum}[$i] ) ) {
            simpletag( $f500L3{$sysnum}[$i], "locus" );
        }
        $writer->characters( $f500La{$sysnum}[$i] );
        $writer->endTag("layout");
    }

    $writer->endTag("layoutDesc");
    $writer->endTag("objectDesc");

    if ( @{ $f500Lb{$sysnum} } > 0 ) {

        $writer->startTag("handDescr");
        $writer->startTag("handNote");

        foreach my $i ( 0 .. ( @{ $f500Lb{$sysnum} } - 1 ) ) {
            $writer->startTag("p");
            if ( hasvalue( $f500L3{$sysnum}[$i] ) ) {
                simpletag( $f500L3{$sysnum}[$i], "locus" );
            }
            $writer->characters( $f500Lb{$sysnum}[$i] );
            $writer->endTag("p");
        }

        $writer->endTag("handNote");
        $writer->endTag("handDescr");
    }

    $writer->startTag("decoDescr");

    foreach my $i ( 0 .. ( @{ $f500DAa{$sysnum} } - 1 ) ) {
        $writer->startTag( "decoNote", "type" => "rubric" );
        if ( hasvalue( $f500DA3{$sysnum}[$i] ) ) {
            simpletag( $f500DA3{$sysnum}[$i], "locus" );
        }
        $writer->characters( $f500DAa{$sysnum}[$i] );
        $writer->endTag("decoNote");
    }

    foreach my $i ( 0 .. ( @{ $f500DBa{$sysnum} } - 1 ) ) {
        $writer->startTag( "decoNote", "type" => "inital" );
        if ( hasvalue( $f500DB3{$sysnum}[$i] ) ) {
            simpletag( $f500DB3{$sysnum}[$i], "locus" );
        }
        $writer->characters( $f500DBa{$sysnum}[$i] );
        $writer->endTag("decoNote");
    }

    foreach my $i ( 0 .. ( @{ $f500DCa{$sysnum} } - 1 ) ) {
        $writer->startTag( "decoNote", "type" => "miniatures" );
        if ( hasvalue( $f500DC3{$sysnum}[$i] ) ) {
            simpletag( $f500DC3{$sysnum}[$i], "locus" );
        }
        $writer->characters( $f500DCa{$sysnum}[$i] );
        $writer->endTag("decoNote");
    }

    $writer->endTag("decoDescr");

    $writer->startTag("additions");

    foreach my $i ( 0 .. ( @{ $f500Za{$sysnum} } - 1 ) ) {
        $writer->startTag("p");
        if ( hasvalue( $f500Z3{$sysnum}[$i] ) ) {
            simpletag( $f500Z3{$sysnum}[$i], "locus" );
        }
        $writer->characters( $f500Za{$sysnum}[$i] );
        $writer->endTag("p");
    }

    $writer->endTag("additions");
    
    if ( @{ $f563{$sysnum} } > 0 ) {

        $writer->startTag("bindingDesc");
        $writer->startTag("binding");
        simpletag( $f563{$sysnum}, "p" );
        $writer->endTag("binding");
        $writer->endTag("bindingDesc");
    }

    $writer->startTag("accMat");
    simpletag( $f525{$sysnum}, "p" );
    $writer->endTag("accMat");

    $writer->endTag("physDesc");

    $writer->startTag("history");

    $writer->startTag("origins");
    simpletag( $f561{$sysnum}, "p" );
    $writer->endTag("origins");

    $writer->startTag("provenance");
    foreach my $i ( 0 .. ( @{ $f700{$sysnum} } - 1 ) ) {
        if ( $f700e{$sysnum}[$i] eq $formerowner ) {
            simpletag( $f700{$sysnum}[$i], "p" );
        }
    }
    foreach my $i ( 0 .. ( @{ $f710{$sysnum} } - 1 ) ) {
        if ( $f710e{$sysnum}[$i] eq $formerowner ) {
            simpletag( $f710{$sysnum}[$i], "p" );
        }
    }
    foreach my $i ( 0 .. ( @{ $f711{$sysnum} } - 1 ) ) {
        if ( $f711j{$sysnum}[$i] eq $formerowner ) {
            simpletag( $f711{$sysnum}[$i], "p" );
        }
    }
    $writer->endTag("provenance");

    $writer->endTag("history");

    $writer->startTag("additional");

    $writer->startTag("adminInfo");
    $writer->startTag("recordHist");

    $writer->startTag("source");
    $writer->startTag("bibl");
    $writer->characters( "Aus: HAN. Verbundkatalog Handschriften - Archive - Nachlässe");
    $writer->endTag("bibl");

    foreach my $i ( 0 .. ( @{ $f583{$sysnum} } - 1 ) ) {
	if ( $f583b{$sysnum}[$i] =~ /^Verzeichnung/ ) {
	    simpletag( $f583{$sysnum}[$i], "bibl" );
	}
    }

    $writer->endTag("source");
    $writer->endTag("recordHist");

    $writer->startTag("custodialHist");
    foreach my $i ( 0 .. ( @{ $f583{$sysnum} } - 1 ) ) {
	unless ( $f583b{$sysnum}[$i] =~ /^Verzeichnung/ ) {
	    simpletag( $f583{$sysnum}[$i], "custEvent" );
	}
    }
    $writer->endTag("custodialHist");

    simpletag( $f506{$sysnum},  "availability" );
    simpletag( $f5420{$sysnum}, "availability" );

    if ( @{ $f8561u{$sysnum} } > 0 ) {
        $writer->startTag("surrogates");
        foreach my $i (0 .. ( @{ $f8561u{$sysnum} } - 1 )) {
            $writer->startTag(
                "ref",
                "type"   => "crossRef",
                "target" => $f8561u{$sysnum}[$i]
            );
            $writer->characters( $f8561z{$sysnum}[$i] );
            $writer->endTag("ref");
        }
        $writer->endTag("surrogates");
    }
     
    simpletag( $f533{$sysnum}, "surrogates" );

    $writer->endTag("adminInfo");

    $writer->startTag("listBibl");

    simpletag_b( $f510{$sysnum}, "listBibl", "Bibliographische Nachweise" );
    simpletag_b( $f581{$sysnum}, "listBibl", "Literatur" );

    if ( @{ $f8562u{$sysnum} } > 0 ) {
        $writer->startTag("listBibl");
        $writer->startTag("head");
        $writer->characters("Online");
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $f8562u{$sysnum} } - 1 ) ) {
            $writer->startTag("bibl");
            $writer->startTag(
                "ref",
                "type"   => "crossRef",
                "target" => $f8562u{$sysnum}[$i]
            );
            $writer->characters( $f8562z{$sysnum}[$i] );
            $writer->endTag("ref");
            $writer->endTag("bibl");
        }
        $writer->endTag("listBibl");
    }
    $writer->endTag("listBibl");
    $writer->endTag("additional");
}



# Write dao elements for links
#foreach my $i ( 0 .. ( @{ $f856u{$sysnum} } - 1 ) ) {
#    $writer->startTag(
#        "dao", [ $xlink, "href" ] => $f856u{$sysnum}[$i],
#        [ $xlink, "title" ] => $f856z{$sysnum}[$i]
#    );
#    $writer->endTag("dao");
#}

# Write a link to the HAN OPAC (exception: pseudo records for unlinked records)

#unless ( $f909{$sysnum} =~ /einzel/ ) {
#    $writer->startTag(
#        "dao", [ $xlink, "type" ] => "simple",
#        [ $xlink, "show" ]        => "embed",
#        [ $xlink, "actuate" ]     => "onLoad",
#        [ $xlink, "href" ]        => 'http://aleph.unibas.ch/F/?local_base=DSV05&con_lng=GER&func=find-b&find_code=SYS&request=' . $sysnum,
#        [ $xlink, "title" ] => "Katalogeintrag im Verbundkatalog HAN"
#    );
#    $writer->endTag("dao");
#}

# Gives back the maximum length of the arrays given as arguments
sub maxarray {
    my $max;
    foreach my $i ( 0 .. ( @_ - 1 ) ) {
        $max = scalar @{ $_[$i] } if scalar @{ $_[$i] } > $max;
    }
    return $max;
}

# Checks if the variable is both defined and not an empty string
sub hasvalue {
    my $i = 1 if defined $_[0] && $_[0] ne "";
    return $i;
}

# Links together MARC subfields including interpunction
sub isbd {
    if ( hasvalue( $_[1] ) ) {
        $_[0] = $_[0] . $_[2] . $_[1] . $_[3];
    }
}

# Generates a simple ead-element:
# Argument 0: element content
# Argument 1: element tag
# Argument 2: element argument name
# Argument 3: element argument content
sub simpletag {
    if ( ref($_[0]) eq 'ARRAY') {
        if ( @{ $_[0] } > 0 ) {
            foreach my $i ( 0 .. ( @{ $_[0] } - 1 ) ) {
                $writer->startTag( $_[1], $_[2] => $_[3] );
                $writer->characters( $_[0][$i] );
                $writer->endTag( $_[1] );
            }
        }
    } else {
        if (hasvalue($_[0])) {
            $writer->startTag( $_[1], $_[2] => $_[3] );
            $writer->characters( $_[0] );
            $writer->endTag( $_[1] );
        }
    }
}

# Generates an ead-element with head element and p-tags:
# Argument 0: p-element content
# Argument 1: element tag
# Argument 2: head element content
sub simpletag_p {
    if ( ref($_[0]) eq 'ARRAY') {
        if ( @{ $_[0] } > 0 ) {
            $writer->startTag( $_[1] );
            $writer->startTag("head");
            $writer->characters( $_[2] );
            $writer->endTag("head");
            foreach my $i ( 0 .. ( @{ $_[0] } - 1 ) ) {
                $writer->startTag("p");
                $writer->characters( $_[0][$i] );
                $writer->endTag("p");
            }
            $writer->endTag( $_[1] );
        }
    } else {
        if (hasvalue($_[0])) {
            $writer->startTag( $_[1] );
            $writer->startTag("head");
            $writer->characters( $_[2] );
            $writer->endTag("head");
            $writer->startTag("p");
            $writer->characters( $_[0] );
            $writer->endTag("p");
            $writer->endTag( $_[1] );
        }
    }
}

# Generates an ead-element with head element and bibref-tags:
# Argument 0: bibref-element content
# Argument 1: element tag
# Argument 2: head element content
sub simpletag_b {
    if ( ref($_[0]) eq 'ARRAY') {
        if ( @{ $_[0] } > 0 ) {
            $writer->startTag( $_[1] );
            $writer->startTag("head");
            $writer->characters( $_[2] );
            $writer->endTag("head");
            foreach my $i ( 0 .. ( @{ $_[0] } - 1 ) ) {
                $writer->startTag("bibl");
                $writer->characters( $_[0][$i] );
                $writer->endTag("bibl");
            }
            $writer->endTag( $_[1] );
        }
    } else {
        if (hasvalue($_[0])) {
            $writer->startTag( $_[1] );
            $writer->startTag("head");
            $writer->characters( $_[2] );
            $writer->endTag("head");
            $writer->startTag("bibl");
            $writer->characters( $_[0] );
            $writer->endTag("bibl");
            $writer->endTag( $_[1] );
        }
    }
}

# Adaption of the marc_map function of the Catmandu Projekt
# If a repeated field is present, Catmandu only extracts the subfields into an array if they exist.
# This causes a problem if we later want to combine different subfields with the isbd sub.
# 1st field 700b   -> marc_map(700b) will create an array with 1 element, marc_map(700a) will do nothing
# 2nd field 700ab  -> marc_map(700b) will add a second element to the array, marc_map(700a) will create an array with one element
# If we now want to combine subfields a and b, we will combine subfield a of the second field with subfield b of the first
# Solution (i.e. hack): Create an empty aray element even if no subfield is found.

sub marc_map {
    my ( $data, $marc_path, %opts ) = @_;

    return unless exists $data->{'record'};

    my $record = $data->{'record'};

    unless ( defined $record && ref $record eq 'ARRAY' ) {
        return wantarray ? () : undef;
    }

    my $split     = $opts{'-split'};
    my $join_char = $opts{'-join'} // '';
    my $pluck     = $opts{'-pluck'};
    my $attrs     = {};

    if ( $marc_path =~
        /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9^]+)?(\/(\d+)(-(\d+))?)?/ )
    {
        $attrs->{field}          = $1;
        $attrs->{ind1}           = $3;
        $attrs->{ind2}           = $4;
        $attrs->{subfield_regex} = defined $5 ? "[$5]" : "[a-z0-9_]";
        $attrs->{from}           = $7;
        $attrs->{to}             = $9;
    }
    else {
        return wantarray ? () : undef;
    }

    $attrs->{field_regex} = $attrs->{field};
    $attrs->{field_regex} =~ s/\*/./g;

    my $add_subfields = sub {
        my $var   = shift;
        my $start = shift;

        my @v = ();

        if ($pluck) {

            # Treat the subfield_regex as a hash index
            my $_h = {};
            for ( my $i = $start ; $i < @$var ; $i += 2 ) {
                push @{ $_h->{ $var->[$i] } }, $var->[ $i + 1 ];
            }
            for my $c ( split( '', $attrs->{subfield_regex} ) ) {
                push @v, @{ $_h->{$c} } if exists $_h->{$c};
            }
        }
        else {
            my $found = "false";
            for ( my $i = $start ; $i < @$var ; $i += 2 ) {
                if ( $var->[$i] =~ /$attrs->{subfield_regex}/ ) {
                    push( @v, $var->[ $i + 1 ] );
                    $found = "true";
                }
            }
            if ( $found eq "false" ) {
                # !!! The following line was changes from Catmandu. Pushes an empty string, if no subfield is found
                push( @v, "" );
            }
        }

        return \@v;
    };

    my @vals = ();

    for my $var (@$record) {
        next if $var->[0] !~ /$attrs->{field_regex}/;
        next if defined $attrs->{ind1} && $var->[1] ne $attrs->{ind1};
        next if defined $attrs->{ind2} && $var->[2] ne $attrs->{ind2};

        my $v;

        if ( $var->[0] =~ /LDR|00./ ) {
            $v = $add_subfields->( $var, 3 );
        }
        elsif ( defined $var->[5] && $var->[5] eq '_' ) {
            $v = $add_subfields->( $var, 5 );
        }
        else {
            $v = $add_subfields->( $var, 3 );
        }

        if (@$v) {
            if ( !$split ) {
                $v = join $join_char, @$v;

                if ( defined( my $off = $attrs->{from} ) ) {
                    my $len =
                      defined $attrs->{to} ? $attrs->{to} - $off + 1 : 1;
                    $v = substr( $v, $off, $len );
                }
            }
        }

        push( @vals, $v
          )   #if ( (ref $v eq 'ARRAY' && @$v) || (ref $v eq '' && length $v ));
    }

    if (wantarray) {
        return @vals;
    }
    elsif ( @vals > 0 ) {
        return join $join_char, @vals;
    }
    else {
        return undef;
    }
}

exit;

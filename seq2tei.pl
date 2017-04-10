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

# Read out current date
use DateTime;
my $dt            = DateTime->now;
my $syncdate      = $dt->ymd('');
my $syncdatehuman = $dt->datetime() . "+00:00";

# Catmandu-Module for importin Aleph sequential
use Catmandu::Importer::MARC::ALEPHSEQ;

# Information about output file (ead-xml)
my $output    = IO::File->new(">$ARGV[1]");
#my $xlink     = "http://www.w3.org/1999/xlink";
#my $xmlns     = "http://www.tei-c.org/ns/1.0";
#my $xsi       = "http://www.w3.org/2001/XMLSchema-instance";
#my $xsischema = "urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd";
my $writer    = XML::Writer->new(
    OUTPUT     => $output,
    NEWLINES   => 1,
    ENCODING   => "utf-8",
    NAMESPACES => 1,
    PREFIX_MAP => {
       # $xlink     => 'xlink',
       # $xsi       => 'xsi',
       # $xsischema => 'xsi:schemaLocation',
        $xmlns     => ''
    }
);

# Check arguments
die "Argumente: $0 Input-Dokument (alephseq), Output Dokument\n"
  unless @ARGV == 2;

# Hash with concordance 852$n and country name
my %country = (
    "AT"  => "Österreich",
    "CH"  => "Schweiz",
    "DE"  => "Deutschland",
    "DK"  => "Dänemark",
    "EE"  => "Estland",
    "FI"  => "Finnland",
    "FR"  => "Frankreich",
    "GB"  => "Grossbritannien",
    "IT"  => "Italien",
    "KB"  => "Italien",
    "NL"  => "Niedernlande",
    "RU"  => "Russland",
    "SE"  => "Schweden",
    "US"  => "Vereinigte Staaten von Amerika"

);

# Hash with concordance 852$a and place name
my %place = (
    "Basel UB" => "Basel",
    "Basel UB Wirtschaft - SWA" => "Basel",
    "Bern Gosteli-Archiv" => "Bern",
    "Bern UB Schweizerische Osteuropabibliothek" => "Bern",
    "Bern UB Archives REBUS" => "Bern",
    "Bern UB Medizingeschichte: Rorschach-Archiv" => "Bern",
    "KB Appenzell Ausserrhoden" => "Trogen",
    "KB Thurgau" => "Frauenfeld",
    "Luzern ZHB" => "Luzern",
    "ZB Solothurn" => "Solothurn",
    "St. Gallen KB Vadiana" => "St. Gallen",
    "St. Gallen Stiftsbibliothek" => "St. Gallen",
);

# Array with relator codes which will be used for the tei export
my @relator = [
    "Annotator",
    "Auftraggeber",
    "Buchbinder",
    "Drucker",
    "Illustrator",
    "Mitwirkender",
    "Papierhersteller",
    "Schreiber",
    "Übersetzer",
    "Widmungsverfasser",
    "Zweifelhafter Autor",
];

# Hash with concordance MARC21 relator codes and ead relator codes
my %relator = (
    'Andere'                     => 'Beiträger',
    'Autor'                      => 'Verfasser',
    'Bildhauer'                  => 'Künstler',
    'Buchbinder/Buchbinderei'    => 'Buchbinder',
    'Darsteller/Interpret'       => 'Interpret',
    'Filmemacher'                => 'Regisseur',
    'Früherer Eigentümer'        => 'Vorbesitzer',
    'Gegenwärtiger Eigentümer'   => 'Inhaber',
    'Illustrator/Atelier'        => 'Illustrator',
    'Kartograph'                 => 'Verfasser',
    'Mitwirkender'               => 'Beiträger',
    'Sänger'                     => 'Künstler',
    'Schreiber/Scriptorium'      => 'Schreiber',
    'Sprecher/Erzähler'          => 'Sprecher',
    'Textdichter'                => 'Texter',
    'Widmungsverfasser'          => 'Widmungsschreiber',
    'Zweifelhafter Autor'        => 'Verfasser',
);

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

# Catmandu importer to read each MARC record and export the information needed to generate the xml file
my $importer = Catmandu::Importer::MARC::ALEPHSEQ->new( file => $ARGV[0] );
$importer->each(
    sub {
        my $data          = $_[0];
        my $sysnum        = $data->{'_id'};
        my $f008          = marc_map( $data, '008' );
        my $language008   = substr( $f008, 35, 3 );
        my $date0081      = substr( $f008, 7,  4 );
        my $date0082      = substr( $f008, 11, 4 );
        my $f041          = marc_map( $data, '041a' );
        my @f046a         = marc_map( $data, '046a' );
        my @f046b         = marc_map( $data, '046b' );
        my @f046c         = marc_map( $data, '046c' );
        my @f046d         = marc_map( $data, '046d' );
        my @f046e         = marc_map( $data, '046e' );
        my $f100a         = marc_map( $data, '100a' );
        my $f100b         = marc_map( $data, '100b' );
        my $f100a         = marc_map( $data, '110a' ) unless hasvalue($f100a);
        my $f100b         = marc_map( $data, '110b' ) unless hasvalue($f100b);
        my $f130a         = marc_map( $data, '130a' );
        my $f245a         = marc_map( $data, '245a' );
        my $f245b         = marc_map( $data, '245b', '-join', ', ' );
        my @f246a         = marc_map( $data, '246a' );
        my @f246i         = marc_map( $data, '246i' );
        my $f250          = marc_map( $data, '250a' );
        my @f254          = marc_map( $data, '254a' );
        my $f260a         = marc_map( $data, '260a' );
        my $f260c         = marc_map( $data, '260c' );
        my $f300a         = marc_map( $data, '300a', '-join', ', ' );
        my $f300e         = marc_map( $data, '300e' );
        my $f300c         = marc_map( $data, '300c', '-join', ', ' );
        my @f340          = marc_map( $data, '340a', '-join', ', ' );
        my $f351a         = marc_map( $data, '351a' );
        my $f351c         = marc_map( $data, '351c' );
        my $f490          = marc_map( $data, '490w' );
        my @f500          = marc_map( $data, '500[  ]a' );
        my @f505          = marc_map( $data, '500'  );
        my @f505n         = marc_map( $data, '505n' );
        my @f505g         = marc_map( $data, '505g' );
        my @f505r         = marc_map( $data, '505r' );
        my @f505t         = marc_map( $data, '505t' );
        my @f505i         = marc_map( $data, '505i' );
        my @f505s         = marc_map( $data, '505s' );
        my @f505v         = marc_map( $data, '505v', '-join', ', ' );
        my @f506a         = marc_map( $data, '506a' );
        my @f506c         = marc_map( $data, '506c' );
        my @f510a         = marc_map( $data, '510a' );
        my @f510i         = marc_map( $data, '510i' );
        my @f520a         = marc_map( $data, '520a' );
        my @f520b         = marc_map( $data, '520b', '-join', ', ' );
        my @f5203         = marc_map( $data, '5203' );
        my @f525          = marc_map( $data, '525a' );
        my @f5413         = marc_map( $data, '5413' );
        my @f541c         = marc_map( $data, '541c' );
        my @f541a         = marc_map( $data, '541a' );
        my @f541d         = marc_map( $data, '541d' );
        my @f541e         = marc_map( $data, '541e' );
        my @f541f         = marc_map( $data, '541f' );
        my @f544          = marc_map( $data, '544n' );
        my @f545a         = marc_map( $data, '545a' );
        my @f545b         = marc_map( $data, '545b', '-join', ', ' );
        my @f546          = marc_map( $data, '546a' );
        my @f555          = marc_map( $data, '555a' );
        my @f561          = marc_map( $data, '561a' );
        my @f563          = marc_map( $data, '563a' );
        my @f581i         = marc_map( $data, '581i' );
        my @f581a         = marc_map( $data, '581a' );
        my @f5813         = marc_map( $data, '5813', '-join', ', ' );
        my @f600a         = marc_map( $data, '600a' );
        my @f600q         = marc_map( $data, '600q' );
        my @f600b         = marc_map( $data, '600b' );
        my @f600c         = marc_map( $data, '600c', '-join', ', ' );
        my @f600d         = marc_map( $data, '600d' );
        my @f6001         = marc_map( $data, '6001' );
        my @f610a         = marc_map( $data, '610a' );
        my @f610b         = marc_map( $data, '610b', '-join', ', ' );
        my @f6101         = marc_map( $data, '6101' );
        my @f611a         = marc_map( $data, '611a' );
        my @f611e         = marc_map( $data, '611e', '-join', ', ' );
        my @f6111         = marc_map( $data, '6111' );
        my @f650a         = marc_map( $data, '650[ 7]a' );
        my @f650v         = marc_map( $data, '650[ 7]v', '-join', ', ' );
        my @f650x         = marc_map( $data, '650[ 7]x', '-join', ', ' );
        my @f650y         = marc_map( $data, '650[ 7]y', '-join', ', ' );
        my @f650z         = marc_map( $data, '650[ 7]z', '-join', ', ' );
        my @f6501         = marc_map( $data, '650[ 7]1' );
        my @f651a         = marc_map( $data, '651[ 7]a' );
        my @f651v         = marc_map( $data, '651[ 7]v', '-join', ', ' );
        my @f651x         = marc_map( $data, '651[ 7]x', '-join', ', ' );
        my @f651y         = marc_map( $data, '651[ 7]y', '-join', ', ' );
        my @f651z         = marc_map( $data, '651[ 7]z', '-join', ', ' );
        my @f6511         = marc_map( $data, '651[ 7]1' );
        my @f655          = marc_map( $data, '655[ 7]a' );
        my @f700a         = marc_map( $data, '700a' );
        my @f700q         = marc_map( $data, '700q' );
        my @f700b         = marc_map( $data, '700b' );
        my @f700c         = marc_map( $data, '700c', '-join', ', ' );
        my @f700d         = marc_map( $data, '700d' );
        my @f700e         = marc_map( $data, '700e' );
        my @f700t         = marc_map( $data, '700t' );
        my @f700n         = marc_map( $data, '700n', '-join', ', ' );
        my @f700p         = marc_map( $data, '700p', '-join', ', ' );
        my @f700m         = marc_map( $data, '700m', '-join', ', ' );
        my @f700r         = marc_map( $data, '700r' );
        my @f700s         = marc_map( $data, '700s' );
        my @f700o         = marc_map( $data, '700o' );
        my @f700h         = marc_map( $data, '700h' );
        my @f7001         = marc_map( $data, '7001' );
        my @f710a         = marc_map( $data, '710a' );
        my @f710b         = marc_map( $data, '710b', '-join', ', ' );
        my @f7101         = marc_map( $data, '7101' );
        my @f710e         = marc_map( $data, '710e' );
        my @f711a         = marc_map( $data, '711a' );
        my @f711e         = marc_map( $data, '711e', '-join', ', ' );
        my @f7111         = marc_map( $data, '7111' );
        my @f711j         = marc_map( $data, '711j' );

        #Fields 100, 110 and 111 are treated like 7##-fields and are therefore shifted into these arrays
        if ( marc_map( $data, '100' ) ne "" ) {
            unshift @f700a,       marc_map( $data, '100a' );
            unshift @f700q,       marc_map( $data, '100q' );
            unshift @f700b,       marc_map( $data, '100b' );
            unshift @f700c,       marc_map( $data, '100c', '-join', ', ' );
            unshift @f700d,       marc_map( $data, '100d' );
            unshift @f700e,       marc_map( $data, '100e' );
            unshift @f700t,       undef;
            unshift @f700n,       undef;
            unshift @f700p,       undef;
            unshift @f700m,       undef;
            unshift @f700r,       undef;
            unshift @f700s,       undef;
            unshift @f700o,       undef;
            unshift @f700h,       undef;
            unshift @f7001,       marc_map( $data, '1001' );
        }

        if ( marc_map( $data, '110' ) ne "" ) {
            unshift @f710a,       marc_map( $data, '110a' );
            unshift @f710b,       marc_map( $data, '110b', '-join', ', ' );
            unshift @f710e,       marc_map( $data, '110e' );
            unshift @f7101,       marc_map( $data, '1101' );
        }

        if ( marc_map( $data, '111' ) ne "" ) {
            unshift @f711a,       marc_map( $data, '111a' );
            unshift @f711e,       marc_map( $data, '111e', '-join', ', ' );
            unshift @f7111,       marc_map( $data, '1111' );
            unshift @f711j,       marc_map( $data, '111j' );
        }

        my @f730a           = marc_map( $data, '730a' );
        my @f751a           = marc_map( $data, '751a' );
        my @f7511           = marc_map( $data, '7511' );
        my $f852            = marc_map( $data, '852[  ]' );
        my @f852A           = marc_map( $data, '852[A ]' );
        my @f852E           = marc_map( $data, '852[E ]' );
        my @f852a           = marc_map( $data, '852[  ]a' );
        my @f852b           = marc_map( $data, '852[  ]b' );
        my @f852Ab          = marc_map( $data, '852[A ]b' );
        my @f852Eb          = marc_map( $data, '852[E ]b' );
        my @f852Aa          = marc_map( $data, '852[A ]p' );
        my @f852Ea          = marc_map( $data, '852[E ]p' );
        my @f852p           = marc_map( $data, '852[  ]p' );
        my @f852Ap          = marc_map( $data, '852[A ]p' );
        my @f852Ep          = marc_map( $data, '852[E ]p' );
        my @f852n           = marc_map( $data, '852[  ]a' );
        my @f852An          = marc_map( $data, '852[A ]p' );
        my @f852En          = marc_map( $data, '852[E ]p' );
        my @f856u           = marc_map( $data, '856u' );
        my @f856z           = marc_map( $data, '856z' );
        my $f773            = marc_map( $data, '773w' );
        my $f909            = marc_map( $data, '909f' );
        my @catdate         = marc_map( $data, 'CATc' );

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
            $date008      = $date0081 . "/" . $date0082;
            $date008_hum = $date0081 . "-" . $date0082;
        }
        else {
            $date008 = $date008_hum  = $date0081;
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

        my $f046_max =
            maxarray( \@f046a, \@f046b, \@f046c, \@f046d,
                \@f046e );

        my @f046_hum;
        my @f046;

        # Modify 046 based on their length.
        # The normalised version has the format YYYY, YYYY-MM or YYYYMMDD, with - as a prefix for BC dates
        # The human readable version hat the format YYYY, MM.YYYY or DD.MM.YYYY with v as a prefix for BC dates
        for my $i ( 0 .. ($f046_max) - 1 ) {
            if ( length( $f046b[$i] ) == 6 ) {
                $f046b_hum[$i] = "v" . substr( $f046b_hum[$i], 4, 2 ) . "." . substr( $f046b_hum[$i], 0, 4 );
                $f046b[$i] = "-" . substr( $f046b[$i], 0, 4 ) . "-" . substr( $f046b[$i], 4, 2 );
            }
            elsif ( length( $f046b[$i] ) == 8 ) {
                $f046b_hum[$i] = "v" . substr( $f046b_hum[$i], 6, 2 ) . "." . substr( $f046b_hum[$i], 4, 2 ) . "." . substr( $f046b_hum[$i], 0, 4 );
                $f046b[$i] = "-" . $f046b[$i];
            }
            elsif ( $f046b[$i] ) {
                $f046b_hum[$i] = "v" . $f046b_hum[$i];
                $f046b[$i]     = "-" . $f046b[$i];
            }

            if ( length( $f046c[$i] ) == 6 ) {
                $f046c_hum[$i] = substr( $f046c_hum[$i], 4, 2 ) . "." . substr( $f046c_hum[$i], 0, 4 );
                $f046c[$i] = substr( $f046c[$i], 0, 4 ) . "-" . substr( $f046c[$i], 4, 2 );
            }
            elsif ( length( $f046c[$i] ) == 8 ) {
                $f046c_hum[$i] = substr( $f046c_hum[$i], 6, 2 ) . "." . substr( $f046c_hum[$i], 4, 2 ) . "." . substr( $f046c_hum[$i], 0, 4 );
            }

            if ( length( $f046d[$i] ) == 6 ) {
                $f046d_hum[$i] = "v" . substr( $f046d_hum[$i], 4, 2 ) . "." . substr( $f046d_hum[$i], 0, 4 );
                $f046d[$i] = "-" . substr( $f046d[$i], 0, 4 ) . "-" . substr( $f046d[$i], 4, 2 );
            }
            elsif ( length( $f046d[$i] ) == 8 ) {
                $f046d_hum[$i] = "v" . substr( $f046d_hum[$i], 6, 2 ) . "." . substr( $f046d_hum[$i], 4, 2 ) . "." . substr( $f046d_hum[$i], 0, 4 );
                $f046d[$i] = "-" . $f046d[$i];
            }
            elsif ( $f046d[$i] ) {
                $f046d_hum[$i] = "v" . $f046d_hum[$i]; $f046d[$i]      = "-" . $f046d[$i];
            }

            if ( length( $f046e[$i] ) == 6 ) {
                $f046e_hum[$i] = substr( $f046e_hum[$i], 4, 2 ) . "." . substr( $f046e_hum[$i], 0, 4 ); $f046e[$i] = substr( $f046e[$i], 0, 4 ) . "-" . substr( $f046e[$i], 4, 2 );
            }
            elsif ( length( $f046e[$i] ) == 8 ) {
                $f046e_hum[$i] = substr( $f046e[$i], 6, 2 ) . "." . substr( $f046e_hum[$i], 4, 2 ) . "." . substr( $f046e_hum[$i], 0, 4 );
            }

            # If BC dates exist (fields 046$b and $d, replace the AC fields with the BC dates
            $f046c[$i] = $f046b[$i] unless $f046c[$i];
            $f046e[$i] = $f046d[$i] unless $f046e[$i];

            $f046c_hum[$i] = $f046b_hum[$i] unless $f046c_hum[$i];
            $f046e_hum[$i] = $f046d_hum[$i] unless $f046e_hum[$i];

            # Create a human readable date field from field 046
            my $newf046_hum;
            $newf046_hum = $f046c_hum[$i] . "-" . $f046e_hum[$i] unless $f046e_hum[$i] eq "";
            push @f046_hum, $newf046_hum;

            # Create a normalized date field from field 046
            my $newf046;
            $newf046 = $f046c[$i] . "/" . $f046e[$i] unless $f046e[$i] eq "";

            # Check if normalized date field matches the ead date regex, if not insert empty date
            if ( $newf046 =~ /^(-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|-((01|02|03|04|05|06|07|08|09|10|11|12)(\-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)(\/-?(0|1|2)([0-9]{3})(((01|02|03|04|05|06|07|08|09|10|11|12)((0[1-9])|((1|2)[0-9])|(3[0-1])))|-((01|02|03|04|05|06|07|08|09|10|11|12)(-((0[1-9])|((1|2)[0-9])|(3[0-1])))?))?)?$/ ) {
                push @f046, $newf046;
            }
            else {
                push @f046, "";
            }
        }

        # Split field 041 into separate language coes
        my @langcodes;
        my @f041 = $f041 =~ m/(...)/g;
        # Remove first language codes (not necessary, as it is also present in field 008
        shift @f041;
        # Push language code from field 008 into langcodes array
        push @langcodes, $language008 unless $language008 =~ /(zxx|und)/;

        my $otherlang = join(" ", (shift @langcodes));

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
        my $f245 = $100a;
        isbd( $f245, $f100b, " " );
        isbd( $f245, $f245a, " : " );
        isbd( $f245, $f245b, ", " );
        $f245 =~ s/^\s//g;
        $f245 =~ s/^\s:\s//g;

        # Set 246$i = "Weiterer Titel" if $i does not exist
        for my $i ( 0 .. (@f246a) - 1 ) {
            if ( !( hasvalue( $f246i[$i] ) ) ) {
                $f246i[$i] = "Weiterer Titel";
            }
        }

        # Generate alt-title from subfields
        my @f246;
        my $f246_max = maxarray( \@f246a, \@f246i );
        for my $i ( 0 .. ($f246_max) - 1 ) {
            isbd( $f246[$i], $f246i[$i] );
            isbd( $f246[$i], $f246a[$i], ": " );
        }

        # Construct place field from 260$a and 751 (only use 751$a if not identical to 250$a)
        unless ($f260a eq $f751a) {
           $f260a .= " [" . $f751a . "]"
        }

        # Generate extent field
        my $f300 = $f300a;
        isbd( $f300, $f300e, " + " );

        # If no 351$c (description level) is present, set it to Dossier=File
        unless ( hasvalue($f351c) ) {
            $f351c = "Dossier=File";
        }

        # If 351$c does not contain one of the standardised level, set it to Dossier=File
        unless ( hasvalue( $lvlarg{$f351c} ) ) {
            $f351c = "Dossier=File";
        }

        # Edit linking field: Make sure there are leading zeros. If field 773 is present, overwrite field 490 with the contents of field 773
        $f490  = sprintf( "%-9.9d", $f490 );
        $f773 = sprintf( "%-9.9d", $f773 );
        $f490 = $f773 unless $f490;

        # Generate content note from field 505 subfields
        my $f520_max =
            maxarray( \@f505n, \@f505g );
        for my $i ( 0 .. ($f505_max) - 1 ) {
            isbd( $f505n[$i], $f505g[$i], ": " );
            $f505n[$i] =~ s/^:\s//;
        }
        # Generate content note from field 520 subfields
        my @f520;
        my $f520_max =
            maxarray( \@f520a, \@f520b, \@f5203 );
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

        # Generate an acquisition note from field 541 subfields
        my @f541;
        my $f541_max = maxarray(
            \@f5413, \@f541c, \@f541a,
            \@f541d, \@f541e, \@f541f
        );
        for my $i ( 0 .. ($f541_max) - 1 ) {
            isbd( $f541[$i], $f5413[$i], "",           ": " );
            isbd( $f541[$i], $f541c[$i], "",           ". " );
            isbd( $f541[$i], $f541a[$i], "Herkunft: ", ". " );
            isbd( $f541[$i], $f541d[$i], "Datum: ",    ". " );
            isbd( $f541[$i], $f541e[$i], "Akz.-Nr.: ", ". " );
            isbd( $f541[$i], $f541f[$i], "Eigentümer: " );
        }

        # Generate an literature note from field 581 subfields
        my @f581;
        my $f581_max =
          maxarray( \@f581i, \@f581a, \@f5813 );
        for my $i ( 0 .. ($f581_max) - 1 ) {
            isbd( $f581[$i], $f581i[$i], "",         ": " );
            isbd( $f581[$i], $f581a[$i] );
            isbd( $f581[$i], $f5813[$i], " (betr. ", ")" );
            $f581[$i] =~ s/^,\s//;
        }

        # Generate a biographical history fields from field 545 subfields
        my @f545;
        my $f545_max = maxarray( \@f545a, \@f545b );
        for my $i ( 0 .. ($f545_max) - 1 ) {
            $f545[$i] = $f545a[$i];
            isbd( $f545[$i], $f545b[$i], ". " );
        }

        # Generate a subject field (persons) from the field 600 subfields
        for (@f6001) { s/\(DE-588\)//g }
        my @f600;
        my $f600_max = maxarray(
            \@f600a, \@f600q, \@f600b,
            \@f600c, \@f600d
        );
        for my $i ( 0 .. ($f600_max) - 1 ) {
            $f600[$i] = $f600a[$i];
            isbd( $f600[$i], $f600q[$i], " (",  ")" );
            isbd( $f600[$i], $f600b[$i], " " );
            isbd( $f600[$i], $f600c[$i], ", " );
            isbd( $f600[$i], $f600d[$i], ", (", ")" );
        }

        # Generate a subject field (cooporations) from the field 610 subfields
        for (@f6101) { s/\(DE-588\)//g }
        my @f610;
        my $f610_max = maxarray( \@f610a, \@f610b );
        for my $i ( 0 .. ($f610_max) - 1 ) {
            $f610[$i] = $f610a[$i];
            isbd( $f610[$i], $f610b[$i], ". " );
        }

        # Generate a subject field (conferences) from the field 611 subfields
        for (@f6111) { s/\(DE-588\)//g }
        my @f611;
        my $f611_max = maxarray( \@f611a, \@f611e );
        for my $i ( 0 .. ($f611_max) - 1 ) {
            $f611[$i] = $f611a[$i];
            isbd( $f611[$i], $f611e[$i], ". " );
        }

        # Generate a subject field (subject terms) from the field 650 subfields
        for (@f6501) { s/\(DE-588\)//g }
        my @f650;
        my $f650_max = maxarray(
            \@f650a, \@f650v, \@f650x,
            \@f650y, \@f650z
        );
        for my $i ( 0 .. ($f650_max) - 1 ) {
            $f650[$i] = $f650a[$i];
            isbd( $f650[$i], $f650v[$i], " -- " );
            isbd( $f650[$i], $f650x[$i], " -- " );
            isbd( $f650[$i], $f650y[$i], " -- " );
            isbd( $f650[$i], $f650z[$i], " -- " );
        }

        # Generate a subject field (geographical) from the field 651 subfields
        for (@f6511) { s/\(DE-588\)//g }
        my @f651;
        my $f651_max = maxarray(
            \@f651a, \@f651v, \@f651x,
            \@f651y, \@f651z
        );
        for my $i ( 0 .. ($f651_max) - 1 ) {
            $f651[$i] = $f651a[$i];
            isbd( $f651[$i], $f651v[$i], " -- " );
            isbd( $f651[$i], $f651x[$i], " -- " );
            isbd( $f651[$i], $f651y[$i], " -- " );
            isbd( $f651[$i], $f651z[$i], " -- " );
        }

        # Generate an author field from the 700 and 100 subfields
        for (@f7001) { s/\(DE-588\)//g }
        my @f700;
        my $f700_max = maxarray(
            \@f700a, \@f700q, \@f700b, \@f700c, \@f700d,
            \@f700t, \@f700n, \@f700p, \@f700m, \@f700r,
            \@f700s, \@f700o, \@f700h
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
        }

        # Generate an author field from the 710 and 110 subfields
        for (@f7101) { s/\(DE-588\)//g }
        my @f710;
        my $f710_max = maxarray( \@f710a, \@f710b );
        for my $i ( 0 .. ($f710_max) - 1 ) {
            $f710[$i] = $f710a[$i];
            isbd( $f710[$i], $f710b[$i], ". " );
        }

        # Generate an author field from the 711 and 111 subfields
        for (@f7111) { s/\(DE-588\)//g }
        my @f711;
        my $f711_max = maxarray( \@f711a, \@f711e );
        for my $i ( 0 .. ($f711_max) - 1 ) {
            $f711[$i] = $f711a[$i];
            isbd( $f711[$i], $f711e[$i], ". " );
        }

        # Replace MARC relator codes (fields 700$e, 710$e and 711$j with ead codes
        for my $relator ( keys %relator ) {
            foreach my $i ( 0 .. ( @f700e - 1 ) ) {
                if ( $f700e[$i] =~ $relator ) {
                    $f700e[$i] = $relator{$relator};
                }
            }
            foreach my $j ( 0 .. ( @f710e - 1 ) ) {
                if ( $f710e[$j] =~ $relator ) {
                    $f710e[$j] = $relator{$relator};
                }
            }
            foreach my $k ( 0 .. ( @f711j - 1 ) ) {
                if ( $f711j[$k] =~ $relator ) {
                    $f711j[$k] = $relator{$relator};
                }
            }
        }

        # Prepare origination field from field 751
        for (@f7511) { s/\(DE-588\)//g }

        # Translate country codes from 852$n into country name
        for my $country ( keys %country ) {
            if ( $f852n =~ $country ) {
                $f852n = $country{$country};
            }
            if ( $f852An =~ $country ) {
                $f852An = $country{$country};
            }
            if ( $f852En =~ $country ) {
                $f852En = $country{$country};
            }
        }

        # Extract placenames from 852$a
        for my $place ( keys %place ) {
            if ($f852a eq $place) {
                $f852a_place = $place{$place};
            }
            if ($f852Aa eq $place) {
                $f852Aa_place = $place{$place};
            }
            if ($f852Ea eq $country) {
                $f852Ea_place = $place{$place};
            }
        }

        # If the 856$z field contains "Digitalisat" remove the entire field except the word "Digitalisat"
        foreach (@f856z) {
            s/^.*Digitalisat.*$/Digitalisat/g;
        }

        # Construct the array catdatehuman with the dates from the CAT field in human-readable form
        my @catdatehuman;
        for (@catdate) {
            push @catdatehuman, ( substr( $_, 6 ) . "." . substr( $_, 4, 2 ) . "." . substr( $_, 0, 4 ) );
        }

        # If the 909$f field contains "hide_this ead", set f909 to einzel.
        # These are the pseudo-records to which unlinked records (not part of an hierarchy) are linked in the ead export.
        # They are hidden in Aleph, for the ead export they have to be taken into account, therefore we remove the hidden code
        if ( $f909 =~ /hide_this ead/ ) {
            $f909 = "einzel";
        }

        # Some records don't have to be exported as ead (records with 909-code hide this and some library specific records)
        unless (
                  ( $f909 =~ /hide_this/ )
               || ( $f351c =~ /Abteilung/ )
               || ( $f351c =~ /Hauptabteilung/ )
               || ( $f909 =~ /collect_this.handschrift/ && $f852 =~ /UBHandschriften/ )
               || ( $f909 =~ /collect_this.miszellan/ && $f852 =~ /UBHandschriften/ )
               || ( $f909 =~ /collect_this.handschrift/ && $f852 =~ /Luzern.ZHB/ )
               || ( $f909 =~ /collect_this.handschrift/ && $f852 =~ /Vadiana/ )
               || ( $f852 =~ /REBUS/ )
        )
        {
            # If a record has to be exported, we read in its field (already manipulated) into hashes (key = sysnum)
            push( @sysnum, $sysnum );
            $date008{$sysnum}          = $date008;
            $date008_hum{$sysnum}      = $date008_hum;
            $f046{$sysnum}             = [@f046];
            $f046_hum{$sysnum}         = [@f046_hum];
            $f245{$sysnum}             = ($f245);
            $f246{$sysnum}             = [@f246];
            $f250{$sysnum}             = $f250;
            $f254{$sysnum}             = [@f254];
            $f260a{$sysnum}            = $f260a;
            $f260c{$sysnum}            = $f260c;
            $f300{$sysnum}             = $f300;
            $f300c{$sysnum}            = $f300c;
            $f340{$sysnum}             = [@f340];
            $f351a{$sysnum}            = $f351a;
            $f351c{$sysnum}            = $f351c;
            $f500{$sysnum}             = [@f500];
            $f505{$sysnum}             = [@f505];
            $f505n{$sysnum}            = [@f505n];
            $f505r{$sysnum}            = [@f505r];
            $f505t{$sysnum}            = [@f505t];
            $f505i{$sysnum}            = [@f505i];
            $f505v{$sysnum}            = [@f505v];
            $f505s{$sysnum}            = [@f505s];
            $f506{$sysnum}             = [@f506];
            $f510{$sysnum}             = [@f510];
            $f520{$sysnum}             = [@f520];
            $f525{$sysnum}             = [@f525];
            $f541{$sysnum}             = [@f541];
            $f544{$sysnum}             = [@f544];
            $f545{$sysnum}             = [@f545];
            $f555{$sysnum}             = [@f555];
            $f561{$sysnum}             = [@f561];
            $f563{$sysnum}             = [@f563];
            $f581{$sysnum}             = [@f581];
            $f490{$sysnum}             = $f490;
            my %f852;
            $f852{$sysnum}             = $f852;
            my %f852A;
            $f852A{$sysnum}            = [@f852A];
            my %f852E;
            $f852E{$sysnum}            = [@f852E];
            my %f852a;
            $f852a{$sysnum}            = [@f852a];
            my %f852a_place;
            $f852a_place{$sysnum}      = [@f852a_place];
            my %f852b;
            $f852b{$sysnum}            = [@f852b];
            my %f852p;
            $f852p{$sysnum}            = [@f852p];
            my %f852n;
            $f852n{$sysnum}            = [@f852n];
            my %f852Aa;
            $f852Aa{$sysnum}           = [@f852Aa];
            my %f852Aa_place;
            $f852Aa_place{$sysnum}     = [@f852Aa_place];
            my %f852Ab;
            $f852Ab{$sysnum}           = [@f852Ab];
            my %f852Ap;
            $f852Ap{$sysnum}           = [@f852Ap];
            my %f852Ea;
            $f852Ea{$sysnum}           = [@f852Ea];
            my %f852Ea_place;
            $f852Ea_place{$sysnum}     = [@f852Ea_place];
            my %f852Eb;
            $f852Eb{$sysnum}           = [@f852Eb];
            my %f852Ep;
            $f852Ep{$sysnum}           = [@f852Ep];
            $f600{$sysnum}             = [@f600];
            $f600a{$sysnum}            = [@f600a];
            $f6001{$sysnum}            = [@f6001];
            $f600c{$sysnum}            = [@f600c];
            $f610{$sysnum}             = [@f610];
            $f610a{$sysnum}            = [@f610a];
            $f6101{$sysnum}            = [@f6101];
            $f611{$sysnum}             = [@f611];
            $f611a{$sysnum}            = [@f611a];
            $f6111{$sysnum}            = [@f6111];
            $f650{$sysnum}             = [@f650];
            $f650a{$sysnum}            = [@f650a];
            $f6501{$sysnum}            = [@f6501];
            $f651{$sysnum}             = [@f651];
            $f651a{$sysnum}            = [@f651a];
            $f6511{$sysnum}            = [@f6511];
            $f655{$sysnum}             = [@f655];
            $f700{$sysnum}             = [@f700];
            $f700a{$sysnum}            = [@f700a];
            $f7001{$sysnum}            = [@f7001];
            $f700e{$sysnum}            = [@f700e];
            $f710{$sysnum}             = [@f710];
            $f710a{$sysnum}            = [@f710a];
            $f7101{$sysnum}            = [@f7101];
            $f710e{$sysnum}            = [@f710e];
            $f711{$sysnum}             = [@f711];
            $f711a{$sysnum}            = [@f711a];
            $f7111{$sysnum}            = [@f7111];
            $f711j{$sysnum}            = [@f711j];
            $f751a{$sysnum}            = [@f751a];
            $f7511{$sysnum}            = [@f7511];
            $f856u{$sysnum}            = [@f856u];
            $f856z{$sysnum}            = [@f856z];
            $f909{$sysnum}             = $f909;
            $isilsysnum{$sysnum}       = $isilsysnum;
            $isilnum{$sysnum}          = $isilnum;
            $languages{$sysnum}        = [@languages];
            $langcodes{$sysnum}        = [@langcodes];
            $otherlang{$sysnum}        = $otherlang;
            $catdate{$sysnum}          = [@catdate];
            $catdatehuman{$sysnum}     = [@catdatehuman];
        }
    }
);

#Now we're ready to being creating ead-files. First we select all records with level=Bestand and build up an ead-file
#containint their children records. Exception: The pseudo records for unlinked records.

foreach (@sysnum) {
    if ( ( $f351c{$_} =~ /Bestand/ ) && !( $f909{$_} =~ /einzel/ ) ) {
        intro($_);
        tei($_);
        extro();
    }
}

#After all records linked to Bestände (Fonds) are used, we created the ead-files for the unlinked records. We can
#identify them by the contant of the sysnumcheck hash (for records which were already used the hash value is true,
#to make sure we don't use a record twice.

#First we set the 490 field of each unlinked record, so that is points to the pseudo record.

foreach (@sysnum) {
    unless ( $sysnumcheck{$_} ) {
        if ( $f852{$_} =~ /Basel UBHandschriften/ ) {
            $f490{$_} = '000297324' unless $_ == '000297324';
        }
        elsif ( $f852{$_} =~ /SWA/ ) {
            $f490{$_} = '000297326' unless $_ == '000297326';
        }
        elsif ( $f852{$_} =~ /Gosteli/ ) {
            $f490{$_} = '000297327' unless $_ == '000297327';
        }
        elsif ( $f852{$_} =~ /Rorschach/ ) {
            $f490{$_} = '000297330' unless $_ == '000297330';
        }
        elsif ( $f852{$_} =~ /Ausserrhoden/ ) {
            $f490{$_} = '000297407' unless $_ == '000297407';
        }
        elsif ( $f852{$_} =~ /Thurgau/ ) {
            $f490{$_} = '000297408' unless $_ == '000297408';
        }
        elsif ( $f852{$_} =~ /Luzern/ ) {
            $f490{$_} = '000297409' unless $_ == '000297409';
        }
        elsif ( $f852{$_} =~ /Solothurn/ ) {
            $f490{$_} = '000297410' unless $_ == '000297410';
        }
        elsif ( $f852{$_} =~ /Vadiana/ ) {
            $f490{$_} = '000297411' unless $_ == '000297411';
        }
        elsif ( $f852{$_} =~ /Stiftsbibliothek/ ) {
            $f490{$_} = '000297412' unless $_ == '000297412';
        }
    }
}

#Second we create ead files for each pseudo record

foreach (@sysnum) {
    if ( $f909{$_} =~ /einzel/ ) {
        intro($_);
        ead($_);
        extro();
    }
}

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
    if ( defined $_[0] ) {
        foreach my $i ( 0 .. ( @{ $_[0] } - 1 ) ) {
            $writer->startTag( $_[1], $_[2] => $_[3] );
            $writer->characters( $_[0][$i] );
            $writer->endTag( $_[1] );
        }
    }
}

# Generates an ead-element with head element and p-tags:
# Argument 0: p-element content
# Argument 1: element tag
# Argument 2: head element content
sub simpletag_p {
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
}

# Generates an ead-element with head element and bibref-tags:
# Argument 0: bibref-element content
# Argument 1: element tag
# Argument 2: head element content
sub simpletag_b {
    if ( @{ $_[0] } > 0 ) {
        $writer->startTag( $_[1] );
        $writer->startTag("head");
        $writer->characters( $_[2] );
        $writer->endTag("head");
        foreach my $i ( 0 .. ( @{ $_[0] } - 1 ) ) {
            $writer->startTag("bibref");
            $writer->characters( $_[0][$i] );
            $writer->endTag("bibref");
        }
        $writer->endTag( $_[1] );
    }
}

# Creates the beginning of an tei-file
sub intro {
    my $sysnum = $_[0];

    $writer->xmlDecl("UTF-8");
    $writer->startTag("ead");

    $writer->startTag(
        "tei",
        "version" => "5.0",
            xmlns="http://www.tei-c.org/ns/1.0"
    );

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
    $writer->endTag("tei");
    $writer->end();
}

# Writes the body of an ead-file
sub tei {
    # The sub is executed with the system number of the records we're currently transforming
    my $sysnum = $_[0];

    $writer->startTag("msIdentifier");

    simpletag( $f852n{$sysnum},  "country" );
    simpletag( $f852a_place{$sysnum},  "settlement" );
    simpletag( $f852a{$sysnum},  "institution" );
    simpletag( $f852b{$sysnum},  "repository" );
    simpletag( $f852p{$sysnum},  "idno" );

    foreach my $i ( 0 .. ( @{ $f856A{$sysnum} } - 1 ) ) {
        if (hasvalue($f856A{$sysnum}[$i]))  {
            $writer->startTag("altIdentifier", "type" => "former");
            simpletag( $f852An{$sysnum},  "country" );
            simpletag( $f852Aa_place{$sysnum},  "settlement" );
            simpletag( $f852Aa{$sysnum},  "institution" );
            simpletag( $f852Ab{$sysnum},  "repository" );
            simpletag( $f852Ap{$sysnum},  "idno" );
            $writer->end("altIdentifier", "type" => "former");
        }
    }

    foreach my $i ( 0 .. ( @{ $f856E{$sysnum} } - 1 ) ) {
        if (hasvalue($f856E{$sysnum}[$i]))  {
            $writer->startTag("altIdentifier", "type" => "alternative");
            simpletag( $f852En{$sysnum},  "country" );
            simpletag( $f852Ea_place{$sysnum},  "settlement" );
            simpletag( $f852Ea{$sysnum},  "institution" );
            simpletag( $f852Eb{$sysnum},  "repository" );
            simpletag( $f852Ep{$sysnum},  "idno" );
            $writer->end("altIdentifier", "type" => "former");
        }
    }

    $writer->endTag("msIdentifier");

    $writer->startTag("head");
    simpletag( $f245{$sysnum},  "title" );
    simpletag( $f246{$sysnum},  "title" );
    simpletag( $f130a{$sysnum},  "title" );
    simpletag( $f730a{$sysnum},  "title" );
    simpletag( $f700t{$sysnum},  "title" );
    simpletag( $f655{$sysnum},  "title", "type", "supplied" );

    foreach my $i ( 0 .. ( @{ $f700{$sysnum} } - 1 ) ) {
        if ( $f700e{$sysnum}[$i] ~~ @relator ) {
            $writer->startTag("respStmt");
            simpletag( $f700e{$sysnum}, "resp" );
            simpletag( $f700{$sysnum}, "name" );
            $writer->endTag("respStmt");
        }
    }

    foreach my $i ( 0 .. ( @{ $f710{$sysnum} } - 1 ) ) {
        if ( $f710e{$sysnum}[$i] ~~ @relator ) {
            $writer->startTag("respStmt");
            simpletag( $f710e{$sysnum}, "resp" );
            simpletag( $f710{$sysnum}, "name" );
            $writer->endTag("respStmt");
        }
    }

    foreach my $i ( 0 .. ( @{ $f711{$sysnum} } - 1 ) ) {
        if ( $f711j{$sysnum}[$i] ~~ @relator ) {
            $writer->startTag("respStmt");
            simpletag( $f711j{$sysnum}, "resp" );
            simpletag( $f711{$sysnum}, "name" );
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

    # Write langmaterial element for language information, both codes and human readable
    foreach my $i ( 0 .. ( @{ $f546{$sysnum} } - 1 ) ) {
        $writer->startTag( "textLang", "mainLang" => $langcodes{$sysnum}[0], "otherLang" => $otherlang{$sysnum} );
        $writer->characters( $f546{$sysnum}[$i] );
        $writer->endTag("language");
    }
    $writer->endTag("textLang");

    foreach my $i ( 0 .. ( @{ $f505{$sysnum} } - 1 ) ) {
        $writer->startTag("msItem");
        simpletag( $f505n{$sysnum}[$i], "locus" );
        simpletag( $f505r{$sysnum}[$i], "author" );
        simpletag( $f505t{$sysnum}[$i], "title" );
        simpletag( $f505i{$sysnum}[$i], "quote" );
        simpletag( $f505v{$sysnum}[$i], "bibl" );
        simpletag( $f505s{$sysnum}[$i], "note" );
        $writer->endTag("msItem");
    }


    $writer->endTag("msContents");


    $writer->startTag("physDesc");


    $writer->endTag("physDesc");


    $writer->startTag("history");


    $writer->endTag("history");


    $writer->startTag("additional");


    $writer->endTag("additional");

    # Depending on field 351, we use either an archdesc or a c-element
    $writer->startTag(
        $lvl{ $f351c{$sysnum} },
        "level" => $lvlarg{ $f351c{$sysnum} },
        "id"    => $isilsysnum{$sysnum}
    );
    $writer->startTag("did");

    # Write unitid elements for signature information
    simpletag( $f852p{$sysnum},  "unitid" );
    simpletag( $f852Ap{$sysnum}, "unitid", "label", "Weitere Signatur" );
    simpletag( $f852Ep{$sysnum}, "unitid", "label", "Frühere Signatur" );

    # Write dao elements for links
    foreach my $i ( 0 .. ( @{ $f856u{$sysnum} } - 1 ) ) {
        $writer->startTag(
            "dao", [ $xlink, "href" ] => $f856u{$sysnum}[$i],
            [ $xlink, "title" ] => $f856z{$sysnum}[$i]
        );
        $writer->endTag("dao");
    }

    # Write a link to the HAN OPAC (exception: pseudo records for unlinked records)

    unless ( $f909{$sysnum} =~ /einzel/ ) {
        $writer->startTag(
            "dao", [ $xlink, "type" ] => "simple",
            [ $xlink, "show" ]        => "embed",
            [ $xlink, "actuate" ]     => "onLoad",
            [ $xlink, "href" ]        => 'http://aleph.unibas.ch/F/?local_base=DSV05&con_lng=GER&func=find-b&find_code=SYS&request=' . $sysnum,
            [ $xlink, "title" ] => "Katalogeintrag im Verbundkatalog HAN"
        );
        $writer->endTag("dao");
    }

    # Write repository element for the library/archive
    $writer->startTag("repository");
    $writer->startTag(
        "corpname",
        "role"           => "Bestandshaltende Einrichtung",
        "normal"         => $f852a{$sysnum}[0],
        "authfilenumber" => $isilnum{$sysnum}
    );
    $writer->characters( $f852a{$sysnum}[0] );
    $writer->endTag("corpname");
    $writer->endTag("repository");


    # Write origination element for the creator of the Fonds (1##/7##$e=Aktenbildner)
    # Case 1: Creator is a person
    foreach my $i ( 0 .. ( @{ $f700{$sysnum} } - 1 ) ) {
        if ( $f700e{$sysnum}[$i] eq 'Aktenbildner' ) {
            # Depending whether the 100/700 field has a GND-link we treat the field differently
            if ( $f7001{$sysnum}[$i] ne "" ) {
                $writer->startTag("origination");
                $writer->startTag(
                    "persname",
                    "normal"         => $f700a{$sysnum}[$i],
                    "role"           => "Bestandsbildner",
                    "source"         => "GND",
                    "authfilenumber" => "$f7001{$sysnum}[$i]"
                );
                $writer->characters( $f700{$sysnum}[$i] );
                $writer->endTag("persname");
                $writer->endTag("origination");
            }
            else {
                $writer->startTag("origination");
                $writer->startTag(
                    "persname",
                    "normal" => $f700a{$sysnum}[$i],
                    "role"   => "Bestandsbildner"
                );
                $writer->characters( $f700{$sysnum}[$i] );
                $writer->endTag("persname");
                $writer->endTag("origination");
            }
        }
    }

    # Case 2: Creator is a cooperation
    foreach my $i ( 0 .. ( @{ $f710{$sysnum} } - 1 ) ) {
        if ( $f710e{$sysnum}[$i] eq 'Aktenbildner' ) {
            # Depending whether the 100/700 field has a GND-link we treat the field differently
            if ( $f7101{$sysnum}[$i] ne "" ) {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal"         => $f710a{$sysnum}[$i],
                    "role"           => "Bestandsbildner",
                    "source"         => "GND",
                    "authfilenumber" => "$f7101{$sysnum}[$i]"
                );
                $writer->characters( $f710{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
            else {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal" => $f710a{$sysnum}[$i],
                    "role"   => "Bestandsbildner"
                );
                $writer->characters( $f710{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
        }
    }

    # Case 3: Creator is a conference
    foreach my $i ( 0 .. ( @{ $f711{$sysnum} } - 1 ) ) {
        if ( $f711j{$sysnum}[$i] eq 'Aktenbildner' ) {
            # Depending whether the 100/700 field has a GND-link we treat the field differently
            if ( $f7111{$sysnum}[$i] ne "" ) {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal"         => $f711a{$sysnum}[$i],
                    "role"           => "Bestandsbildner",
                    "source"         => "GND",
                    "authfilenumber" => "$f7111{$sysnum}[$i]"
                );
                $writer->characters( $f711{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
            else {
                $writer->startTag("origination");
                $writer->startTag(
                    "corpname",
                    "normal" => $f711a{$sysnum}[$i],
                    "role"   => "Bestandsbildner"
                );
                $writer->characters( $f711{$sysnum}[$i] );
                $writer->endTag("corpname");
                $writer->endTag("origination");
            }
        }
    }

    # Generate unittitle element for field 245. Write additional unititle elements for 246 fields (with attribute label=245$i)
    if ( hasvalue( $f245{$sysnum} ) ) {
        $writer->startTag("unittitle");
        $writer->characters( $f245{$sysnum} );
        $writer->endTag("unittitle");

        foreach my $i ( 0 .. ( @{ $f246{$sysnum} } - 1 ) ) {
            $writer->startTag( "unittitle",
                "label" => $f246i{$sysnum}[$i] );
            $writer->startTag("title");
            $writer->characters( $f246{$sysnum}[$i] );
            $writer->endTag("title");
            $writer->endTag("unittitle");
        }
    }
    # If only fields 246 are present, use the first field in place of field 245
    else {
        $writer->startTag( "unittitle", "label" => $f246i{$sysnum}[0] );
        $writer->characters( $f246{$sysnum}[0] );
        $writer->endTag("unittitle");

        foreach my $i ( 1 .. ( @{ $f246{$sysnum} } - 1 ) ) {
            $writer->startTag( "unittitle",
                "label" => $f246i{$sysnum}[$i] );
            $writer->startTag("title");
            $writer->characters( $f246{$sysnum}[$i] );
            $writer->endTag("title");
            $writer->endTag("unittitle");
        }
    }

    simpletag( $f254{$sysnum}, "materialspec" );

    $writer->startTag("physdesc");

    simpletag($f250{$sysnum},  "physfacet", "label", "Ausreifungsgrad" );
    simpletag($f300{$sysnum},  "extent" );
    simpletag($f300c{$sysnum}, "dimensions" );
    simpletag($f340{$sysnum},  "physfacet", "label", "Material" );
    simpletag($f563{$sysnum},  "physfacet", "label", "Einband" );

    $writer->endTag("physdesc");

    foreach my $i ( 0 .. ( @{ $f500{$sysnum} } - 1 ) ) {
        $writer->startTag( "note",
            "label"    => "Bemerkung",
            "audience" => "external"
        );
        $writer->startTag("p");
        $writer->characters( $f500{$sysnum}[$i] );
        $writer->endTag("p");
        $writer->endTag("note");
    }

    simpletag( $f525{$sysnum}, "abstract", "type", "Darin" );

    $writer->endTag("did");

    simpletag_p( $f520{$sysnum},     "scopecontent", "Inhaltsangabe" );
    simpletag_p( $f351a{$sysnum},    "arrangement", "Ordnungszustand" );
    simpletag_p( $f506{$sysnum},     "userestrict", "Benutzungsbeschränkung" );

    simpletag_b( $f510{$sysnum},     "bibliography", "Bibliographie" );
    simpletag_b( $f581{$sysnum},     "bibliography", "Literaturhinweise" );

    simpletag_p( $f541{$sysnum},     "acqinfo", "Akzession" );
    simpletag_p( $f544{$sysnum},     "relatedmaterial", "Verwandte Verzeichnungseinheiten" );
    simpletag_p( $f545{$sysnum},     "bioghist",        "Biographische Notiz" );
    simpletag_p( $f555{$sysnum},     "otherfindaid",    "Weitere Findmittel" );
    simpletag_p( $f561{$sysnum},     "custodhist",      "Angaben zur Herkunft" );

    #Write controlacess element for persons, if there are 600 or 700 fields present (except 700$e=Aktenbildner fields)
    if (
        ( @{ $f600{$sysnum} } > 0 )
        || ( @{ $f700{$sysnum} } > 0 && !( 'Aktenbildner' ~~ @{ $f700e{$sysnum} } ) )
      )
    {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Personen');
        $writer->endTag("head");

        # Special case for 600 fields with 600$c=Familie
        foreach my $i ( 0 .. ( @{ $f600{$sysnum} } - 1 ) ) {
            if ( $f600c{$sysnum}[$i] =~ /Familie/ ) {
                # Depending whether the 600 field has a GND-link we treat the field differently
                if ( $f6001{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "persname",
                        "role"           => "Erwähnte Familie",
                        "normal"         => $f600a{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$f6001{$sysnum}[$i]"
                    );
                    $writer->characters( $f600{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
                else {
                    $writer->startTag(
                        "persname",
                        "role"   => "Erwähnte Familie",
                        "normal" => $f600a{$sysnum}[$i]
                    );
                    $writer->characters( $f600{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
            }
            # Normal persons in 600 fields
            else {
                # Depending whether the 600 field has a GND-link we treat the field differently
                if ( $f6001{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "persname",
                        "role"           => "Erwähnte Person",
                        "normal"         => $f600a{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$f6001{$sysnum}[$i]"
                    );
                    $writer->characters( $f600{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
                else {
                    $writer->startTag(
                        "persname",
                        "role"   => "Erwähnte Person",
                        "normal" => $f600a{$sysnum}[$i]
                    );
                    $writer->characters( $f600{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
            }
        }

        # Normal persons in 700 fields
        foreach my $i ( 0 .. ( @{ $f700{$sysnum} } - 1 ) ) {
            unless ( $f700e{$sysnum}[$i] eq 'Aktenbildner' ) {
                # Depending whether the 700 field has a GND-link we treat the field differently
                if ( $f7001{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "persname",
                        "normal"         => $f700a{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$f7001{$sysnum}[$i]",
                        "role"           => $f700e{$sysnum}[$i]
                    );
                    $writer->characters( $f700{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
                else {
                    $writer->startTag(
                        "persname",
                        "normal" => $f700a{$sysnum}[$i],
                        "role"   => $f700e{$sysnum}[$i]
                    );
                    $writer->characters( $f700{$sysnum}[$i] );
                    $writer->endTag("persname");
                }
            }
        }

        $writer->endTag("controlaccess");
    }

    #Write controlacess element for coorporations and conferences, if there are 610, 611, 710 or 711 fields present (except 700$e/710$j=Aktenbildner fields)
    if (
           ( @{ $f610{$sysnum} } > 0 )
        || ( @{ $f611{$sysnum} } > 0 )
        || ( @{ $f710{$sysnum} } > 0 && !( 'Aktenbildner' ~~ @{ $f710e{$sysnum} } ) )
        || ( @{ $f711{$sysnum} } > 0 && !( 'Aktenbildner' ~~ @{ $f711j{$sysnum} } ) )
      )
    {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Körperschaften');
        $writer->endTag("head");

        # Coorporation in field 610
        foreach my $i ( 0 .. ( @{ $f610{$sysnum} } - 1 ) ) {
            # Depending whether the 610 field has a GND-link we treat the field differently
            if ( $f6101{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "corpname",
                    "role"           => "Erwähnte Körperschaft",
                    "normal"         => $f610a{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$f6101{$sysnum}[$i]"
                );
                $writer->characters( $f610{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
            else {
                $writer->startTag(
                    "corpname",
                    "role"   => "Erwähnte Körperschaft",
                    "normal" => $f610a{$sysnum}[$i]
                );
                $writer->characters( $f610{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
        }

        # Coorporation in field 710
        foreach my $i ( 0 .. ( @{ $f710{$sysnum} } - 1 ) ) {
            unless ( $f710e{$sysnum}[$i] eq 'Aktenbildner' ) {
                # Depending whether the 710 field has a GND-link we treat the field differently
                if ( $f7101{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "corpname",
                        "normal"         => $f710a{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$f7101{$sysnum}[$i]",
                        "role"           => $f710e{$sysnum}[$i]
                    );
                    $writer->characters( $f710{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
                else {
                    $writer->startTag(
                        "corpname",
                        "normal" => $f710a{$sysnum}[$i],
                        "role"   => $f710e{$sysnum}[$i]
                    );
                    $writer->characters( $f710{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
            }
        }

        # Conference in field 611
        foreach my $i ( 0 .. ( @{ $f611{$sysnum} } - 1 ) ) {
            # Depending whether the 611 field has a GND-link we treat the field differently
            if ( $f6111{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "corpname",
                    "role"           => "Erwähnte Körperschaft",
                    "normal"         => $f611a{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$f6111{$sysnum}[$i]"
                );
                $writer->characters( $f611{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
            else {
                $writer->startTag(
                    "corpname",
                    "role"   => "Erwähnte Körperschaft",
                    "normal" => $f611a{$sysnum}[$i]
                );
                $writer->characters( $f611{$sysnum}[$i] );
                $writer->endTag("corpname");
            }
        }

        # Conference in field 711
        foreach my $i ( 0 .. ( @{ $711{$sysnum} } - 1 ) ) {
            unless ( $f711j{$sysnum}[$i] eq 'Aktenbildner' ) {
                # Depending whether the 711 field has a GND-link we treat the field differently
                if ( $f7111{$sysnum}[$i] ne "" ) {
                    $writer->startTag(
                        "corpname",
                        "normal"         => $f711a{$sysnum}[$i],
                        "source"         => "GND",
                        "authfilenumber" => "$f7111{$sysnum}[$i]",
                        "role"           => $f711j{$sysnum}[$i]
                    );
                    $writer->characters( $711{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
                else {
                    $writer->startTag(
                        "corpname",
                        "normal" => $f711a{$sysnum}[$i],
                        "role"   => $f711j{$sysnum}[$i]
                    );
                    $writer->characters( $711{$sysnum}[$i] );
                    $writer->endTag("corpname");
                }
            }
        }

        $writer->endTag("controlaccess");

    }

    # Write controlaccess term for subject headings
    unless ( @{ $f650{$sysnum} } == 0 ) {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Sachschlagwörter');
        $writer->endTag("head");

        foreach my $i ( 0 .. ( @{ $f650{$sysnum} } - 1 ) ) {
            # Depending whether the 650 field has a GND-link we treat the field differently
            if ( defined $f6501{$sysnum}[$i] ) {
                $writer->startTag(
                    "subject",
                    "normal"         => $f650a{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$f6501{$sysnum}[$i]"
                );
                $writer->characters( $f650{$sysnum}[$i] );
                $writer->endTag("subject");
            }
            else {
                $writer->startTag( "subject",
                    "normal" => $f650a{$sysnum}[$i] );
                $writer->characters( $f650{$sysnum}[$i] );
                $writer->endTag("subject");
            }
        }

        $writer->endTag("controlaccess");

    }

    # Write controlaccess element for geographical places
    unless ( ( @{ $f651{$sysnum} } == 0 )
        && ( @{ $f751a{$sysnum} } == 0 ) )
    {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Orte');
        $writer->endTag("head");

        # Place in field 651
        foreach my $i ( 0 .. ( @{ $f651{$sysnum} } - 1 ) ) {
            # Depending whether the 651 field has a GND-link we treat the field differently
            if ( $f6511{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "geogname",
                    "role"           => "Erwähnter Ort",
                    "normal"         => $f651a{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$f6511{$sysnum}[$i]"
                );
                $writer->characters( $f651{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
            else {
                $writer->startTag(
                    "geogname",
                    "role"   => "Erwähnter Ort",
                    "normal" => $f651a{$sysnum}[$i]
                );
                $writer->characters( $f651{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
        }

        # Place in field 751
        foreach my $i ( 0 .. ( @{ $f751a{$sysnum} } - 1 ) ) {
            # Depending whether the 751 field has a GND-link we treat the field differently
            if ( $f7511{$sysnum}[$i] ne "" ) {
                $writer->startTag(
                    "geogname",
                    "role"           => "Entstehungsort",
                    "normal"         => $f751a{$sysnum}[$i],
                    "source"         => "GND",
                    "authfilenumber" => "$f7511{$sysnum}[$i]"
                );
                $writer->characters( $f751a{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
            else {
                $writer->startTag(
                    "geogname",
                    "role"   => "Entstehungsort",
                    "normal" => $f751a{$sysnum}[$i]
                );
                $writer->characters( $f751a{$sysnum}[$i] );
                $writer->endTag("geogname");
            }
        }
        $writer->endTag("controlaccess");
    }

    # Write controlaccess element for genre
    unless ( @{ $f655{$sysnum} } == 0 ) {
        $writer->startTag("controlaccess");

        $writer->startTag("head");
        $writer->characters('Gattungen');
        $writer->endTag("head");

        simpletag( $f655{$sysnum}, "genreform" );

        $writer->endTag("controlaccess");
    }

    $writer->startTag("odd");
    $writer->startTag("head");
    $writer->characters("Steuerfelder");
    $writer->endTag("head");

    $writer->startTag("list");
    $writer->startTag("item");

    # Write first CAT-date (creation date)
    if ( hasvalue( $catdate{$sysnum}[0] ) ) {
        $writer->startTag(
            "date",
            "type"   => "Erfassungsdatum",
            "normal" => $catdate{$sysnum}[0]
        );
        $writer->characters( $catdatehuman{$sysnum}[0] );
        $writer->endTag("date");
    }

    # Write last CAT-date (last edit date)
    if ( hasvalue( $catdate{$sysnum}[-1] ) ) {
        $writer->startTag(
            "date",
            "type"   => "Modifikationsdatum",
            "normal" => $catdate{$sysnum}[-1]
        );
        $writer->characters( $catdatehuman{$sysnum}[-1] );
        $writer->endTag("date");
    }

    # Write syncronisation date = run daten of this script
    $writer->startTag(
        "date",
        "type"   => "Synchronisationsdatum",
        "normal" => $syncdate
    );
    $writer->characters($syncdatehuman);
    $writer->endTag("date");

    $writer->endTag("item");
    $writer->endTag("list");

    $writer->endTag("odd");

    # Write dsc tag for childern (only if the level of the present record = Bestand
    if ( $lvl{ $f351c{$sysnum} } eq "archdesc" ) {
        $writer->startTag("dsc");
    }

    # Run the addchildren subroutine to find and convert childern records (based on 490/773 linking fields)

    addchildren($sysnum);

    # Close dsc tag for childern (only if the level of the present record = Bestand
    if ( $lvl{ $f351c{$sysnum} } eq "archdesc" ) {
        $writer->endTag("dsc");
    }

    # Close archdesc or c element
    $writer->endTag( $lvl{ $f351c{$sysnum} } );

}
# Sub to find and convert childern records
sub addchildren {
    # Check for each record (=keys f490) if there is a record with the system number of the present record ($_[0]). If found, execute
    # the ead sub for this record.
    for my $child ( keys %f490 ) {
        if ( $f490{$child} == $_[0] ) {
            ead($child);
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

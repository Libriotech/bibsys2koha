#!/usr/bin/perl -w

# bibsys-items.pl - Convert data from BIBSYS into format suitable for Koha
# Copyright 2012 Magnus Enger Libriotech

# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

=head1 NAME

items.pl - Assemble records and item info into a MARCXML file that can be imported into Koha.

=head1 SYNOPSIS

perl items.pl -m records.mrc -i items.dok > records-with-items.xml

=cut

use MARC::File::USMARC;
use MARC::File::XML;
use Getopt::Long;
use Data::Dumper;
use File::Slurp;
use Pod::Usage;
use Modern::Perl;
use utf8;

binmode STDOUT, ":utf8";

# CONFIG

# Example
my %itemtypemap = (
    'pv'  => 'BK',
    'p8v' => 'BK',
    'psv' => 'OPPG',
    'pdv' => 'OPPG',
    'phv' => 'OPPG',
    'ncx' => 'NETTDOK',
    'nx'  => 'NETTDOK',
    'vv'  => 'BRETTSPILL',
    'y0'  => 'TREDIM',
);

my %ccodemap = (
    'master'  => 'MASTER', 
    'pensum'  => 'PENSUM', 
    'forkurs' => 'FORKURS',
);

# CONFIG END

# Textual explanations of the codes in 008 $a and $b
# http://www.bibsys.no/files/out/handbok_html/marc/marc-02.htm
my %bibsys008a = (
    'p' => 'Trykt materiale',
    'n' => 'Nettdokumenter',
    'v' => 'CD-er',
    'w' => 'DVD-er',
    'u' => 'Magnetbånd (på spole eller kassett)',
    'x' => 'Manuskripter (originalmanuskripter og avskrifter, ikke faksimiler)',
    'a' => 'Mikroformer',
    't' => 'Grammofonplater',
    'h' => 'Filmruller',
    's' => 'Disketter',
    'o' => 'Grafisk materiale som er tenkt projisert eller gjennomlyst',
    'i' => 'Grafisk materiale ugjennomtrengelig for lys (kunstverk, fotografier, o.l.)',
    'y' => 'Tredimensjonale gjenstander',
    'z' => 'Braille (blindeskrift)',
    'æ' => 'Kombidokument',
    'å' => 'Laserplater (laser-optisk (refleksiv) videoplate med analog representasjon)',
    'd' => 'Digibøker',
    'ø' => 'Lagringsbrikker (minnepinner, etc.)',
    'q' => 'Blu-ray',
    '0' => 'Udefinert'
);
my %bibsys008b = (
    'v' => 'Monografier',
    'æ' => 'Fragmenter (artikler, musikkspor, etc.)',
    'a' => 'Aviser',
    'p' => 'Bibliografiske databaser (f. eks. ISI-basene, Norbok, o.l.)',
    'q' => 'Fulltekstdatabaser',
    'r' => 'Andre databaser (ordbøker, statistikkbaser, o.l.)',
    'w' => 'Monografiserier, nummererte institusjonsserier',
    'x' => 'Tidsskrifter',
    'y' => 'Årbøker',
    'z' => 'Andre typer løpende ressurser (inkl. årsberetninger, løsbladpublikasjoner, etc.)',
    'n' => 'Innspilt musikk',
    'l' => 'Lydbøker',
    'ø' => 'Andre lydopptak (ikke musikkopptak, ikke lydbøker)',
    'b' => 'Bibliografier, diskografier, filmografier',
    'u' => 'Statistikk',
    '5' => 'Anmeldelser. Brukes til kritiske vurderinger av ulike typer verk (bøker, filmer, lyopptak, teater, o.l.)',
    '6' => 'Encyclopedier og leksika',
    '7' => 'Kataloger',
    '8' => 'Ordbøker',
    '9' => 'Håndbøker.',
    'j' => 'Levende bilder',
    'm' => 'Musikalier (trykte eller elektroniske, etc. og musikkmanuskripter)',
    'e' => 'Tilleggsfunksjonalitet (som finnes f.eks. i e-bøker)',
    'd' => 'Dissertaser',
    'h' => 'masteroppgaver og hovedfagsoppgaver fra norske læresteder',
    's' => 'Studentarbeider, semesteroppgaver og lignende fra norske læresteder',
    'c' => 'Kongresser, symposier',
    'i' => 'Biografier',
    'k' => 'Kart, atlas',
    'o' => 'Billedmateriale',
    'f' => 'Festskrift for person (kun til bruk for NBO)',
    'g' => 'Festskrift for korporasjon (kun til bruk for NBO)',
    '0' => 'Udefinert. Brukes også for digibøker'
);

# Get options
my ($marc_file, $item_file, $out_file, $analytics, $subjects, $ccodes, $f008, $f008ab, $limit, $verbose, $debug) = get_options();

# Check that the file exists
if (!-e $marc_file) {
  print "The file $marc_file does not exist...\n";
  exit;
}

# Check that the file exists
if (!-e $item_file) {
  print "The file $item_file does not exist...\n";
  exit;
}

my $xmloutfile = '';
if ( $out_file ) {
  $xmloutfile = MARC::File::XML->out( $out_file );
}

# Parse the item information and keep it in memory

my @ilines = read_file( $item_file );
my %items;
my $item = {};
my $itemcount = 0;
foreach my $iline ( @ilines ) {
  $iline =~ s/\r\n//g; # chomp does not work
  $iline =~ s/\n//g;   # Some files have one, some have the other
  say $iline if $debug;
  
  if ( $iline eq '^' ) {

    $itemcount++;
    
    push @{$items{ $item->{'recordid'} } }, $item;
    # say Dumper $items{ $item->{'recordid'} } if $debug;
    say Dumper $item if $debug;
    
    # Empty %item so we can start over on a new one
    undef $item;
    next;  

  } elsif ( $iline =~ m/^\*096/ ){
    
    # Item details
    my @subfields = split(/\$/, $iline);
    
    foreach my $subfield (@subfields) {
      
      my $index = substr $subfield, 0, 1;
      next if $index eq '*';
      my $value = substr $subfield, 1;
      $item->{ '096' }{ $index } = $value;
      
    }
      
  } elsif ( $iline =~ m/xh/ ) { # FIXME Turn into command line argument? Or look for lines that start with *001
    $item->{'barcode'}  = substr $iline, 4;
    say $item->{'barcode'} if $debug;
  } else {
    $item->{'recordid'} = substr $iline, 1;
    say $item->{'recordid'} if $debug;
  }
  
}

print Dumper %items if $debug;
say "$itemcount items processed" if $verbose;

# print Dumper $items{'000052139980'};
# die;

## Parse the records and add the item data

my $batch = MARC::File::USMARC->in( $marc_file );
my $count = 0;
my %field008count;
my %field008count_ab;
my %field008ab_text;
my %subjectcount;

# Walk through the records once, to map identifiers to titles. We will use this
# when we convert 491 to 773. 
my %titles;
while (my $record = $batch->next()) {
    if ( $record->field( '001' ) && $record->field( '245' ) && $record->field( '245' )->subfield( 'a' ) ) {
        $titles{ $record->field( '001' )->data() } = $record->field( '245' )->subfield( 'a' );
    }
}

# Walk through the records once more, to do the bulk of the editing
$batch = MARC::File::USMARC->in( $marc_file );
while (my $record = $batch->next()) {

  # Set the UTF-8 flag
  $record->encoding( 'UTF-8' );

  # Get data from 008
  my $field008ab;
  if ( $record->field( '008' ) ) {

      my $field008 = $record->field( '008' )->data();
      
      # Delete the field from the record
      $record->delete_fields( $record->field( '008' ) );
      
      # Remove leading whitespace
      $field008 = substr $field008, 3;
      say $field008 if $verbose;
      
      my $a = ' ';
      my ( @b, $c, $c_count, @multi_c, $d );
      my $e = ' ';
      my $f = '    ';
      my $i = ' ';
      my $n = ' ';
      my $s = ' ';
      
      my @subfields = split(/\$/, $field008);
    
      foreach my $subfield (@subfields) {
      
          my $index = substr $subfield, 0, 1;
          my $value = substr $subfield, 1;
          $field008count{ $index }{ $value }++;
          say "$index = $value" if $verbose;
          if ( $index eq 'a' ) {
              $a = $value;
          }
          if ( $index eq 'b' ) {
              push @b, $value;
          }
          if ( $index eq 'c' ) {
              $c = $value;
              push @multi_c, $c;
              $c_count++;
          }
          if ( $index eq 'd' ) {
              $d = $value;
          }
          if ( $index eq 'e' ) {
              $e = $value;
          }
          if ( $index eq 'f' ) {
              $f = substr $value, 0, 4;
          }
          if ( $index eq 'i' ) {
              $i = $value;
          }
          if ( $index eq 'n' && $value eq 'j' ) {
              $n = $value;
          }
          if ( $index eq 's' ) {
              $s = $value;
          }
      }
      
      $field008ab = $a . join '', sort @b;
      $field008count_ab{ $field008ab }++;
      $field008ab_text{ $field008ab } = $bibsys008a{ $a };
      foreach my $field2text ( @b ) {
          $field008ab_text{ $field008ab } .= " + " . $bibsys008b{ $field2text };
      }

      # Add a new 008 field, and possibly a 041 for multiple languages
      my $field008pos35_37 = '   ';
      if ( $c_count && $c_count > 1 ) {
          $field008pos35_37 = 'mul';
          # Add 041 for all the languages
          my $field041 = MARC::Field->new( '041', ' ', ' ',
              'a' => join '', @multi_c
          );
          if ( $d ) {
              $field041->add_subfields( 'h' => $d );
          }
          $record->insert_fields_ordered( $field041 );
      } elsif ( $c ) {
          $field008pos35_37 = $c;
          if ( $d ) {
              my $field041 = MARC::Field->new( '041', ' ', ' ',
                  'h' => $d
              );
              $record->insert_fields_ordered( $field041 );
          }
      }
      
      # Assemble the 008 string
      my $string008 = ' '; # 00
        $string008 .= ' '; # 01
        $string008 .= ' '; # 02
        $string008 .= ' '; # 03
        $string008 .= ' '; # 04
        $string008 .= ' '; # 05
        $string008 .= $e;  # 06
        $string008 .= $f;  # 07-10
        $string008 .= ' '; # 11
        $string008 .= ' '; # 12
        $string008 .= ' '; # 13
        $string008 .= ' '; # 14
        $string008 .= ' '; # 15
        $string008 .= ' '; # 16
        $string008 .= ' '; # 17
        $string008 .= $i;  # 18
        $string008 .= ' '; # 19
        $string008 .= ' '; # 20
        $string008 .= ' '; # 21
        $string008 .= $n;  # 22
        $string008 .= ' '; # 23
        $string008 .= ' '; # 24
        $string008 .= ' '; # 25
        $string008 .= ' '; # 26
        $string008 .= ' '; # 27
        $string008 .= ' '; # 28
        $string008 .= ' '; # 29
        $string008 .= ' '; # 30
        $string008 .= ' '; # 31
        $string008 .= ' '; # 32
        $string008 .= $s;  # 33
        $string008 .= ' '; # 34
        $string008 .= $field008pos35_37; # 35-37
        $string008 .= ' '; # 38
        $string008 .= ' '; # 39
      # Add the 008
      my $field008new = MARC::Field->new( '008', $string008 );
      $record->insert_fields_ordered( $field008new );
      
  }
  
  # 241
  if ( $record->field( '241' ) && $record->field( '241' )->subfield( 'a' ) ) {
      
      foreach my $field241 ( $record->field( '241' ) ) {
          my $field240 = MARC::Field->new( '240', ' ', ' ',
              'a' => $field241->subfield( 'a' )
          );
          if ( $field241->subfield( 'b' ) ) {
              $field240->add_subfields( 'b' => $field241->subfield( 'b' ) );
          }
          if ( $field241->subfield( 'w' ) ) {
              $field240->add_subfields( 'w' => $field241->subfield( 'w' ) );
          }
          $record->insert_fields_ordered( $field240 );
          $record->delete_fields( $field241 );
      }
  }
  
    # 491
    if ( $record->field( '491' ) && $analytics ) {
        say '-------------------------------------';
        say $record->field( '001' )->as_formatted();
        if ( $record->field( '245' ) ) {
        say $record->field( '245' )->as_formatted();
        }
        say $record->field( '491' )->as_formatted();
    }
    if ( $record->field( '491' ) && $record->field( '491' )->subfield( 'n' ) ) {

        my $field491 = $record->field( '491' );
        my $field773 = MARC::Field->new( '773', ' ', ' ',
            'w' => $field491->subfield( 'n' )
        );
        # Title
        if ( $field491->subfield( 'a' ) ) {
            $field773->add_subfields( 't' => $field491->subfield( 'a' ) );
        } elsif ( $titles{ $field491->subfield( 'n' ) } ) {
            # Use the actual title 
            $field773->add_subfields( 't' => $titles{ $field491->subfield( 'n' ) } );
        }
        if ( $field491->subfield( 'v' ) ) {
            $field773->add_subfields( 'b' => $field491->subfield( 'v' ) );
        }
        $record->insert_fields_ordered( $field773 );
        $record->delete_fields( $field491 );
        
        # Print the 773 we just added
        if ( $analytics ) {
            say $record->field( '773' )->as_formatted();
        }

    }
  
  # 691
  if ( $record->field( '691' ) && $record->field( '691' )->subfield( 'a' ) ) {
    my @subjects = split ' ', $record->field( '691' )->subfield( 'a' );
    foreach my $s ( @subjects ) {
          my $field653 = MARC::Field->new( '653', ' ', ' ',
              'a' => $s
          );
          $record->insert_fields_ordered( $field653 );
          $subjectcount{ $s }++;
    }
  }
  $record->delete_fields( $record->field( '691' ) );
  
  # Remove 899
  $record->delete_fields( $record->field( '899' ) );
  
  # Add item info
  if ( $record->field( '001' ) ) {
    my $dokid = $record->field( '001' )->data();
    say $dokid if $verbose;
    if ( $items{ $dokid } ) {
      foreach my $olditem ( @{ $items{ $dokid } } ) {
        say "Found item for dokid $dokid with barcode ", $olditem->{ 'barcode' } if $debug;
        my $field952 = MARC::Field->new( 952, ' ', ' ',
          'a' => $olditem->{ '096' }{ 'a' }, # Homebranch
          'b' => $olditem->{ '096' }{ 'a' }, # Holdingbranch
          'c' => 'GEN',
          'p' => $olditem->{ 'barcode' },    # Barcode
        );
        # Item type
        my $itemtype;
        if ( $itemtypemap{ $field008ab } ) {
            if ( $olditem->{ '096' }{ 'c' } && $olditem->{ '096' }{ 'c' } =~ m/^Manus/ ) {
                $itemtype = 'MAN';
            } else {
                $itemtype = $itemtypemap{ $field008ab };
            }
        } else {
            $itemtype = 'X';
        }
        my $field942 = MARC::Field->new( 942, ' ', ' ', 'c' => $itemtype );
        $field952->add_subfields( 'y', $itemtype );
        # Collection code
        if ( $olditem->{ '096' }{ 'b' } ) {
            print $olditem->{ '096' }{ 'b' } if $ccodes;
            if ( $ccodemap{ lc $olditem->{ '096' }{ 'b' } } ) {
                print " -> ", $ccodemap{ lc $olditem->{ '096' }{ 'b' } } if $ccodes;
                $field952->add_subfields( '8', $ccodemap{ lc $olditem->{ '096' }{ 'b' } } );
            }
            print "\n" if $ccodes;
        }
        # Call number
        if ( $olditem->{ '096' }{ 'c' } ) {
            if ( $olditem->{ '096' }{ 'c' } =~ m/(.*) \(Ikke fjern/ ) {
                $field952->add_subfields( 'o', $1 );
                $field952->add_subfields( 'z', 'Ikke fjernlån' );
            } else {
                $field952->add_subfields( 'o', $olditem->{ '096' }{ 'c' } );
            }
        }
        # Add the field to the record
        $record->insert_fields_ordered( $field942 );
        $record->insert_fields_ordered( $field952 );
      }
      # say $record->as_formatted;
      # die;
    }
  }
  
  # Write out the record as XML
  if ( $out_file ) {
      $xmloutfile->write($record);
  }
  
  $count++;
  if ( $limit && $limit == $count ) {
      exit;
  }

}

if ( $subjects ) {
    foreach my $key ( sort keys %subjectcount ) {
        say '"', $key, '";', $subjectcount{ $key };
    }
}

if ( $f008 ) {
    print Dumper \%field008count;
}

if ( $f008ab ) {
    foreach my $key (sort {$field008count_ab{$b} <=> $field008count_ab{$a} } keys %field008count_ab) {
        say sprintf("%-4s", $key), sprintf("%5s", $field008count_ab{ $key }), "  ", $field008ab_text{ $key };
    }
}

say "$count records processed" if $verbose;

# Functions

sub get_options {

  # Options
  my $marc_file = '';
  my $item_file = '';
  my $out_file  = '';
  my $analytics = '';
  my $subjects  = '';
  my $ccodes    = '';
  my $f008      = '';
  my $f008ab    = '';
  my $limit     = '',
  my $verbose   = '';
  my $debug     = '';
  my $help      = '';
  
GetOptions (
    'm|marcfile=s' => \$marc_file,
    'i|itemfile=s' => \$item_file,
    'o|outfile=s'  => \$out_file,
    'a|analytics'  => \$analytics,
    's|subjects'   => \$subjects,
    'c|ccodes'     => \$ccodes, 
    'f008'         => \$f008,
    'f008ab'       => \$f008ab,
    'l|limit=i'    => \$limit,
    'v|verbose'    => \$verbose,
    'd|debug'      => \$debug,
    'h|?|help'     => \$help
  );

  pod2usage( -exitval => 0 ) if $help;
  pod2usage( -msg => "\nMissing Argument: -m, --marcfile required\n", -exitval => 1 ) if !$marc_file;
  pod2usage( -msg => "\nMissing Argument: -i, --itemfile required\n", -exitval => 1 ) if !$item_file;

  return ( $marc_file, $item_file, $out_file, $analytics, $subjects, $ccodes, $f008, $f008ab, $limit, $verbose, $debug );

}

__END__

=head1 OPTIONS

=over 4

=item B<-m, --marcfile>

MARC records in ISO2709. If records from BIBSYS are in "line" format they will 
have to be transformed with e.g. line2iso.pl

=item B<-i, --itemfile>

File that contains item information.

=item B<-o, --outfile>

File to write XML records to. If this is left out no records will be output. (Useful for debugging.)

=item B<-a, --analytics>

Dump some info (001, 245, 491 and the generated 773) about analytic records. 

=item B<-s, --subjects>

Print out subjects found in 691 in CSV format.

=item B<-c, --ccodes>

Print original and new collection codes. 

=item B<--f008>

Dump the contents of field 008, with frequencies.

=item B<--f008ab>

Print the concatenated contents of fields 008 a and b, in descending order of frequency.

=item B<-l, --limit>

Only process the n first records (all the items will be processed).

=item B<-v --verbose>

More output.

=item B<-d --debug>

Output extra debug info.

=item B<-h, -?, --help>

Prints this help message and exits.

=back
=cut

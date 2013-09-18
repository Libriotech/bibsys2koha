#!/usr/bin/perl 

=head1 NAME
    
subjects.pl - Extract and display subjects from a MARCXML file.
        
=head1 SYNOPSIS
            
 ./subjects.pl -i records.xml

=cut

use MARC::File::XML ( BinaryEncoding => 'utf8' );
use Getopt::Long;
use Data::Dumper;
use Template;
use Pod::Usage;
use Modern::Perl;
binmode(STDOUT, ":utf8");

# Get options
my ( $input_file, $limit, $verbose, $debug ) = get_options();

# Check that the file exists
if ( !-e $input_file ) {
  print STDERR "The file $input_file does not exist...\n";
  exit;
}

my $record_count = 0;
my %subject_count;

my $file = MARC::File::XML->in( $input_file );
while (my $record = $file->next()) {
    
    say $record->as_formatted if $debug;
    
    if ( $record->field( '650' ) ) {
        my @subjects = $record->field( '650' );
        foreach my $subject ( @subjects ) {
            $subject_count{ $subject->subfield( 'a' ) }++;
        }
    }
    
    if ( $record->field( '653' ) ) {
        my @subjects = $record->field( '653' );
        foreach my $subject ( @subjects ) {
            $subject_count{ $subject->subfield( 'a' ) }++;
        }
    }
    
    $record_count++;
    
    if ( $limit && $record_count == $limit ) {
        last;
    }
    
}

foreach my $sub ( sort keys %subject_count ) {
    say '"' . $sub . '",' . $subject_count{ $sub } ;
}

if ( $verbose ) {
    say STDERR "$record_count records done";
}

=head1 OPTIONS
              
=over 4
                                                   
=item B<-i, --infile>

Name of input file.

=item B<-l, --limit>

Only process the n first somethings.

=item B<-v --verbose>

Prettyprint found records.

=item B<-d --debug>

Output extra debug info.

=item B<-h, -?, --help>
                                               
Prints this help message and exits.

=back
                                                               
=cut

sub get_options {

    # Options
    my $input_file = '';
    my $limit      = '', 
    my $verbose    = '';
    my $debug      = '';
    my $help       = '';

    GetOptions (
        'i|infile=s' => \$input_file,
        'l|limit=i'  => \$limit,
        'v|verbose'  => \$verbose,
        'd|debug'    => \$debug,
        'h|?|help'   => \$help
    );

    pod2usage( -exitval => 0 ) if $help;
    pod2usage( -msg => "\nMissing Argument: -i, --infile required\n", -exitval => 1 ) if !$input_file;

    return ( $input_file, $limit, $verbose, $debug );

}

=head1 AUTHOR

Copyright 2013 Magnus Enger Libriotech

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this file; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut

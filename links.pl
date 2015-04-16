#!/usr/bin/perl 

# Copyright 2015 Magnus Enger Libriotech

=head1 NAME

links.pl - Format links exported from BIBSYS as YAML suitable for use by items.pl.

=head1 SYNOPSIS

 perl links.pl -i /path/to/export.mrc > /path/to/client/config/links.yaml

=cut

use File::Slurper qw( read_lines );
use YAML::Syck;
use Getopt::Long;
use Data::Dumper;
use Template;
use DateTime;
use Pod::Usage;
use Modern::Perl;

# Get options
my ( $input_file, $limit, $verbose, $debug ) = get_options();

# Check that the file exists
if ( !-e $input_file ) {
    print "The file $input_file does not exist...\n";
    exit;
}

my @records;
my %links;
{
    local $/ = '^';
    @records = read_lines( $input_file );
}
foreach my $record ( @records ) {

    $record =~ m/\*000(.*)\n/i;
    my $dokid = $1;
    $record =~ m/\*856  \$u(.*)\n/i;
    my $url = $1;
    $links{ $dokid } = $url;

}

say Dump( \%links );

=head1 OPTIONS

=over 4

=item B<-i, --infile>

Name of input file.

=item B<-l, --limit>

Only process the n first somethings. Not implemented.

=item B<-v --verbose>

More verbose output.

=item B<-d --debug>

Even more verbose output.

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

Magnus Enger, <magnus [at] libriotech.no>

=head1 LICENSE

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

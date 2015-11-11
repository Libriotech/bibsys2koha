#!/bin/bash

# prep.sh Prepare files from BIBSYS for use with items.pl

die() {
    echo "$@" 1>&2
    exit 1
}

# Check for one argument
[ "$#" = 2 ] || die "Usage: $0 /path/to/export/records.txt /path/to/export/items.txt"

# Set up some variables
RECORDS=$1
ITEMS=$2
RECORDS_TMP="$RECORDS.tmp"
ITEMS_TMP="$ITEMS.tmp"
# LINKS=links.txt

echo "Preparing $RECORDS and $ITEMS"

## Fix the records

# Convert to UTF-8
#iconv -f ISO_8859-1 -t UTF-8 -o $RECORDS_TMP $RECORDS
#mv $RECORDS_TMP $RECORDS

sed -i 's/*000/*001/' $RECORDS

# Replace \r\n with \n
perl -pi -e '$/=undef; s/\r\n/\n/g' $RECORDS

# Replace new line + dollar with just dollar
perl -pi -e '$/=undef; s/\n\$/\$/g' $RECORDS

# Replace new line + space with just space
perl -pi -e '$/=undef; s/\n / /g' $RECORDS

# Un-break long lines that are broken over several lines
# This can typically happen with long URLs in 856$u
perl -pi -e '$/=undef; s/\n[^*^]//g' $RECORDS

# Newline followed by a space on the next line should be replaced by just a
# space, so that broken lines are restored. Example:
#
#   *300  $a1 partitur (13 s.)$c30 cm$estemmer
#   *500  $aInnhold: Våren / A. Vivaldi. Marsj / G.F. Händel. Andante / J. Haydn.
#    Andante / W.A. Mozart. Sang til glede / L. van Beethoven.
#   *500  $aEdisjonsnummere: M-H 2947, M-H 2955, M-H 2956, M-H 2957, M-H 2958, M-H
#    2959, M-H 2960
#   *655uk$aPartitur
perl -pi -e '$/=undef; s/\n / /g' $RECORDS

# Remove "@<" and "@>"
sed -i 's/@<//g' $RECORDS
sed -i 's/@>//g' $RECORDS

## Fix the items

# Convert to UTF-8
#iconv -f ISO_8859-1 -t UTF-8 -o $ITEMS_TMP $ITEMS
#mv $ITEMS_TMP $ITEMS

# Replace \r\n with \n
perl -pi -e '$/=undef; s/\r\n/\n/g' $ITEMS

# Replace new line + dollar with just dollar
perl -pi -e '$/=undef; s/\n\$/\$/g' $ITEMS

## Fix the links
# Replace \r\n with \n
# perl -pi -e '$/=undef; s/\r\n/\n/g' $LINKS

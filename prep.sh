#!/bin/bash

# prep.sh Prepare files from BIBSYS for use with items.pl

die() {
    echo "$@" 1>&2
    exit 1
}

# Check for one argument
[ "$#" = 1 ] || die "Usage: $0 /path/to/export/"

# Set up some variables
DIR=$1
ITEMS=items.txt
RECORDS=records.mrk
LINKS=links.txt

# Change into the target dir
cd $DIR

# Give files standard names
cp cat-dok.mrc "$ITEMS"
cp cat-obj.mrc "$RECORDS"
cp WSOC_v1-856.mrc "$LINKS"

## Fix the records

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

# Remove "@<" and "@>"
sed -i 's/@<//g' $RECORDS
sed -i 's/@>//g' $RECORDS

## Fix the items

# sed -i 's/*000/*/' $ITEMS

# Replace \r\n with \n
perl -pi -e '$/=undef; s/\r\n/\n/g' $ITEMS

# Replace new line + dollar with just dollar
perl -pi -e '$/=undef; s/\n\$/\$/g' $ITEMS

## Fix the links

# Replace \r\n with \n
perl -pi -e '$/=undef; s/\r\n/\n/g' $LINKS

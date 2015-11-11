#!/bin/bash

cd "/path/to/data"

if [ ! -d "out/" ]; then
    mkdir "out/"
fi

ORIG_RECORDS="x-objektposter.txt"
ORIG_ITEMS="x-dokumentposter.txt"
RECORDS="records.txt"
ITEMS="items.txt"
TMP_REC="records.marcxml"
OUT="out/x.marcxml"

# Delete the byproducts of earlier runs
rm -f $TMP_REC
rm -f $OUT

# Copy original files to working copies
cp $ORIG_RECORDS $RECORDS
cp $ORIG_ITEMS   $ITEMS

echo "*** Running prep.sh... "
/path/to/bibsys2koha/prep.sh $RECORDS $ITEMS
echo "done"

echo "*** Running line2iso.pl"
perl /path/to/libriotools/line2iso.pl -i $RECORDS -e -x > $TMP_REC
echo "Created MARCXML in $TMP_REC"
echo "done"

echo "*** Running items.pl"
perl /path/to/bibsys2koha/items.pl -m $TMP_REC -i $ITEMS --config "/path/to/migration/" -o $OUT -v 
echo "done"

echo "*** Running fix_at_chars.sh"
/path/to/bibsys2koha/fix_at_chars.sh $OUT
echo "done"

echo "*** Beaming up records"
scp $OUT me@my-server.no:/path/to/data/
echo "done"

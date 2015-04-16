#!/bin/bash

# Sometimes, records from BIBSYS have records where non-ASCII chars are 
# represented as @ + ASCII-char. For example:
# Stanis@law v.s. Stanisław
# This script tries to catch as many of those cases as possible
# This script should NEVER be run on an ISO2709 file, since it will mess up 
# the field offsets. MARCXML and line format only! 

if [ "$#" -ne 1 ]; then
  echo "Illegal number of parameters"
  exit
fi

FILE=$1

if [ ! -f $FILE ]; then
   echo "File $FILE does not exists."
   exit
fi

perl -pi -e '$/=undef; s/\@\@/::::::/g' $FILE

perl -pi -e '$/=undef; s/\@l/ł/g' $FILE
perl -pi -e '$/=undef; s/\@L/Ł/g' $FILE

perl -pi -e '$/=undef; s/\@æ/ä/g' $FILE
perl -pi -e '$/=undef; s/\@Æ/Ä/g' $FILE

perl -pi -e '$/=undef; s/\@ø/ö/g' $FILE
perl -pi -e '$/=undef; s/\@Ø/Ö/g' $FILE

perl -pi -e '$/=undef; s/\@y/ü/g' $FILE
perl -pi -e '$/=undef; s/\@Y/Ü/g' $FILE

perl -pi -e '$/=undef; s/\@d/ð/g' $FILE

perl -pi -e '$/=undef; s/\@s/ß/g' $FILE

perl -pi -e '$/=undef; s/\@m/ő/g' $FILE

perl -pi -e '$/=undef; s/\@i/ı/g' $FILE

perl -pi -e '$/=undef; s/\@`/ʿ/g' $FILE
perl -pi -e '$/=undef; s/\@´/ʾ/g' $FILE

perl -pi -e '$/=undef; s/\@b/♭/g' $FILE

perl -pi -e '$/=undef; s/\@%/%/g' $FILE
perl -pi -e '$/=undef; s/\@_/_/g' $FILE
perl -pi -e '$/=undef; s/\@#/#/g' $FILE
perl -pi -e '$/=undef; s/\@S/\$/g' $FILE
perl -pi -e '$/=undef; s/\@0/°/g' $FILE

perl -pi -e '$/=undef; s/::::::/@/g' $FILE

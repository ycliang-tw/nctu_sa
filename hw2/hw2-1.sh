#!/bin/sh
directory="partclone-0.2.89"
cd ${directory}
ls -ARl | awk '{ if(NF == 9) { print $5, "\t", $0 } }' | sort -nr |\
awk 'BEGIN { dir=0; file=0; size=0; count=0 }\
	{\
		if(count < 5){ print ++count, ":", $1, " ", $10 }\
		if($2 ~ /d.*/){ ++dir }\
		if($2 ~ /^-.*/){ ++file; size += $1 }\
	}\
	END { print "Dir num: ", dir, "\nFile num: ", file, "\nTotal: ", size }'

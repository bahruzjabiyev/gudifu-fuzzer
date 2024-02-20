#!/bin/bash

grep ":-;)" $1 > /tmp/x1 

awk -F"[ ][-]{4}[ ]" '{arr[$2]=$1; if (length(hashes[$2])<200) hashes[$2]=hashes[$2]";"$3} END {for (key in arr) print key"©©©©"arr[key]"©©©©"hashes[key]}' /tmp/x1 > /tmp/x2 

sort /tmp/x2 | uniq -c | sort -rn | sed 's/^\s*//' | sed 's/ b/©©©©b/1' > /tmp/x3 

#awk -F "[©]{4}" '{print length($2)","$0}' /tmp/x3 | sort -t, -k1,1n | sed 's/©©©©/   /g' | sed -z "s/\n/\n\n/g"
awk -F "[©]{4}" '{print length($2)","$0}' /tmp/x3 | sort -t, -k1,1n | sed -z "s/\n/\n\n/g"

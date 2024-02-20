#!/bin/bash
# look-additions

awk -F"[©]{4}" '{print $3}' $1 | sed 's/[0-9]\+/NUM/g' | sort | uniq -c | sort -rn > /tmp/zzzz
sed 's/^[ ]*[0-9]\+..//;s/.$//' /tmp/zzzz | grep ";" > /tmp/zzz
mv /tmp/zzz /tmp/zzzz
for i in $(seq 1 $(wc -l /tmp/zzzz | cut -d" " -f1)); do 
  s=$(head -$i /tmp/zzzz | tail -1)
  cat $1 | sed 's/:[0-9]\+;/:NUM;/g' | grep "©.$s.©" | sed 's/©/ /g'
  echo
  echo
done


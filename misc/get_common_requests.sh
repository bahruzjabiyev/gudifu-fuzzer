#!/bin/bash

logsdir=$1 #should not end with a slash
outdir=$2 #should not end with a slash
echo "Getting the list of files... "
ls $logsdir > /tmp/file_list #orig 

echo "Getting the good hashes... "
cat /tmp/file_list | cut -d"_" -f2 | sort | uniq -c | awk '$1>2 && length($2)==40 {print $2}' > $outdir/good_hashes #orig
echo "Getting the hashes for which no input info is available..."
echo > /tmp/noinput_hashes
for hash in $(cat $outdir/good_hashes); do if (ls $logsdir/input_$hash 2>&1 | grep -q "No such file"); then echo $hash >> /tmp/noinput_hashes;fi;done

cat $outdir/good_hashes $outdir/good_hashes /tmp/noinput_hashes | sort | uniq -c | awk '$1==2 {print $2}' > /tmp/temp; mv /tmp/temp $outdir/good_hashes

echo "Splitting hashes into 100 parts ..."
split -l$((`wc -l < $outdir/good_hashes`/100)) $outdir/good_hashes $outdir/good_hashes.part -da 4

echo "Copying input and forwarded requests to $outdir/logs ..."
mkdir -p $outdir/logs 

for file in $(ls $outdir/*part*); do
  for hash in $(cat $file); do for server in input apache nginx h2o ats haproxy envoy; do cp $logsdir/${server}_$hash $outdir/logs 2>/dev/null; done;done &
done

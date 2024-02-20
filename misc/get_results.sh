#!/bin/bash

logsdir=$1 #should not end with a slash
outdir=$2 #should not end with a slash

echo "Getting the buckets..."
mkdir -p $outdir/results
for action in additions deletions modifications line-modifications body-modifications; do
  echo "now getting the $action ..."
  python3 compare.py $outdir/logs/ $action > $outdir/results/raw-$action
  bash look.sh $outdir/results/raw-$action > $outdir/results/look-$action
  bash bucket.sh $outdir/results/look-$action > $outdir/results/see-$action
done

echo "Copying cacheable error responses and requests to $outdir/logs ..."
find $logsdir -name "error*" -o -name "response*" | xargs -I file cp file $outdir/logs
echo "Done."

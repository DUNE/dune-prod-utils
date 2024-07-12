#!/bin/bash

check_cvmfs() {
  a=2
  i=0
  while [ $i -le ${maxiter:-100} ]; do
    stat $1 > /dev/null 2>&1 
    if [ $? == 0 ]; then
      echo "Found in RCDS"
      break
    fi

    echo "iter $i"
    echo "File not found in RCDS"
    echo "sleeping $a"
    sleep $a
    a=$((2*a))
  done
}

hour=$(date -u +"%H")

today="$(date -u +"%Y%m%d")"

if [ "$hour" -ge 12 ]; then
  roundhour=12
  iter=1
else
  roundhour=00
  iter=0
fi

endhr=$(( $roundhour + 12 ))
begin="$(date -u +"%Y-%m-%d")T${roundhour}00"
end="$(date -u +"%Y-%m-%d")T${endhr}00"
endfind="$(date -d '+2 day' -u +"%Y%m%d")"

echo now: $(date)
echo begin: $begin
echo end: $end
echo endfind: $endfind

query="files where core.run_type=hd-protodune and core.file_type=detector and core.data_tier=raw and created_timestamp >= ${begin} and created timestamp < ${end}"
jobscript="protodunehd_split_stage_keepup.jobscript"
desc="PDHD Keepup (${begin} -- ${end})"
scope=${scope:-"hd-protodune-det-reco"}
maxwall="$(( 3600*5 ))"
recopattern="*keepup.root:hd-protodune_reconstruction_keepup_${today}_set${iter}_v09_91_02d00_v0"
ntuplepattern="*hists.root:hd-protodune_reconstruction_keepup_ntuples_${today}_set${iter}_v09_91_02d00_v0"
rssmb=3999

echo "Setting up python and justin"
setup python v3_9_15
setup justin

#echo "Uploading metadata.tar"
#metadata_dir=`justin-cvmfs-upload /exp/dune/app/users/calcuttj/data-mgmt-ops/utilities/metadata.tar` 
metadata_dir=/cvmfs/fifeuser2.opensciencegrid.org/sw/dune/71f643ddd59465043e3cd3712a1e24b9cd0fa631
#echo "Uploaded to $metadata_dir"

echo "Checking cvmfs"
maxiter=500
check_cvmfs $metadata_dir
if [ $? -ne 0 ]; then
  "Could not find in cvmfs. Exiting"
  return 1
fi

echo "Found in cvmfs"

echo
echo "Will execute"
echo justin simple-workflow \
  --jobscript $jobscript \
  --description $desc --scope $scope \
  --mql $query --refind-end-date $endfind \
  --refind-interval-hours 1 --wall-seconds $maxwall \
  --rss-mb $rssmb --max-distance 30 \
  --output-pattern ${recopattern}'_$JUSTIN_WORKFLOW_ID' \
  --output-pattern ${ntuplepattern}'_$JUSTIN_WORKFLOW_ID' \
  --env "METADATA_DIR=$metadata_dir" \
  --lifetime-days 90 \
  --classad HAS_CVMFS_dune_osgstorage_org=true

echo justin simple-workflow \
  --jobscript $jobscript \
  --description "$desc" --scope $scope \
  --mql "$query" --refind-end-date $endfind \
  --refind-interval-hours 1 --wall-seconds $maxwall \
  --rss-mb $rssmb --max-distance 30 \
  --output-pattern ${recopattern}'_$JUSTIN_WORKFLOW_ID' \
  --output-pattern ${ntuplepattern}'_$JUSTIN_WORKFLOW_ID' \
  --env "METADATA_DIR=$metadata_dir" \
  --lifetime-days 90 \
  --classad HAS_CVMFS_dune_osgstorage_org=true 

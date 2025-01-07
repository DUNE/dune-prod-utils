#!/bin/bash

check_cvmfs() {
  a=2
  i=0
  while [ $i -le ${maxiter:-10} ]; do
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
    i=$((i+1))
  done
}

scope=${1}
extra=${2:-""}
echo "scope $scope"
echo "extra $extra"

hour=$(date -u +"%H")
#convert to central (by hand because I couldn't get it to work)
hour=$(( $hour - 5 ))
echo "Hour: $hour"

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

## TODO -- ADD IN 'dune.daq_test=False'
query="files where created_timestamp >= ${begin} and created_timestamp < ${end} and core.run_type=hd-protodune and core.file_type=detector and core.data_tier=raw and core.data_stream in (physics, cosmics)"
jobscript="/exp/dune/app/users/calcuttj/dune-prod-utils/production-scripts/data/PDHD/keepup_july_2024/protodunehd_split_stage_keepup.jobscript"
desc="PDHD Keepup (${begin} -- ${end})"
#scope=${scope:-"hd-protodune-det-reco"}
maxwall="$(( 3600*5 ))"
recopattern="*keepup.root:hd-protodune_reconstruction_keepup_${today}_set${iter}_v09_91_02d01_v0"
ntuplepattern="*hists.root:hd-protodune_reconstruction_keepup_ntuples_${today}_set${iter}_v09_91_02d01_v0"
rssmb=3999

source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
echo "Setting up python and justin"
setup python v3_9_15
setup justin
##For getting managed tokens
export HTGETTOKENOPTS="--credkey=dunepro/managedtokens/fifeutilgpvm01.fnal.gov --nooidc --nokerberos -r production"
htgettoken -a htvaultprod.fnal.gov -i dune $HTGETTOKENOPTS

echo "Uploading metadata.tar"
metadata_dir=`justin-cvmfs-upload /exp/dune/app/users/calcuttj/data-mgmt-ops/utilities/metadata.tar` 
if [ $? -ne 0 ]; then
  echo "Could not upload. Exiting"
  exit 1
fi 
#metadata_dir=/cvmfs/fifeuser2.opensciencegrid.org/sw/dune/71f643ddd59465043e3cd3712a1e24b9cd0fa631
#echo "Uploaded to $metadata_dir"

echo "Checking cvmfs"
maxiter=10
check_cvmfs $metadata_dir
if [ $? -ne 0 ]; then
  echo "Could not find in cvmfs. Exiting"
  exit 1
fi

#extra=${extra:-""}

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
  --classad HAS_CVMFS_dune_osgstorage_org=true $extra 

justin simple-workflow \
  --jobscript $jobscript \
  --description "$desc" --scope $scope \
  --mql "$query" --refind-end-date $endfind \
  --refind-interval-hours 1 --wall-seconds $maxwall \
  --rss-mb $rssmb --max-distance 30 \
  --output-pattern ${recopattern}'_$JUSTIN_WORKFLOW_ID' \
  --output-pattern ${ntuplepattern}'_$JUSTIN_WORKFLOW_ID' \
  --env "METADATA_DIR=$metadata_dir" \
  --lifetime-days 90 \
  --classad HAS_CVMFS_dune_osgstorage_org=true  $extra 


echo $?

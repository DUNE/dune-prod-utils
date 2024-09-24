#!/bin/bash

##Defines check_cvmfs
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

source utils.sh

iter=${1}
date="${2}"
if [ $iter -eq 0 ]; then
  t0="${date}T0000"
  t1="${date}T1200"
else
  t0="${date}T1200"
  t1="${date}T2400"
fi

workflow=${3}
scope=${4}
extra=${5:-""}

echo "t0 $t0"
echo "t1 $t1"
echo "workflow $workflow"
echo "scope $scope"
echo "extra $extra"


export HTGETTOKENOPTS="--credkey=dunepro/managedtokens/fifeutilgpvm01.fnal.gov --nooidc --nokerberos -r production"
htgettoken -a htvaultprod.fnal.gov -i dune $HTGETTOKENOPTS

query="files where created_timestamp >= ${t0} and created_timestamp < ${t1} and core.run_type=hd-protodune and core.file_type=detector and core.data_tier=raw and core.data_stream in (physics, cosmics)"

if [ $workflow -ne 0 ]; then
  query="$query - parents(files from hd-protodune-det-reco:hd-protodune_reconstruction_keepup_${date}_set${iter}_v09_91_02d01_v0_${workflow} where dune.output_status=confirmed)"
fi

jobscript="/exp/dune/app/users/calcuttj/dune-prod-utils/production-scripts/data/PDHD/keepup_july_2024/protodunehd_split_stage_keepup.jobscript"
desc="PDHD makeup (${t0} -- ${t1}), workflow: $workflow"
maxwall="$(( 3600*5 ))"
today="$(date -u +"%Y%m%d")"
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
  --mql $query --wall-seconds $maxwall \
  --rss-mb $rssmb --max-distance 30 \
  --output-pattern ${recopattern}'_$JUSTIN_WORKFLOW_ID' \
  --output-pattern ${ntuplepattern}'_$JUSTIN_WORKFLOW_ID' \
  --env "METADATA_DIR=$metadata_dir" \
  --lifetime-days 90 \
  --classad HAS_CVMFS_dune_osgstorage_org=true $extra 

justin simple-workflow \
  --jobscript $jobscript \
  --description "$desc" --scope $scope \
  --mql "$query" --wall-seconds $maxwall \
  --rss-mb $rssmb --max-distance 30 \
  --output-pattern ${recopattern}'_$JUSTIN_WORKFLOW_ID' \
  --output-pattern ${ntuplepattern}'_$JUSTIN_WORKFLOW_ID' \
  --env "METADATA_DIR=$metadata_dir" \
  --lifetime-days 90 \
  --classad HAS_CVMFS_dune_osgstorage_org=true  $extra 


echo $?

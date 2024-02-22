#!/bin/bash
:<<'EOF'
Create a request to justIN with something like:

justin quick-request --monte-carlo 10 --output-rse DUNE_US_FNAL_DISK_STAGE \
 --jobscript your.jobscript --rss-mb 4000 \
 --scope usertests \
 --output-pattern '*_*_gen_g4_detsim_hitreco.root:output-test-01' \
 --output-pattern '*.logs.tgz:output-test-01'
EOF

date -u +"%Y-%m-%d %H:%M:%S Start jobscript"

export CLUSTER=`echo $JUSTIN_JOBSUB_ID | cut -f1 -d.`
export PROCESS=`echo $JUSTIN_JOBSUB_ID | cut -f1 -d@ | cut -f2 -d.`

export POMS4_CAMPAIGN_STAGE_ID=POMS4_CAMPAIGN_STAGE_IDVAR
export POMS4_CAMPAIGN_STAGE_NAME=POMS4_CAMPAIGN_STAGE_NAMEVAR
export POMS4_CAMPAIGN_STAGE_TYPE=POMS4_CAMPAIGN_STAGE_TYPEVAR
export POMS4_CAMPAIGN_ID=POMS4_CAMPAIGN_IDVAR
export POMS4_CAMPAIGN_NAME=POMS4_CAMPAIGN_NAMEVAR
export POMS4_SUBMISSION_ID=POMS4_SUBMISSION_ID
export POMS4_CAMPAIGN_ID=POMS4_CAMPAIGN_IDVAR
export POMS4_TEST_LAUNCH=POMS4_TEST_LAUNCHVAR
export POMS_CAMPAIGN_ID=POMS_CAMPAIGN_IDVAR
export POMS_CAMPAIGN_NAME=POMS_CAMPAIGN_NAMEVAR
export POMS_PARENT_TASK_ID=POMS_PARENT_TASK_IDVAR
export POMS_TASK_ID=POMS_TASK_IDVAR
export POMS_LAUNCHER=POMS_LAUNCHERVAR
export POMS_TEST=POMS_TESTVAR
export POMS_TASK_DEFINITION_ID=POMS_TASK_DEFINITION_IDVAR
export JOBSUB_GROUP=JOBSUB_GROUPVAR
export GROUP=GROUPVAR

for myvar in POMS4_CAMPAIGN_STAGE_ID POMS4_CAMPAIGN_STAGE_NAME POMS4_CAMPAIGN_STAGE_TYPE POMS4_CAMPAIGN_ID POMS4_CAMPAIGN_NAME POMS4_SUBMISSION_ID POMS4_TEST_LAUNCH POMS_CAMPAIGN_ID POMS_CAMPAIGN_NAME POMS_PARENT_TASK_ID POMS_TASK_ID POMS_LAUNCHER POMS_TEST POMS_TASK_DEFINITION_ID JOBSUB_GROUP GROUP
do
    eval pomsattr=\$${myvar}
    if [ -z "$pomsattr" ]; then continue ; fi
    condor_chirp set_job_attr $myvar $pomsattr
done



did_pfn_rse=$($JUSTIN_PATH/justin-get-file)
if [ "$did_pfn_rse" = "" ] ; then
  echo Nothing to do - exiting
  exit 0
fi
echo "Allocated $did_pfn_rse"
justin_pfn=$(echo $did_pfn_rse | cut -f2 -d' ')

(

#!/bin/bash

ARGS="$@"

fife_launch --dry_run $ARGS   | sed -r -e "/\=\=\=\=\=/ d" -e "/^\-\-\-\-\-$/ d" -e "/I would clean up/ d" -e "/^\[.*lar.*\]/ d" > justIN_core_better_name_later.sh

# extra massaging of the dry run output
sed -i -n -e '/# setup commands:/,/^exit \$rres/ {/# setup commands:/d; /^exit \$rres/d; p;}' justIN_core_better_name_later.sh

cat justIN_preamble.sh justIN_core_better_name_later.sh justIN_closing.sh > justIN_script_better_name_later.sh

# edit in the actual values for the various POMS variables
for myvar in POMS4_CAMPAIGN_STAGE_ID POMS4_CAMPAIGN_STAGE_NAME POMS4_CAMPAIGN_STAGE_TYPE POMS4_CAMPAIGN_ID POMS4_CAMPAIGN_NAME POMS4_SUBMISSION_ID POMS4_TEST_LAUNCH POMS_CAMPAIGN_ID POMS_CAMPAIGN_NAME POMS_PARENT_TASK_ID POMS_TASK_ID POMS_LAUNCHER POMS_TEST POMS_TASK_DEFINITION_ID JOBSUB_GROUP GROUP
do
eval tmpvar=\$$myvar
sed -i -e "s/${myvar}VAR/${tmpvar}" justIN_script_better_name_later.sh
done


# Is there an easier way to get dataset here?
outname=`grep '^#outname=' justIN_script_better_name_later.sh | cut -d= -f2`
splitname=`echo $outname | sed 's/_dune.*//'`
fdmodule=`echo "$POMS4_CAMPAIGN_STAGE_NAME" | cut -f1 -d_ | tr "[:upper:]" "[:lower:]"`
jobscript=${fdmodule}_${splitname}.jobscript
cp justIN_script_better_name_later.sh $jobscript

echo "Debugging: Here is the jobscript for justIN"
echo
echo "--- Start $PWD/$jobscript ---"
cat $jobscript
echo "--- End $PWD/$jobscript ---"
echo
echo "Now I will try to actually run the justIN command, which is:"
echo
echo "justin quick-request --monte-carlo 1 --jobscript $PWD/$jobscript --description '${POMS4_CAMPAIGN_NAME}-${fdmodule}_${splitname}' --rss-mb 6000 --output-rse DUNE_US_FNAL_DISK_
STAGE --scope fardet-${fdmodule} --lifetime-days 365 --output-pattern '*_*_gen_g4_detsim_hitreco.root:fardet-${fdmodule}_'${JUSTIN_REQUEST_ID}'"
echo

justin quick-request --monte-carlo 1 --jobscript $PWD/$jobscript --description "${POMS4_CAMPAIGN_NAME}-${fdmodule}_${splitname}" --rss-mb 6000 --output-rse DUNE_US_FNAL_DISK_STAGE --scope fardet-${fdmodule} --lifetime-days 365 --output-pattern '*_*_gen_g4_detsim_hitreco.root:fardet-'${fdmodule}'_${JUSTIN_REQUEST_ID}'

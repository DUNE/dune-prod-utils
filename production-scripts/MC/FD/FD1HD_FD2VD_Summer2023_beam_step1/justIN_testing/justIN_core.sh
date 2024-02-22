#!/bin/bash

ARGS="$@"

fife_launch --dry_run $ARGS   | sed -r -e "/\=\=\=\=\=/ d" -e "/^\-\-\-\-\-$/ d" -e "/I would clean up/ d" -e "/^\[.*lar.*\]/ d" > justIN_core_better_name_later.sh

# extra massaging of the dry run output
sed -i -n -e '/# setup commands:/,/^exit \$rres/ {/# setup commands:/d; /^exit \$rres/d; p;}' justIN_core_better_name_later.sh

cat justIN_preamble.sh justIN_core_better_name_later.sh justIN_closing.sh > justIN_script_better_name_later.sh

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
echo "Now I would do"
echo
echo "justin quick-request --monte-carlo 1 \\"
echo "  --jobscript $PWD/$jobscript \\"
echo "  --description '${POMS4_CAMPAIGN_NAME}-${fdmodule}_${splitname}' \\"
echo "  --rss-mb 6000 \\"
echo "  --output-rse DUNE_US_FNAL_DISK_STAGE \\"
echo "  --scope fardet-${fdmodule} \\"
echo "  --lifetime-days 365 \\"
echo "  --output-pattern '*_*_gen_g4_detsim_hitreco.root:fardet-${fdmodule}_\${JUSTIN_REQUEST_ID}' "
echo
echo


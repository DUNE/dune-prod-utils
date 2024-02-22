if [ $rres = 0 ] ;  then
  echo "$justin_pfn" > justin-processed-pfns.txt
fi
exit $rres
) > application.log 2>&1
rres=$?

tail -100 application.log

date -u +"%Y-%m-%d %H:%M:%S End jobscript with code $rres"
tar zcf `echo "$JUSTIN_JOBSUB_ID.logs.tgz" | sed 's/@/_/g'` *.log
exit $rres 

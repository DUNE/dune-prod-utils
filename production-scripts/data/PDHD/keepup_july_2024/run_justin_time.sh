#!/bin/bash
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
echo "Setting up python and justin"
setup python v3_9_15
setup justin
##For getting managed tokens
export HTGETTOKENOPTS="--credkey=dunepro/managedtokens/fifeutilgpvm01.fnal.gov --nooidc --nokerberos -r production"
htgettoken -a htvaultprod.fnal.gov -i dune $HTGETTOKENOPTS
justin time
echo $?

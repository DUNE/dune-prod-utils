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



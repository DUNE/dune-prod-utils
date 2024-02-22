#!/usr/bin/env python
import sys
import os
import json
import samweb_client
import subprocess
import argparse
import urllib3
import re
import string

ftsurl='http://dunesamgpvm01.fnal.gov:8787/fts/status'
myhttp = urllib3.PoolManager(ca_certs='/etc/grid-security/certificates/InCommon-IGTF-Server-CA.pem')
r=myhttp.request('GET', ftsurl, fields={'format':'json'})

if r.status == 200:

    myjson = json.loads(r.data.decode('utf-8'))
    errordict=myjson['errorstates']
    nomdfile = open("no_metadata.txt","w")
    mismatchfile = open("size_mismatches.txt","w")
    for i in range(0, len(errordict)):
        if errordict[i]["msg"][0:18] == "File size mismatch":
            fixfile=errordict[i]["msg"]
            fname=fixfile[fixfile.find('/'):fixfile.find(':')]
            mismatchfile.write(fname + '\n')
            #        subprocess.call(['./extractor_prod.py','--infile',fixfile,'--strip_parents','--appname','detsim','--appversion','v06_84_00','--declare']
        elif errordict[i]["msg"][0:11] == "No metadata":
            fixfile=errordict[i]["msg"][21:]
            nomdfile.write(fixfile + '\n')
    nomdfile.close()
    mismatchfile.close()
    # file exists errors
    ftdict=myjson['failedtransferstates']
    ftfile=open('failedxfer.txt','w')
    myre = re.compile('enstore:/.*\s')
    for ft in ftdict:
        if "File exists" in ft['msg']:
            loc=myre.search(ft['msg'])
            outstr=(loc.group(0).rstrip('\n')).rstrip(' failed') + '/' + ft['name']
            outstr = outstr.lstrip('enstore:')
            ftfile.write(outstr + '\n')
    ftfile.close()
else:
    print('Error contacting FTS (status code %d). Not doing anything.' % r.status )
    sys.exit(1)

#!/bin/bash

# assume samweb is already set up
# Note that this script removes ALL copies of a file known to SAM, if directly accessible with "rm"

myfile=$1
basefile=$(basename $myfile)
for child in $(samweb file-lineage children $basefile)
do
    for loc in $(samweb locate-file $child)
    do
        path=$(echo $loc | cut -d ":" -f 2 | cut -d "(" -f 1)
        samweb remove-file-location $child $loc
        rm -f ${path}/${child}
    done
    samweb retire-file $child
done

#finish the children, now do the main file. Check for corresponding .pndr file if reco
pandorafile=$(echo $basefile | sed -e "s/.root/_Pandora_Events.pndr/")
pndrmd=$(samweb get-metadata $pandorafile)
if [ $? -eq 0 ]; then
    # there is a file, delete it too
    for loc in $(samweb locate-file $pandorafile)
    do
        path=$(echo $loc | cut -d ":" -f 2 | cut -d "(" -f 1)
        samweb remove-file-location $pandorafile $loc
        rm -f ${path}/${pandorafile}
    done
    samweb retire-file $pandorafile
fi
#finally retire the file itself

for loc in $(samweb locate-file $basefile)
do
    path=$(echo $loc | cut -d ":" -f 2 | cut -d "(" -f 1)
    samweb remove-file-location $basefile $loc
    rm -f ${path}/${basefile}
done
samweb retire-file $basefile

# delete original path, if still existing
if [ -f $myfile ]; then
    rm -f $myfile
fi

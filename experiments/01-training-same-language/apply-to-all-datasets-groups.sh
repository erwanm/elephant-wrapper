#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <output dir>"
    exit 1
fi
workDir="$1"

[ -d "$workDir" ] || mkdir "$workDir"

expeDir="experiments/01-training-same-language/"
udCorpus="ud-treebanks-v2.1/"

for datasetFile in "$expeDir"/*.datasets; do
    name=$(basename "${datasetFile%.datasets}")
    comm="$expeDir/apply-model-same-language.sh -e 8 \"$datasetFile\" \"$udCorpus\" \"$workDir/$name\""
    eval "$comm"
done

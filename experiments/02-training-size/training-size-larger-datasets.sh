#!/bin/bash



progName=$(basename "$BASH_SOURCE")

scriptDir=$(dirname "$BASH_SOURCE")
# assuming that the script is in some directory xxx/bin, and the default model dir is xxx/models
if [ -d "$scriptDir/../models" ]; then 
    defaultModelDir="$scriptDir/../models"
else
    defaultModelDir="./models"
fi

delayed=""


function usage {
  echo
  echo "Usage: $progName [options] <UD2.1 dataset dir> <top N datasets> <nb samples> <output dir>"
  echo
  echo "  This script can be used to reproduce the 'varying training size'"
  echo "  experiment presented in the corresponding LREC 2018 paper."
  echo "  Applies the 'varying training size' script to the N largest"
  echo "  datasets (in sentences) in the UD dir which contain both train"
  echo "  and test set."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -d delay execution, instead just print the commands to STDOUT"
  echo "       so that commands can be run in parallel."
  echo
}



OPTIND=1
while getopts 'dh' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"d" ) delayed="yep";;
 	"?" ) 
	    echo "Error, unknow option." 1>&2
            printHelp=1;;
    esac
done
shift $(($OPTIND - 1))
if [ $# -ne 4 ]; then
    echo "Error: expecting 4 args." 1>&2
    printHelp=1
fi


if [ ! -z "$printHelp" ]; then
    usage 1>&2
    exit 1
fi
inputDir="$1"
nbDatasets="$2"
nbSamples="$3"
workDir="$4"

if [ ! -d "$inputDir" ]; then
    echo "Error: '$inputDir' not found" 1>&2
    exit 3
fi

[ -d "$workDir" ] || mkdir "$workDir"


# get datasets size in sentences
for f in "$inputDir"/*/*-train.conllu; do
    size=$(cat "$f" | grep "^1\s" | wc -l)
    echo -e "$f\t$size"
done | sort -k 2,2rn >"$workDir/size-datasets.txt"

# extract N largest
head -n "$nbDatasets" "$workDir/size-datasets.txt" | sed -e "s:$inputDir/::g" -e "s:/[^/]*train.conllu::g" >"$workDir/selected-datasets.txt"

# min size among selected
size=$(tail -n 1 "$workDir/selected-datasets.txt" | cut -f 2)
nbSent=$(( $size / $nbSamples ))

echo "Smallest size in largest $nbDatasets datasets = $size; using $nbSamples samples of size $nbSent" 1>&2

cat "$workDir/selected-datasets.txt" | cut -f 1 | while read dataset; do
    echo "$dataset..." 1>&2
    comm="$scriptDir/vary-training-size.sh \"$inputDir/$dataset\" \"$nbSamples\" \"$nbSent\" \"$workDir/$dataset\""
    if [ -z "$delayed" ]; then
	eval "$comm"
    else
	echo "$comm"
    fi
done


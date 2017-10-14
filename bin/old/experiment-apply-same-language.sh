#!/bin/bash



progName=$(basename "$BASH_SOURCE")

iobOpt=""

function usage {
  echo
  echo "Usage: $progName [options] <UD input dir> <expe dir with models> <language> <pattern id> <output directory>"
  echo
  echo
  echo "  Options:"
  echo "    -h this help"
  echo
}




OPTIND=1
while getopts 'h' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
 	"?" ) 
	    echo "Error, unknow option." 1>&2
            printHelp=1;;
    esac
done
shift $(($OPTIND - 1))
if [ $# -ne 5 ]; then
    echo "Error: expecting 5 args." 1>&2
    printHelp=1
fi

if [ ! -z "$printHelp" ]; then
    usage 1>&2
    exit 1
fi
inputDir="$1"
expeDir="$2"
lang="$3"
patternId="$4"
outputDir="$5"

rm -rf $outputDir
[ -d "$outputDir" ] || mkdir "$outputDir"

for dataDir1 in "$inputDir"/UD_$lang*; do
    data1=$(basename "$dataDir1")
    modelDir="$expeDir/$data1/$patternId/elman.model"
    for dataDir2 in "$inputDir"/UD_$lang*; do
	data2=$(basename "$dataDir2")
	testFile=$(ls $dataDir2/*dev*.conllu)
	echo "### applying $data1 model to $data2 test set"
	apply-tokenizer-to-UD-corpus.sh -i "$testFile" "$modelDir" "$outputDir/test-${data2}-train-${data1}.out"
    done
done


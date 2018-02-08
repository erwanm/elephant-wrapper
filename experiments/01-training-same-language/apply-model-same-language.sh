#!/bin/bash



progName=$(basename "$BASH_SOURCE")

scriptDir=$(dirname "$BASH_SOURCE")
# assuming that the script is in some directory xxx/bin, and the default model dir is xxx/models
if [ -d "$scriptDir/../models" ]; then 
    defaultModelDir="$scriptDir/../models"
else
    defaultModelDir="./models"
fi

paramsModelName="elephant"
iso639File="iso639-codes.txt"

evalCol=4  # value to select: accuracy
printPerfPattern="%.3f"

function usage {
  echo
  echo "Usage: $progName [options] <datasets file> <UD2.1 dir> <output dir>"
  echo
  echo "  This script can be used to reproduce the 'same language, different dataset'"
  echo "  experiment presented in the corresponding LREC 2018 paper."
  echo "  The input file contains the names of datasets/models in a given language."
  echo "  Each of the models is going to be applied to each of the test sets."
  echo "  Results written in <output dir>."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -n <parameters model name> name to use for the parameters model directory,"
  echo "       in case there are several alternatives. Default: '$paramsModelName'."
  echo "    -e <eval column> no of evaluation output column to use; default=$evalCol;"
  echo "       (see evaluate.pl -h)"
  echo "    -p <printf perf pattern> default: $printPerfPattern."
  echo
}


function findModelDir {
    local name="$1"

    if [ -s "$name/$paramsModelName.elephant-model" ]; then
	echo "$d/$paramsModelName.elephant-model"
    else
	if [ -d "$defaultModelDir/$name/$paramsModelName.elephant-model" ]; then
	    echo "$defaultModelDir/$name/$paramsModelName.elephant-model"
	else
	    echo "Error: model dir '$name' not found (or does not contain an elephant model '$paramsModelName.elephant-model')" 1>&2
	    exit 5
	fi
    fi
	
}




OPTIND=1
while getopts 'hn:e:p:' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
        "n" ) paramsModelName="$OPTARG";;
	"e" ) evalCol="$OPTARG";;
	"p" ) printPerfPattern="$OPTARG";;
 	"?" ) 
	    echo "Error, unknow option." 1>&2
            printHelp=1;;
    esac
done
shift $(($OPTIND - 1))
if [ $# -ne 3 ]; then
    echo "Error: expecting 3 args." 1>&2
    printHelp=1
fi


if [ ! -z "$printHelp" ]; then
    usage 1>&2
    exit 1
fi
datasetsFile="$1"
dataUD="$2"
workDir="$3"

if [ ! -e "$datasetsFile" ]; then
    echo "Error: '$datasetsFile' not found or empty" 1>&2
    exit 3
fi

[ -d "$workDir" ] || mkdir "$workDir"

# print title row
echo -en "TrainingSet" >"$workDir/perf.out"
cat "$datasetsFile" | while read dataset; do
    echo -en "\t$dataset"
done >>"$workDir/perf.out"
echo >>"$workDir/perf.out"

cat "$datasetsFile" | while read datasetTrain; do
    echo -en "$datasetTrain"
    cat "$datasetsFile" | while read datasetTest; do
	echo "TRAIN: $datasetTrain; TEST: $datasetTest" 1>&2
	trainDir=$(findModelDir "$datasetTrain")
	testFile=$(ls "$dataUD/$datasetTest"/*test*.conllu | tail -n 1)
	output="$workDir/$datasetTrain-$datasetTest.out"
	tokenize.sh -q -i "$testFile" -c -I -o "$output" "$trainDir"
	rm -f "$workDir/$datasetTrain-$datasetTest.out" # no need for the actual tokenized text normally
	perf=$(cat "$output.eval" | cut -f $evalCol)
	printf "\t$printPerfPattern" $perf
    done
    echo
done >> "$workDir/perf.out"

cat "$workDir/perf.out"

echo "Done, result perf table in '$workDir/perf.out'"

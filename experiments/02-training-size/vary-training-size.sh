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
printPerfPattern="%.5"

function usage {
  echo
  echo "Usage: $progName [options] <UD2.1 dataset dir> <nb samples> <nb sentences/sample> <output dir>"
  echo
  echo "  This script can be used to reproduce the 'varying training size'"
  echo "  experiment presented in the corresponding LREC 2018 paper."
  echo "  The first argument is a single dataset directory from the UD2.1 data."
  echo "  The dataset is split into <nb samples> parts, each contanining"
  echo "  <nb sentences/sample> sentences. The training/testing process is"
  echo "  performed by adding one sample at a time to the training set."
  echo "  This script must be run from the elephant-wrapper directory, so that"
  echo "  the pattern for each dataset can be found in the models dir."
  echo "  Results written to <output dir>."
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
if [ $# -ne 4 ]; then
    echo "Error: expecting 4 args." 1>&2
    printHelp=1
fi


if [ ! -z "$printHelp" ]; then
    usage 1>&2
    exit 1
fi
datasetDir="$1"
nbSamples="$2"
nbSentencesBySample="$3"
workDir="$4"

if [ ! -d "$datasetDir" ]; then
    echo "Error: '$datasetDir' not found" 1>&2
    exit 3
fi

[ -d "$workDir" ] || mkdir "$workDir"

data=$(basename "$datasetDir")

trainFile=$(ls "$datasetDir"/*train*.conllu | tail -n 1)
testFile=$(ls "$datasetDir"/*test*.conllu | tail -n 1)
if [ -z "$trainFile" ] || [ -z "$testFile" ] ; then
    echo "Error: not able to find train and/or test file in '$datasetDir'" 1>&2
    exit 4
fi

# find pattern in models
modelDir=$(findModelDir $(basename "$datasetDir"))
patternFile=$(ls "$modelDir"/*.pat | tail -n 1)
if [ -z "$patternFile" ]; then
    echo "Error: cannot find pattern to use for training in '$modelDir'" 1>&2
    exit 5
fi
if echo  "$patternFile" | grep "E1" >/dev/null; then
    elman=1
else
    elman=0
fi

# split
maxSize=$(( $nbSamples * $nbSentencesBySample ))
comm="split-conllu-sentences.pl -c \"$maxSize\" -b $workDir/sample. -a .conllu $nbSamples $trainFile"
eval "$comm"

totalSent=0
echo -e "dataset\tno\tnbSentences\telman\tperf" >"$workDir/results.tsv"
# train/test
trainFile=$(mktemp --tmpdir "tmp.$progName.train.XXXXXXXXX")
for sampleFile in $workDir/sample.*.conllu; do
#    echo "$sampleFile..." 1>&2
    cat "$sampleFile" >>"$trainFile"
    no=$(basename ${sampleFile%.conllu})
    no=${no#sample.}
    elmanModel=$(mktemp --tmpdir "tmp.$progName.elman.XXXXXXXXX")
    if [ $elman -eq 1 ]; then
	comm="train-lm-from-UD-corpus.sh -q \"$trainFile\" \"$elmanModel\""
	eval "$comm"
	if [ ! -s "$elmanModel" ]; then
	    echo "$comm"
	    echo "Bug: no Elman model computed" 1>&2
	    exit 7
	fi
	opts="-e \"$elmanModel\""
    fi
    comm="train-tokenizer-from-UD-corpus.sh $opts -q \"$trainFile\" \"$patternFile\" \"$workDir/$no\""
    eval "$comm"
    comm="tokenize.sh -i \"$testFile\" -o \"$workDir/$no.out\" -c -I -q \"$workDir/$no\""
    eval "$comm"
#    rm -rf "$elmanModel" "$workDir/$no" "$workDir/$no.out"
    perf=$(cat "$workDir/$no.out.eval" | cut -f $evalCol)
    totalSent=$(( $totalSent + $nbSentencesBySample ))
    echo -e "$data\t$no\t$totalSent\t$elman\t$perf" >>"$workDir/results.tsv"
done
rm -f "$trainFile" 


#!/bin/bash



progName=$(basename "$BASH_SOURCE")

iobOpt=""

function usage {
  echo
  echo "Usage: $progName [options] <UD directory> <output directory>"
  echo
  echo "  Reads a list of pattern files from STDIN, applies this pattern to all"
  echo "  the directories found in <UD directory>, both with and without Elman model."
  echo "  Corpora are read from <UD directory>/<dataset>/*conllu, using the 'train'"
  echo "  version for training and the 'dev' version for testing."
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
if [ $# -ne 2 ]; then
    echo "Error: expecting 2 args." 1>&2
    printHelp=1
fi

if [ ! -z "$printHelp" ]; then
    usage 1>&2
    exit 1
fi
inputDir="$1"
outputDir="$2"

rm -rf $outputDir
[ -d "$outputDir" ] || mkdir "$outputDir"

while read patternFile; do
    p=$(basename "$patternFile")
    for dataDir in "$inputDir"/*; do
	echo "PATTERN=$p ; DATA=$dataDir"
	if [ -d "$dataDir" ]; then
	    data=$(basename "$dataDir")
	    trainFile=$(ls $dataDir/*train*.conllu)
	    ignore=""
	    if [ -z "$trainFile" ]; then
		ignore="train"
	    fi
	    testFile=$(ls $dataDir/*dev*.conllu)
	    if [ -z "$testFile" ]; then
		ignore="dev"
	    fi
	    if [ -z "$ignore" ]; then
		workDir="$outputDir/$data"
		[ -d "$workDir" ] || mkdir "$workDir"
		if [ ! -s "$workDir/elman.model" ]; then
		    train-lm-from-UD-corpus.sh "$trainFile" "$workDir/elman.model"
		fi
		workDir2="$workDir/$p"
		[ -d "$workDir2" ] || mkdir "$workDir2"
		train-tokenizer-from-UD-corpus.sh "$trainFile" "$patternFile" "$workDir2/crf.model"
		apply-tokenizer-to-UD-corpus.sh -i "$testFile" "$workDir2/crf.model"  "$workDir2/crf.output"
		train-tokenizer-from-UD-corpus.sh -e "$workDir/elman.model" "$trainFile" "$patternFile" "$workDir2/elman.model"
		apply-tokenizer-to-UD-corpus.sh -i "$testFile" "$workDir2/elman.model"  "$workDir2/elman.output"
	    else
		echo "Warning: no $ignore file in $dataDir, ignoring" 1>&2
	    fi
	fi
    done
done

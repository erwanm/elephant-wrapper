#!/bin/bash



progName=$(basename "$BASH_SOURCE")

function usage {
  echo
  echo "Usage: $progName [options] <UD directory>"
  echo
  echo "  Generates a file containing pairs <ISO639 code> <UD2 directory> (one by line)"
  echo "  from the full UD2 directory, based on the UD2 naming conventions."
  echo "  TODO update here. Corpora are read from <UD directory>/<dataset>/*conllu, using the 'train'"
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
if [ $# -ne 1 ]; then
    echo "Error: expecting 1 args." 1>&2
    printHelp=1
fi

if [ ! -z "$printHelp" ]; then
    usage 1>&2
    exit 1
fi
inputDir="$1"

for dataDir in "$inputDir"/*; do
    if [ -d "$dataDir" ]; then
	data=$(basename "$dataDir")
	trainFile=$(ls $dataDir/*train*.conllu)
	TODO get code from filename here
	echo -e "$code\t$data"
done | sort +0 -1 -u

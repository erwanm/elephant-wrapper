#!/bin/bash



progName=$(basename "$BASH_SOURCE")


function usage {
  echo
  echo "Usage: $progName [options] <expe directory>"
  echo
  echo "  Reads a list of pattern files from STDIN, collects eval files"
  echo "  contents for each dataset in <expe directory>."
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

while read patternFile; do
    p=$(basename "$patternFile")
    missing=""
    for dataDir in $inputDir/*; do
	if [ -d "$dataDir" ]; then
	    data=$(basename "$dataDir")
	    if [ ! -s "$dataDir"/baseline.eval ]; then
		echo "Error: no baseline in $dataDir" 1>&2
		exit 1
	    fi
	    data=${data#UD_}
	    size=$(cut -f 1 "$dataDir"/baseline.eval)
	    baseline=$(cut -f 3 "$dataDir"/baseline.eval)
	    if [ ! -s "$dataDir"/$p/crf.output.eval ] || [ ! -s "$dataDir"/$p/elman.output.eval ]; then
		missing="$missing $data"
		crf=NA
		elman=NA
	    else
		crf=$(cut -f 3 "$dataDir"/$p/crf.output.eval)
		elman=$(cut -f 3 "$dataDir"/$p/elman.output.eval)
	    fi
	    echo -e "$data\t$p\t$size\t$baseline\t$crf\t$elman"
	fi
    done
    n=$(echo "$missing" | wc -w)
    echo "Warning: $n missing for $p: $missing" 1>&2
done


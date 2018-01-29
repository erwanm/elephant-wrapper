#!/bin/bash



progName=$(basename "$BASH_SOURCE")
elmanModel=""
quiet=""
iobInput=""
addElmanFeatures=""

function usage {
  echo
  echo "Usage: $progName [options] <UD conllu file> <pattern file> <output model directory>"
  echo
  echo "  Options:"
  echo "    -h this help."
  echo "    -e <Elman LM file> use LM features."
  echo "    -a add the 10 Elman features to the pattern file (use this only if the pattern"
  echo "       does not already contain the Elman features); ignored if -e is not supplied."
  echo "    -i provide the IOB file directly instead of the UD conllu file. The IOB file"
  echo "       is normally generated with: 'untokenize.pl -B T -i -f UD -C 1 <input>'."
  echo "    -q quiet mode: do not print stderr output from Wapiti."
  echo
}




OPTIND=1
while getopts 'he:iqa' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"e") elmanModel="$OPTARG";;
	"a") addElmanFeatures="yep";;
	"i") iobInput="yep";;
	"q") quiet="yes";;
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
input="$1"
pattern="$2"
modelDir="$3"

options=""

if [ -z "$iobInput" ]; then
    # extract unicode chars + IOB labels from UD file
    iobFile=$(mktemp --tmpdir "tmp.$progName.iob.XXXXXXXXX")
    untokenize.pl -B T -i -f UD -C 1 "$input" >$iobFile
    #echo $iobFile
else
    iobFile="$input"
fi

patternFile=$(mktemp --tmpdir "tmp.$progName.pat.XXXXXXXXX")
cat "$pattern" >"$patternFile"
if [ ! -z "$elmanModel" ]; then
    options="$options -e $elmanModel"
     if [ ! -z "$addElmanFeatures" ] ; then
	 # add Elman features to pattern
	 echo >>"$patternFile"
	 for i in $(seq 1 10); do
	     echo "*100:%x[ 0,$i]" >>"$patternFile"
	 done
     fi
fi


redirect=""
if [ ! -z "$quiet" ]; then
    redirect="2>/dev/null"
fi


# training model
rm -rf "$modelDir"
mkdir "$modelDir"
tmpTrainOutput=$(mktemp --tmpdir "tmp.$progName.elephant-train-output.XXXXXXXXX")
command="elephant-train $options -m \"$modelDir\" -w \"$patternFile\"  -i \"$iobFile\" 2>$tmpTrainOutput"
eval "$command"
if [ $? -ne 0 ] || grep error $tmpTrainOutput; then
    cat "$tmpTrainOutput" 1>&2
    rm -f "$tmpTrainOutput"
    echo "Error: an error occured with command '$command', aborting." 1>&2
    exit 3
else
    if [ -z "$quiet" ]; then
	cat "$tmpTrainOutput" 1>&2
    fi
    rm -f "$tmpTrainOutput"
    if [ ! -z "$elmanModel" ]; then
	if [ ! -f "$modelDir/elman" ] && [ -f "$modelDir/$(basename "$elmanModel")" ]; then
	    if [ -z "$quiet" ]; then
		echo "(fixing Elman model filename)"
	    fi
	    mv "$modelDir/$(basename "$elmanModel")" "$modelDir/elman"
	fi
	if [ ! -f "$modelDir/elman" ]; then
	    echo "Error: no Elman model in $modelDir, something went wrong" 1>&2
	fi
    fi
fi

# cleaning up
if [ -z "$iobInput" ]; then
    rm -f "$iobFile"
fi
rm -f "$patternFile"

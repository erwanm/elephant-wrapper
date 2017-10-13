#!/bin/bash



progName=$(basename "$BASH_SOURCE")
elmanModel=""
quiet=""


function usage {
  echo
  echo "Usage: $progName [options] <UD conllu file> <pattern file> <output model directory>"
  echo
  echo "  Remark: <pattern file> should not contain the Elman features, they will be added"
  echo "  automatically if option -e is provided."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -e <Elman LM file> use LM features"
  echo "    -q quiet mode: do not print stderr output from Wapiti"
  echo
}




OPTIND=1
while getopts 'he:q' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"e") elmanModel="$OPTARG";;
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

# extract unicode chars + IOB labels from UD file
iobFile=$(mktemp --tmpdir "$progName.iob.XXXXXXXXX")
untokenize.pl -B T -i -f UD -C 1 "$input" >$iobFile
#echo $iobFile

patternFile=$(mktemp --tmpdir "$progName.pat.XXXXXXXXX")
cat "$pattern" >"$patternFile"
if [ ! -z "$elmanModel" ]; then
    # add Elman features to pattern
    echo >>"$patternFile"
    for i in $(seq 1 10); do
	echo "*100:%x[ 0,$i]" >>"$patternFile"
    done
    options="$options -e $elmanModel"
fi


redirect=""
if [ ! -z "$quiet" ]; then
    redirect="2>/dev/null"
fi


# training model
rm -rf "$modelDir"
mkdir "$modelDir"
command="elephant-train $options -m \"$modelDir\" -w \"$patternFile\"  -i \"$iobFile\" $redirect"
eval "$command"
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

# cleaning up
rm -f $iobFile $patternFile

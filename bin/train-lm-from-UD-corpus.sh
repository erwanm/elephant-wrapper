#!/bin/bash



progName=$(basename "$BASH_SOURCE")

percentTrain=80
optThreads=""
quiet=""

function usage {
  echo
  echo "Usage: $progName [options] <UD conllu file> <output lm file>"
  echo
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -p <percentage training set> The rest is used as validation set;"
  echo "       Default: $percentTrain."
  echo "    -t <nb threads>"
  echo "    -q quiet mode: don't print progress to STDOUT"
  echo
}




OPTIND=1
while getopts 'hp:t:q' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"p") percentTrain="$OPTARG";;
	"t") optThreads="-threads $OPTARG";;
	"q") quiet="yes";;
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
input="$1"
model="$2"

cleanupFiles=""

# extract unicode chars + IOB labels from UD file
iobFile=$(mktemp --tmpdir "$progName.XXXXXXXXX")
cleanupFiles="$cleanupFiles $iobFile"
untokenize.pl -i -f UD -C 1 $input  >$iobFile

# split training/validation set
total=$(cat $iobFile | wc -l)
sizeTrain=$(( $total * $percentTrain / 100 ))
sizeValid=$(( $total - $sizeTrain ))
if [ -z "$quiet" ]; then
    echo "Info: $total chars, splitting $percentTrain % train = $sizeTrain for training + $sizeValid for validation"
fi
head -n $sizeTrain $iobFile | cut -f 1 | tr '\n' ' ' > $iobFile.train
tail -n $sizeValid $iobFile | cut -f 1 | tr '\n' ' ' > $iobFile.valid
cleanupFiles="$cleanupFiles $iobFile.train $iobFile.valid"

# training model
rm -f "$modelFile"
redirect=""
if [ ! -z "$quiet" ]; then
    elmanStderr=$(mktemp --tmpdir "$progName.elman-stderr.XXXXXXXXX")
    cleanupFiles="$cleanupFiles $elmanStderr"
    redirect=" >/dev/null 2>$elmanStderr"
fi
command="elman $optThreads -class 1 -train $iobFile.train -rnnlm \"$model\" -valid $iobFile.valid $redirect"
eval "$command"
if [ ! -z "$quiet" ]; then
    # elman prints the line "rnnlm file: xxxx" to STDERR, so we need to get rid
    # of it in order to check that there's nothing else in STDERR, i.e. actual error
    cat "$elmanStderr" | grep -v "^rnnlm file:" 1>&2
fi

# cleaning up
rm -f $cleanupFiles

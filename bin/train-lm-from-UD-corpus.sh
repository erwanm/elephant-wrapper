#!/bin/bash



progName=$(basename "$BASH_SOURCE")

percentTrain=80
optThreads=""

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
  echo
}




OPTIND=1
while getopts 'hp:t:' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"p") percentTrain="$OPTARG";;
	"t") optThreads="-threads $OPTARG";;
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


# extract unicode chars + IOB labels from UD file
iobFile=$(mktemp --tmpdir "$progName.XXXXXXXXX")
untokenize.pl -i -f UD -C 1 $input  >$iobFile

# split training/validation set
total=$(cat $iobFile | wc -l)
sizeTrain=$(( $total * $percentTrain / 100 ))
sizeValid=$(( $total - $sizeTrain ))
echo "Info: $total chars, splitting $percentTrain % train = $sizeTrain for training + $sizeValid for validation"
head -n $sizeTrain $iobFile | cut -f 1 | tr '\n' ' ' > $iobFile.train
tail -n $sizeValid $iobFile | cut -f 1 | tr '\n' ' ' > $iobFile.valid

# training model
rm -f "$modelFile"
command="elman $optThreads -class 1 -train $iobFile.train -rnnlm \"$model\" -valid $iobFile.valid"
eval "$command"

# cleaning up
rm -f $iobFile $iobFile.train $iobFile.valid

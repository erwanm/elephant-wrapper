#!/bin/bash



progName=$(basename "$BASH_SOURCE")

iobOpt=""

function usage {
  echo
  echo "Usage: $progName [options] <UD conllu file> <elephant model directory> <output file>"
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -i output in IOB format and perform evaluation to <output file>.eval"
  echo
}




OPTIND=1
while getopts 'hi' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"i") iobOpt="-f iob";;
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
modelDir="$2"
output="$3"

# convert UD corpus to text, but remove line breaks
textFile=$(mktemp --tmpdir "$progName.text.XXXXXXXXX")
untokenize.pl -f UD -C 1 "$input" | tr '\n' ' ' >$textFile

# apply model
rm -f "$output"
command="elephant $iobOpt -m \"$modelDir\"  <\"$textFile\" >\"$output\""
eval "$command"


if [ ! -z "$iobOpt" ]; then
    echo "Info: evaluating IOB output"
    
    # fix obviously wrong labels
    tmp=$(mktemp --tmpdir "$progName.iob.XXXXXXXXX")
    iob-fix-missing-b.pl -b T "$output" $tmp
    cat $tmp >$output

    # get IOB gold output
    untokenize.pl -i -f UD -C 1 "$input" >$textFile

    evaluate.pl "$output:1" "$textFile:2" >"$output.eval"
    cat "$output.eval"

    rm -f $tmp
fi

# cleaning up
rm -f $textFile

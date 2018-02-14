#!/bin/bash



progName=$(basename "$BASH_SOURCE")

tokenByLine=""
missingBScript=1
paramsModelName="elephant"
quietOpt=""
opts=""

function usage {
  echo
  echo "Usage: $progName [options] <model> <input text> <output>"
  echo
  echo "  Tokenizes <input text> line by line, i.e. considers each line as a distinct"
  echo "  sentence and runs the tokenization process for each individual line."
  echo
  echo "  <model> can be:"
  echo "    - the name of an elephant model directory; if the directory does not exist,"
  echo "      the model name is searched in the default model dir"
  echo "    - the ISO 639-1 language code (2 letters) corresponding to a model in the"
  echo "      default model dir. "
  echo "    See tokenize.sh -h for details."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -l prints output with one token by line instead of separated by spaces "
  echo "       (default). Sentences are separated by an empty line (one sentence by"
  echo "       line by default)."
  echo "    -n <parameters model name> name to use for the parameters model directory,"
  echo "       in case there are several alternatives. Default: '$paramsModelName'."
  echo "    -b do not apply script to fix missing B labels: applied by default if"
  echo "       -I is provided, but should not be applied if tokens can include"
  echo "       whitespaces. Ignored if -I is not supplied."
  echo "    -q quiet mode."
  echo
}




OPTIND=1
while getopts 'hln:bq' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"l" ) tokenByLine="yes";;
	"n" ) opts="$opts -n \"$OPTARG\"";;
	"b" ) opts="$opts -b";;
	"q" ) opts="$opts -q"
	      quietOpt="-q";;
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
modelDir="$1"
input="$2"
output="$3"

tmpSent=$(mktemp --tmpdir "tmp.$progName.XXXXXXXXXX")
comm="tokenize.sh $opts -o $tmpSent \"$modelDir\""

total=$(cat "$input" | wc -l)
lineNo=1
cat "$input" | while read line; do
    if [ -z "$quietOpt" ]; then
	echo -en "\r$lineNo / $total" 1>&2
    fi
    echo "$line" | eval "$comm"
    if [ -z "$tokenByLine" ]; then
	cat "$tmpSent"
	echo
    else
	cat  "$tmpSent" | tr ' ' '\n'
	echo
	echo
    fi
    lineNo=$(( $lineNo + 1 ))
done >"$output"
echo 1>&2
rm -f "$tmpSent"

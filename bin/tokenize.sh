#!/bin/bash



progName=$(basename "$BASH_SOURCE")

scriptDir=$(dirname "$BASH_SOURCE")
# assuming that the script is in some directory xxx/bin, and the default model dir is xxx/models
if [ -d "$scriptDir/../models" ]; then 
    defaultModelDir="$scriptDir/../models"
else
    defaultModelDir="./models"
fi

iso639File="iso639-codes.txt"

input=""
output=""
ud2Format=""
iobOpt=""
missingBScript=1
paramsModelName="elephant"


function usage {
  echo
  echo "Usage: $progName [options] <model>"
  echo
  echo "  Tokenizes some input text read from STDIN according to <model> and prints"
  echo "  the result to STDOUT."
  echo "  <model> can be:"
  echo "    - the name of an elephant model directory; if the directory does not exist,"
  echo "      the model name is searched in the default model dir $defaultModelDir (see"
  echo "      option -p)."
  echo "    - the ISO 639-1 language code (2 letters) corresponding to a model in the"
  echo "      default model dir $defaultModelDir; The ISO 639-2 code (3 letters) is"
  echo "      used for languages which do not have a 2 letters code (e.g. 'grc' for"
  echo "      Ancient Greek, see option -P)."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -i <input> read from this file instead of STDIN."
  echo "    -o <output> write to this file instead of STDOUT."
  echo "    -c input is in the UD2 .conllu file format"
  echo "    -I output provided in IOB format; if used in conjunction with -c, the"
  echo "       evaluation is also performed and the result is either printed to"
  echo "       STDERR or written to <output>.eval if option -o is supplied."
  echo "    -n <parameters model name> name to use for the parameters model directory,"
  echo "       in case there are several alternatives. Default: '$paramsModelName'."
  echo "    -b do not apply script to fix missing B labels: applied by default if"
  echo "       -I is provided, but should not be applied if tokens can include"
  echo "       whitespaces. Ignored if -I is not supplied."
  echo "    -p print the list of available models in the default model directory,"
  echo "       as full names. The argument is not used."
  echo "    -P print the list of available models in the default model directory,"
  echo "       as ISO 639-1 (or ISO 639-2) codes. The argument is not used."
  echo
}




OPTIND=1
while getopts 'hi:o:cIn:bpP' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"i" ) input="$OPTARG";;
	"o" ) output="$OPTARG";;
	"c" ) ud2Format=1;;
 	"I" ) iobOpt="-f iob";;
	"n" ) paramsModelName="$OPTARG";;
	"b" ) missingBScript="";;
	"p" ) for d in $defaultModelDir/*; do if [ -d "$d" ]; then echo $(basename "$d"); fi; done
	      exit 0;;
	"P" ) if [ ! -f "$defaultModelDir/$iso639File" ]; then echo "Error: cannot find file $defaultModelDir/$iso639File" 1>&2; exit 1; fi; cat "$defaultModelDir/$iso639File"
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
modelDir="$1"

if [ ! -d "$modelDir" ]; then
    if [ -d "$defaultModelDir/$modelDir" ]; then
	dataDir="$defaultModelDir/$modelDir"
    else # ISO639 code, look it up in $iso639File
	dataDir="$defaultModelDir"/$(grep "^$modelDir" "$defaultModelDir/$iso639File" | cut -f 2)
    fi
    modelDir="$dataDir/$paramsModelName.elephant-model"
fi
if [ ! -s "$modelDir/wapiti" ]; then
    echo "Error: '$modelDir' is not a valid Elephant model directory" 1>&2
    exit 1
fi

if [ -z "$input" ]; then
    input=$(mktemp --tmpdir "$progName.input.XXXXXXXXXX")
    echo "$(</dev/stdin)" > "$input"
    rmInput=1
fi

textFile=$(mktemp --tmpdir "$progName.text.XXXXXXXXX")
if [ ! -z "$ud2Format" ]; then
    # convert UD corpus to text, but remove line breaks
    untokenize.pl -f UD -C 1 "$input" | tr '\n' ' ' >$textFile
else
    tr '\n' ' ' <"$input" >$textFile
fi

redirectOutput=""
if [ ! -z "$output" ]; then
    redirectOutput=" >\"$output\""
else
    if [ ! -z "$iobOpt" ] ; then
	output=$(mktemp --tmpdir "$progName.output.XXXXXXXXXX")
	rmOutput=1
	redirectOutput=" >\"$output\""
    fi
fi
# apply model
command="elephant $iobOpt -m \"$modelDir\"  <\"$textFile\" $redirectOutput"
eval "$command"

# if no -I option, we're done here

if [ ! -z "$iobOpt" ]; then

    if [ ! -z "$missingBScript" ]; then # apply missing Bs script
	tmp=$(mktemp --tmpdir "$progName.iob.XXXXXXXXX")
	iob-fix-missing-b.pl -B T "$output" "$tmp"
	cat "$tmp" >"$output"
	rm -f "$tmp"
    fi

    # if not UD2 format, we're done; otherwise evaluation
    if [ ! -z "$ud2Format" ]; then
	# get IOB gold output
	untokenize.pl -B T -i -f UD -C 1 "$input" >$textFile

	if [ -z "$rmOutput" ]; then 
	    redirectOutput=" >\"$output.eval\""
	else  # if no output file, print to STDERR
	    redirectOutput=" 1>&2"
	fi
	command="evaluate.pl \"$output:2\" \"$textFile:2\" $redirectOutput"
	eval "$command"
    fi
    

fi

# cleaning up
rm -f $textFile

if [ ! -z "$rmInput" ]; then
    rm -f "$input"
fi
if [ ! -z "$rmOutput" ]; then
    rm -f "$output"
fi

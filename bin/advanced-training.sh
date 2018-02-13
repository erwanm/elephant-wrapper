#!/bin/bash



progName=$(basename "$BASH_SOURCE")


trainFilePattern="*train*.conllu"
testFilePattern="*dev*.conllu"

iso639File="iso639-codes.txt"

testFile=""
elman=""
paramsModelName="elephant"
missingBScript="yep"

maxNoProgress=""
nbFold=5

cleanupFiles=""
quietMode=""
iobInput=""

function usage {
  echo
  echo "Usage: $progName [options] <training .conll file> <patterns file> <output dir>"
  echo
  echo "  Trains a tokenizer using pre-tokenized data in .conllu format, selecting"
  echo "  the optimal model from the sequence of Wapiti pattern files read from"
  echo "  <patterns file>; also computes the Elman model if needed, depending on"
  echo "   option -e."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -t <test .conll file> also perform testing of the model using this data,"
  echo "       including evaluation and applying a generic tokenizer as  baseline."
  echo "    -m <max no progress> specify the max number of patterns with no progress for"
  echo "       stopping the process; 0 means process all files; default: $stopCriterionMax."
  echo "    -k <K> value for k-fold cross-validation; default: $nbFold."
  echo "    -e use Elman language models (usually performs better but longer training)"
  echo "    -n <parameters model name> name to use for the parameters model directory;"
  echo "       this is useful when runnning this script several times with different"
  echo "       parameters. Default: '$paramsModelName'."
  echo "    -b do not apply script to fix missing B labels in testing: applied by"
  echo "       default, but should not be applied if tokens can include whitespaces."
  echo "       Ignored if -t is supplied."
  echo "    -r <files to cleanup> list of files to remove at the end of the process,"
  echo "       space separated (use quotes for the argument); useful for delayed"
  echo "       processing in the case of distributed processing."
  echo "    -q quiet mode."
  echo "    -i the input file is provided in IOB format instead of conll format."
  echo "       Remark: if -t is supplied, test file is supposed to be in IOB format"
  echo "       as well."
  echo 
}




OPTIND=1
while getopts 'ht:m:k:en:br:qi' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"t" ) testFile="$OPTARG";;
	"m" ) maxNoProgress="$OPTARG";;
	"k" ) nbFold="$OPTARG";;
	"e" ) elman="yep";;
	"n" ) paramsModelName="$OPTARG";;
	"b" ) missingBScript="";;
	"r" ) cleanupFiles="$OPTARG";;
	"q" ) quietMode="yes";;
	"i" ) iobInput="yes";;
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
trainFile="$1"
patternsFile="$2"
workDir="$3"


prefix="$workDir/$paramsModelName"

# TRAINING

if [ -z "$quietMode" ]; then
    echo -n "* Processing '$trainFile': " 1>&2
fi


opts="-q -t \"$prefix.elephant-model\""
if [ ! -z  "$maxNoProgress" ]; then
    opts="$opts -s \"$maxNoProgress\" -c $nbFold"
fi
if [ ! -z "$iobInput" ]; then
    opts="$opts -i"
fi
[ -d "$workDir" ] || mkdir "$workDir"
if [ ! -z "$elman" ]; then
    if [ ! -s "$workDir/elman.model" ]; then # Training Elman LM
	if [ -z "$quietMode" ]; then
	    echo -n "training LM; " 1>&2
	fi
	train-lm-from-UD-corpus.sh -q "$trainFile" "$workDir/elman.model"
    fi
    opts="$opts -e \"$workDir/elman.model\""
fi
# remark: originally the test below also depended on the existence of the Elman model in the output dir;
# however it is now impossible to know whether the output dir should contain the Elman model or not,
# since this depends which pattern was selected. This is why we now test only the Wapiti model,
# assuming that the model was selected with the same parameters (as this was the only case in which
# the wapiti model would exist but not the elman one). If parameters have changed, the user should
#  use the 'force' option anyway.
if [ ! -s "$prefix.elephant-model/wapiti" ]; then # Training main Wapiti model
    if [ -z "$quietMode" ]; then
	echo -n "${nbFold}-fold CV for finding best CRF model; " 1>&2
    fi
    command="cv-tokenizers-from-UD-corpus.sh $opts  \"$trainFile\" \"$patternsFile\" \"$prefix.cv.perf\""
    eval "$command"
    if [ ! -s "$prefix.elephant-model/wapiti" ]; then
	echo "An error occured during training. Command was: '$command'" 1>&2
	echo "Skipping dataset '$workDir'" 1>&2
	testFile="" # skip testing
    fi
fi

# TESTING
if [ ! -z "$testFile" ]; then
    if [ -z "$quietMode" ]; then
	echo -n "testing; " 1>&2
    fi
    opts=""
    # get IOB gold output
    if [ -z "$iobInput" ]; then
	untokenize.pl -i -f UD -C 1 -B T "$testFile" >"$workDir/gold.iob"
	opts="$opts -c"
    else
	cat "$testFile" >"$workDir/gold.iob"
	opts="$opts -t"
    fi
    cleanupFiles="$cleanupFiles $workDir/gold.iob"
    if [ -z "$missingBScript" ]; then
	opts="-b"
    fi
    # remark: evaluation is also done by tokenize.sh
    command="tokenize.sh $opts -q -I -i \"$testFile\" -o \"$prefix\"  \"$prefix.elephant-model\""
    eval "$command"
    cleanupFiles="$cleanupFiles $prefix"
    
    if [ -z "$quietMode" ]; then
	echo -n "baseline; " 1>&2
    fi
    # the following 3 steps are for baseline tokenizer only:
    # 1. get text file from test UD conllu file
    if [ -z "$iobInput" ]; then
	untokenize.pl -f UD -C 1 -B T "$testFile" >"$workDir/baseline.txt"
    else
	iob-to-text.pl -B T -n "$testFile" "$workDir/baseline.txt"
    fi
    # 2. tokenize it with baseline tokenizer
    generic-tokenizer.pl -B T -i "$workDir/baseline.txt" >"$workDir/baseline.iob"
    cleanupFiles="$cleanupFiles $workDir/baseline.iob $workDir/baseline.txt"
    # 3. evaluate baseline
    evaluate.pl -B T "$workDir/baseline.iob:2" "$workDir/gold.iob:2" >"$workDir/baseline.eval"
fi
if [ -z "$quietMode" ]; then
    echo 1>&2
fi
if [ ! -z "$cleanupFiles" ]; then
    rm -f $cleanupFiles
fi

#!/bin/bash



progName=$(basename "$BASH_SOURCE")


trainFilePattern="*train*.conllu"
testFilePattern="*dev*.conllu"

iso639File="iso639-codes.txt"

testing="yep"
elman=""
force=""
iso639mapping=""
elephantModelDirName="elephant.model"
splitDevFile=""
missingBScript="yep"

function usage {
  echo
  echo "Usage: $progName [options] <input directory> <pattern file> <output directory>"
  echo
  echo "  Trains multiple tokenizers using pre-tokenized data in .conllu format. This"
  echo "  script is intended to be used with the Universal Dependencies 2.0 corpus."
  echo
  echo "  It is assumed that <input directory> contains one directory by dataset, and"
  echo "  that every such directory contains a file which matches '$trainFilePattern',"
  echo "  as well as a file which matches '$testFilePattern'; the former is used for"
  echo "  training an Elephant model, then the model is applied to the latter, used as"
  echo "  test data. Additionally, a baseline tokenizer is applied to the test data"
  echo "  and evaluation is performed for both the trained and the baseline tokenizer."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -t training only; by default the tokenizer model is also applied to the"
  echo "       test dataset."
  echo "    -p <train file pattern> pattern to use for finding the train file;"
  echo "       default: '$trainFilePattern'"
  echo "    -P <test file pattern> pattern to use for finding the test file;"
  echo "       default: '$testFilePattern'"
  echo "    -e use Elman language models (usually performs better but longer training)"
  echo "    -f force overwriting any previously existing tokenizers in"
  echo "       <output directory>; by default existing models are not recomputed."
  echo "    -l generate language codes mapping file; this assumes that the input .conllu"
  echo "       filenames start with the ISO639 language codes (intended for UD2 corpus)."
  echo "    -n <elephant model name> name to use for the elephant model directory."
  echo "       Default: '$elephantModelDirName'."
  echo "    -s <training set proportion> Split test file into training and test set if "
  echo "       no training file is found (this is a workaround for the two languages in"
  echo "       UD2 for which only a dev file is supplied: UD_Kazakh and UD_Uyghur)."
  echo "       Example: -s 0.8 means 80% train set, 20% test set."
  echo "    -b do not apply script to fix missing B labels in testing: applied by"
  echo "       default, but should not be applied if tokens can include whitespaces."
  echo "       Ignored if -t is supplied."
  echo 
}




OPTIND=1
while getopts 'htp:P:efln:s:b' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"t" ) testing="";;
	"p" ) trainFilePattern="$OPTARG";;
	"P" ) testFilePattern="$OPTARG";;
	"e" ) elman="yep";;
	"f" ) force="yep";;
	"l" ) iso639mapping="yep";;
	"n" ) elephantModelDirName="$OPTARG";;
	"s" ) splitDevFile="$OPTARG";;
	"b" ) missingBScript="";;
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
inputDir="$1"
patternFile="$2"
outputDir="$3"

if [ ! -z "$force" ]; then
    rm -rf $outputDir
fi
[ -d "$outputDir" ] || mkdir "$outputDir"

for dataDir in "$inputDir"/*; do
    if [ -d "$dataDir" ]; then
	cleanupFiles=""
	data=$(basename "$dataDir")
	echo "### Processing '$data'..." 1>&2
	lsPatTrain="$dataDir/$trainFilePattern"
	trainFile=$(ls $lsPatTrain 2>/dev/null | head -n 1)
	lsPatTest="$dataDir/$testFilePattern"
	testFile=$(ls $lsPatTest 2>/dev/null | head -n 1)
	if [ -z "$trainFile" ] && [ -z "$testFile" ]; then
	    echo "Warning: no file matches '$lsPatTrain' neither '$lsPatTest', ignoring dataset '$data'." 1>&2
	else
	    # from here we have either a train set or a test set
	    if [ -z "$trainFile" ] && [ -z "$splitDevFile" ]; then
		echo "Warning: no file matches '$lsPatTrain' for training and no option -s, ignoring dataset '$data'." 1>&2
	    else
		# from here we have a train set or a test + split option (or both)
		if [ -z "$trainFile" ]; then # no train set: we split the test set
		    echo "Warning: no file matches '$lsPatTrain' in '$data'; splitting test file '$testFile'." 1>&2
		    prefix=$(mktemp --tmpdir "$progName.split-dev-file.XXXXXXXXXX")
		    split-conllu-sentences.pl -b "$prefix." -p "$splitDevFile" "$testFile"
		    trainFile="$prefix.1"
		    testFile="$prefix.2"
		    cleanupFiles="$cleanupFiles $prefix.1 $prefix.2"
		fi
		# now we have a train set, but it's still possible we don't have a test set; we're doing the training anyway

		# TRAINING
		workDir="$outputDir/$data"
		opts=""
		[ -d "$workDir" ] || mkdir "$workDir"
		processWithElman=""
		if [ ! -z "$elman" ] &&  [ ! -s "$workDir/elman.model" ]; then # Training Elman LM
		    train-lm-from-UD-corpus.sh "$trainFile" "$workDir/elman.model"
		    opts="$opts -e \"$workDir/elman.model\""
		    if [ ! -s "$workDir/$elephantModelDirName/elman" ]; then
			processWithElman="yep"
		    fi
		fi
		if [ ! -z "$processWithElman" ] || [ ! -s "$workDir/$elephantModelDirName/wapiti" ]; then # Training main Wapiti model
		    command="train-tokenizer-from-UD-corpus.sh $opts \"$trainFile\" \"$patternFile\" \"$workDir/$elephantModelDirName\""
		    eval "$command"
		    if [ ! -s "$workDir/$elephantModelDirName/wapiti" ]; then
			echo "An error occured during training. Command was: '$command'" 1>&2
			echo "Skipping dataset '$data'" 1>&2
			testing="" # skip testing
		    fi
		fi

		# TESTING
		if [ ! -z "$testing" ]; then
		    if [ -z "$testFile" ]; then
			echo "Warning: no file matches '$lsPatTest' for '$data', skipping testing." 1>&2
		    else
			# get IOB gold output
			untokenize.pl -i -f UD -C 1 -B T "$testFile" >"$workDir/gold.iob"
			opts=""
			if [ -z "$missingBScript" ]; then
			    opts="-n"
			fi
			# remark: evaluation is also done by tokenize.sh
			command="tokenize.sh $opts -c -I -i \"$testFile\" -o \"$workDir/test.iob\"  \"$workDir/$elephantModelDirName\""
			eval "$command"

			# the following 3 steps are for baseline tokenizer only:
			# 1. get text file from test UD conllu file
			untokenize.pl -f UD -C 1 -B T "$testFile" >"$workDir/baseline.txt"
			# 2. tokenize it with baseline tokenizer
			generic-tokenizer.pl -B T -i "$workDir/baseline.txt" >"$workDir/baseline.iob"
			rm -f "$workDir/baseline.txt"
			# 3. evaluate baseline
			evaluate.pl "$workDir/baseline.iob:2" "$workDir/gold.iob:2" >"$workDir/baseline.eval"
		    fi
		fi
	    fi
	fi
	if [ ! -z "$cleanupFiles" ]; then
	    rm -f $cleanupFiles
	fi
    fi
done
if [ ! -z "$iso639mapping" ]; then
    echo "### Generating ISO639 codes mapping..." 1>&2
    generate-iso639-codes-file.sh "$inputDir" >"$outputDir/$iso639File"
fi

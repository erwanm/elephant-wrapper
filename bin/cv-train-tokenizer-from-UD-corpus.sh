#!/bin/bash



progName=$(basename "$BASH_SOURCE")
nbFold=5
trainOpts=""
elmanModel=""
quiet=""
iobInput=""
keepFiles=""
stopCriterionMax=10
outputModelDir=""
evalCol=4 # col 4 for accuracy (see evaluate.pl)

function usage {
  echo
  echo "Usage: $progName [options] <UD conllu file> <pattern list file> <perf output file>"
  echo
  echo "  Runs $nbFold cross-validation training/testing for <UD conllu file> for the"
  echo "  pattern files in <pattern list file>, and writes the resulting performance to"
  echo "  <perf output file>. The list of pattern files is tested until there is no"
  echo "  progress for the last $stopCriterionMax patterns; thus the order of the files"
  echo "   matters, the first are supposed to be the simplest patterns."
  echo
  echo "  Remark: the pattern files should not contain the Elman features, they will be"
  echo "  added automatically if option -e is provided."
  echo
  echo "  Options:"
  echo "    -h this help."
  echo "    -e <Elman LM file> use LM features."
  echo "    -i provide the IOB file directly instead of the UD conllu file. The IOB file"
  echo "       is normally generated with: 'untokenize.pl -B T -i -f UD -C 1 <input>'."
  echo "    -c <nb fold>; default: $nbFold."
  echo "    -q quiet mode: do not print stderr output from Wapiti."
  echo "    -k keep all the generated files (default: delete all)."
  echo "    -s <max no progress> specify the max number of patterns with no progress for"
  echo "       stopping the process; 0 means process all files; default: $stopCriterionMax."
  echo "    -t <output model dir> at the end, use the pattern which gives the best"
  echo "       performance to train the full data model and store it in <output model dir>."
  echo
}



#
# prints the best line if there has been no progress in the last $maxNoProgress models; prints nothing otherwise
#
function noProgressAnymore {
    local perfFile="$1"
    local maxNoProgress="$2"

    if [ $maxNoProgress -gt 0 ]; then # otherwise no limit, we never stop
	total=$(cat "$perfFile" | wc -l)
	if [ $total -gt $maxNoProgress ]; then # otherwise dont stop, not enough cases yet
	    # sort first cases (the ones before the last $maxNoProgress cases)
	    best=$(cat "$perfFile" | sort -n -g +1 -2 | tail)
	    bestNo=$(echo "$best" | cut -f 1) # relying on the pattern no for the order of the file (could also be done differently)
	    if [ $bestNo -le $(( $total - $maxNoProgress )) ]; then
		echo "$best"
	    fi
	fi
    fi
}




OPTIND=1
while getopts 'hc:e:iqks:t:' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"e" ) trainOpts="$trainOpts -e \"$OPTARG\"";;
	"i" ) iobInput="yep"
	      trainOpts="$trainOpts -i";;
	"c" ) nbFold="$OPTARG";;
	"q" ) trainOpts="$trainOpts -q"
	      quiet="yes";;
	"k" ) keepFiles="yep";;
	"s" ) stopCriterionMax="$OPTARG";;
	"t" ) outputModelDir="$OPTARG";;
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
patternsFile="$2"
outputPerfFile="$3"

workDir=$(mktemp -d --tmpdir "$progName.pat.XXXXXXXXX")


#
# split training set into nbFold test sets for CV
#
#
if [ -z "$iobInput" ]; then
    split-conllu-sentences.pl -b "$workDir/" -a ".test.cv" "$nbFold" "$input"
else
    split -d -n "l/$nbFold" --additional-suffix=.test.cv "$input" "$workDir/"
fi



#
# generate train data for CV
#
# remark: in the case of IOB file, it is possible that by concatenating files which are not
#         sequential we create a incoherent sequence of characters (that would be the only one error though)
for testFile in "$workDir"/*.test.cv; do
    trainFile="${testFile%.test.cv}.train.cv"
    rm -f "$trainFile"
    for f2 in "$workDir"/*.test.cv; do
	if [ "$f2" != "$testFile" ]; then
	    cat "$f2" >>"$trainFile"
	fi
    done
done

nbPatterns=$(cat "$patternsFile" | wc -l)
stopCriterion=""
rm -f "$outputPerfFile"
patternNo=1
while [ $patternNo -le $nbPatterns ] && [ -z "$stopCriterion" ]; do
    patternFile=$(head -n $patternNo "$patternFile" | tail -n 1)
    patternDir="$workDir/$(basename "$patternFile")"
    mkdir "$patternDir"
    sumStr="0"
    for testFile in "$workDir"/*.test.cv; do
	trainFile="${testFile%.test.cv}.train.cv"
	outputDir="$patternDir/$(basename "$testFile")"
	comm="train-tokenizer-from-UD-corpus.sh $trainOpts \"$trainFile\" \"$patternFile\" \"$outputDir\""
	eval "$comm"

	TODO pbm: file can be IOB format instead of conllu
	comm="cat  \"$testFile\" | tokenize.sh -c -I -o \"$outputDir/test.out\" \"$patternDir\"" # need option -n ???
	eval "$comm"
	perf=$(cat "$outputDir/test.out.eval" | cut -f "$evalCol")
	sumStr="$sumStr + $perf"
    done
    meanperf=$(echo "scale=6; ( $sumStr ) / $nbFold" | bc) # calculate the mean perf
    echo -e "$patternNo\tpatternFile\t$meanperf" >>"$outputPerfFile"
    stopCriterion=$(noProgressAnymore "$outputPerfFile" "$stopCriterionMax")
    patternNo=$(( $patternNo + 1 ))
done

if [ ! -z "$outputModelDir" ]; then # train on full training data for best pattern
    bestPatternFile=$(echo "$stopCriterion" | cut -f 2)
    comm="train-tokenizer-from-UD-corpus.sh $trainOpts \"$input\" \"$bestPatternFile\" \"$outputModelDir\""
    eval "$comm"
fi

if [ -z "$keepFiles" ]; then
    rm -rf "$workDir"
else
    echo "Leaving all the files in '$workDir'" 1>&2
fi






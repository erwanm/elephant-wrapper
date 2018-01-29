#!/bin/bash



progName=$(basename "$BASH_SOURCE")
nbFold=5
trainOpts=""
elmanModel=""
quiet=""
iobInput=""
keepFiles=""
stopCriterionMax=15
outputModelDir=""
evalCol=4 # col 4 for accuracy (see evaluate.pl)
printProgress=""

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
  echo "  Remark: the columns given for calculating features are as follows:"
  echo "          <unicode point> <unicode category> [<elman1> <elman2> ...]"
  echo "          i.e. columns 0 and 1 are mandatory, columns 2 to 11 are the optional"
  echo "          Elman 'top10' features. If at least one pattern uses the Elman"
  echo "          features, then option -e must be supplied."
  echo
  echo "  Options:"
  echo "    -h this help."
  echo "    -e <Elman LM file> The Elman features will be used depending on whether"
  echo "       the pattern file uses column 2; this implies that this option must be"
  echo "       supplied if at least one pattern file uses column 2."
  echo "    -i provide the IOB file directly instead of the UD conllu file. The IOB file"
  echo "       is normally generated with: 'untokenize.pl -B T -i -f UD -C 1 <input>'."
  echo "    -c <nb fold>; default: $nbFold."
  echo "    -q quiet mode: do not print stderr output from Wapiti."
  echo "    -k keep all the generated files (default: delete all)."
  echo "    -s <max no progress> specify the max number of patterns with no progress for"
  echo "       stopping the process; 0 means process all files; default: $stopCriterionMax."
  echo "    -t <output model dir> at the end, use the pattern which gives the best"
  echo "       performance to train the full data model and store it in <output model dir>."
  echo "    -p print progress (to STDERR)."
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
	    best=$(cat "$perfFile" | sort -g +2 -3 | tail -n 1)
	    bestNo=$(echo "$best" | cut -f 1) # relying on the pattern no for the order of the file (could also be done differently)
	    if [ $bestNo -le $(( $total - $maxNoProgress )) ]; then
		echo "$best"
	    fi
	fi
    fi
}




OPTIND=1
while getopts 'hc:e:iqks:t:p' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"e" ) elmanModel="$OPTARG";;
	"i" ) iobInput="yep"
	      testOpts="$testOpts -t"
	      trainOpts="$trainOpts -i";;
	"c" ) nbFold="$OPTARG";;
	"q" ) trainOpts="$trainOpts -q"
	      testOpts="$testOpts -q"
	      quiet="yes";;
	"k" ) keepFiles="yep";;
	"s" ) stopCriterionMax="$OPTARG";;
	"t" ) outputModelDir="$OPTARG";;
	"p" ) printProgress="yep";;
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
patternsFile="$2"
outputPerfFile="$3"

workDir=$(mktemp -d --tmpdir "tmp.$progName.pat.XXXXXXXXX")

#echo "$workDir" 1>&2

#
# split training set into nbFold test sets for CV
#
#
if [ -z "$iobInput" ]; then
    testOpts="$testOpts -c"
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
progressTotal=$(( $nbFold * $nbPatterns ))
progress=0
stopCriterion=""
rm -f "$outputPerfFile"
patternNo=1
while [ $patternNo -le $nbPatterns ] && [ -z "$stopCriterion" ]; do
    patternFile=$(head -n $patternNo "$patternsFile" | tail -n 1)
    patternDir="$workDir/$(basename "$patternFile")"
#    echo "$patternNo $patternFile $patternDir" 1>&2
    mkdir "$patternDir"
    
    # Elman option is added only if the features in the pattern file require it
    elmanOpt=""
    if grep "%x\[.*,\s*2\s*\]" $patternFile >/dev/null; then # pattern file contains at least one features with column 2, interpreted as requiring Elman features
	if [ -z "$elmanModel" ]; then
	    echo "Warning: pattern '$patternFile' contains feature(s) using column 2, but no Elman model provided." 1>&2
	else
	    elmanOpt="-e \"$elmanModel\""
	fi
    fi
    sumStr="0"
    for testFile in "$workDir"/*.test.cv; do
	trainFile="${testFile%.test.cv}.train.cv"
	outputDir="$patternDir/$(basename "$testFile")"
	comm="train-tokenizer-from-UD-corpus.sh $trainOpts $elmanOpt \"$trainFile\" \"$patternFile\" \"$outputDir\""
	progress=$(( $progress + 1 ))
	if [ ! -z "$printProgress" ]; then
	    echo -en "\r$progress/$progressTotal" 1>&2
	fi
	eval "$comm"
	if [ $? -ne 0 ]; then
	    echo "Warning: an error occured when running '$comm', skipping" 1>&2
	else
	    comm="cat  \"$testFile\" | tokenize.sh $testOpts -c -I -o \"$outputDir/test.out\" \"$outputDir\"" # need option -n ???
	    eval "$comm"
	    if [ $? -ne 0 ]; then
		echo "Warning: an error occured when running '$comm', skipping" 1>&2
	    else
		perf=$(cat "$outputDir/test.out.eval" | cut -f "$evalCol")
		sumStr="$sumStr + $perf"
	    fi
	fi
    done
#    echo "PERF $sumStr" 1>&2
    meanperf=$(echo "scale=6; ( $sumStr ) / $nbFold" | bc) # calculate the mean perf
    echo -e "$patternNo\t$patternFile\t$meanperf" >>"$outputPerfFile"
    stopCriterion=$(noProgressAnymore "$outputPerfFile" "$stopCriterionMax")
    patternNo=$(( $patternNo + 1 ))
done
if [ ! -z "$printProgress" ]; then
    echo
fi

if [ ! -z "$outputModelDir" ]; then # train on full training data for best pattern
    bestPatternFile=$(cat "$outputPerfFile" | sort -g +1 -2 | tail -n 1 | cut -f 2)
    #    echo "bestPatternFile=$bestPatternFile" 1>&2
    if grep "%x\[.*,\s*2\s*\]" $bestPatternFile >/dev/null; then # pattern file contains at least one features with column 2, interpreted as requiring Elman features
	trainOpts="$trainOpts -e \"$elmanModel\""
    fi
    comm="train-tokenizer-from-UD-corpus.sh $trainOpts \"$input\" \"$bestPatternFile\" \"$outputModelDir\""
#    echo "$comm" 1>&2
    eval "$comm"
    if [ $? -ne 0 ]; then
	echo "An error occured when running '$comm'" 1>&2
	exit 6
    fi
fi

if [ -z "$keepFiles" ]; then
    rm -rf "$workDir"
else
    echo "Leaving all the files in '$workDir'" 1>&2
fi






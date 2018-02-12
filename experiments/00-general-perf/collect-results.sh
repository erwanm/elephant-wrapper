#!/bin/bash


function sizeTokensUD {
    local f="$1"
    untokenize.pl -B T -i -f UD -C 1 "$f" | cut -f 2 | grep T | wc -l
}

function roundVal {
    local v="$1"
    v=$(echo "$v * 100" | bc)
    printf "%.2f" "$v"
}

if [ $# -ne 2 ]; then
    echo "Usage: $0 <UD2 dir> <output tokenizers dir>" 1>&2
    echo  1>&2
    echo  "  Collects stats and prints a table indicating size and perf "1>&2
    echo  "  to STDOUT for all the datasets in UD 2.x (unit=tokens):"1>&2
    echo  "  <dataset> <size training set> <baseline recall> <model recall>"1>&2
    echo  "  <output tokenizers dir> contains all the trained tokenizers" 1>&2
    echo  "  computed with advanced-training-UD.sh." 1>&2
    echo  "   " 1>&2
    exit 1
fi

udDir="$1"
modelsDir="$2"

# get size of training sets in tokens
sizeFile=$(mktemp --tmpdir)
for d in "$udDir"/UD_*; do
    name=$(basename "$d")
    echo -ne "\r$name               " 1>&2
    trainFile=$(ls "$d"/*train*.conllu 2>/dev/null | head -n 1)
    if [ -z "$trainFile" ] ; then
	testFile=$(ls "$d"/*test*.conllu 2>/dev/null | head -n 1)
	if [ -z "$testFile" ]; then
	    echo "Error: no train or test file in $d" 1>&2
	    exit 1
	fi
	s=$(sizeTokensUD "$testFile")
	s=$(echo "$s * 0.8" | bc)
	s=$(printf "%.0f" "$s")
    else
	s=$(sizeTokensUD "$trainFile")
    fi
    echo -e "$name\t$s"
done | cut -f 2  >"$sizeFile"

# perf + elman
perfFile=$(mktemp --tmpdir)
for d in "$modelsDir"/UD_*; do
    name=$(basename "$d")
    echo -en "\r$name           " 1>&2
    baseperf=$(cat "$d/baseline.eval" | cut -f 8)
    modelperf=$(cat "$d/elephant.eval" | cut -f 8)
    patternFile=$(ls "$d"/elephant.elephant-model/*.pat | tail -n 1)
    if [ -z "$patternFile" ]; then
	echo "Error: cannot find pattern to use for training in '$d'" 1>&2
	exit 5
    fi
    if echo  "$patternFile" | grep "E1" >/dev/null; then
	elman=1
	name="$name [E]"
    else
	elman=0
    fi
    baseperf=$(roundVal "$baseperf")
    modelperf=$(roundVal "$modelperf")
    echo -e "$name\t$baseperf\t$modelperf"
done >"$perfFile"
echo 1>&2

tmpF1=$(mktemp --tmpdir)
tmpF2=$(mktemp --tmpdir)
cut -f 1 "$perfFile" >$tmpF1
cut -f 2- "$perfFile" >$tmpF2

echo -e "dataset\ttrainingSetSize\tbaselineRecall\ttrainedTokenizerRecall"
paste $tmpF1 "$sizeFile" $tmpF2

rm -f "$sizeFile" "$perfFile" $tmpF1 $tmpF2

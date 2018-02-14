#!/bin/bash



progName=$(basename "$BASH_SOURCE")

scriptDir=$(dirname "$BASH_SOURCE")

languages="cs de el es fr hu it pl pt ro sl sv"
nbSentTask=10000


function usage {
  echo
  echo "Usage: $progName [options] <VMWE-trained models dir> <Europarl data dir> <output dir>"
  echo
  echo "  Tokenizes the relevant Europarl datasets with the models learned from the VMWE17"
  echo "  Shared Task data."
  echo "  The tasks to run for every language are written to <output dir>/tasks; after all "
  echo "  the tasks have been run, the full tokenized output for every dataset can be "
  echo "  obtained with:"
  echo "  for lang in <output dir>/*; do echo "\$lang"; cat \"\$lang\"/tokenized/batch.* >\"\$lang.tok\""
  echo
  echo "  - Requires that the models have been trained from VMWE17 data using script:"
  echo "    $scriptDir/train-tokenizers-from-vmwe17.sh"
  echo "  - Requires the (uncompressed) Europarl data available in <Europarl data dir>;"
  echo "    The Europarl data can be downloaded from:"
  echo "    http://www.statmt.org/europarl/v7/europarl.tgz"
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -l <languages> list of space-separated language ids to process (use quotes);"
  echo "       default: '$languages'."
  echo "    -n <nb sentences by task> default: $nbSentTask."
  echo
}




OPTIND=1
while getopts 'hl:n:' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"l" ) languages="$OPTARG";;
	"n" ) nbSentTask="$OPTARG";;
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
vmweModelsDir="$1"
epDir="$2"
outputDir="$3"

[ -d "$outputDir" ] || mkdir "$outputDir"


for lang in $languages; do
    mkdir "$outputDir/$lang"
    mkdir "$outputDir/$lang/ep-chunks"
    mkdir "$outputDir/$lang/tokenized"
    echo "Splitting EP $lang..." 1>&2
    split -d -l $nbSentTask "$epDir/europarl-v7.${lang}-en.${lang}" "$outputDir/$lang/ep-chunks/batch."
    for f in "$outputDir/$lang/ep-chunks"/batch.*; do
	output="$outputDir/$lang/tokenized/$(basename "$f")"
	echo "tokenize-line-by-line.sh -l \"$vmweModelsDir\" \"$f\" \"$output\" >\"$output.err\""
    done
done

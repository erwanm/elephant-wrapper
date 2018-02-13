#!/bin/bash



progName=$(basename "$BASH_SOURCE")

scriptDir=$(dirname "$BASH_SOURCE")


generatePatternsString=""
patternsFile=""




function usage {
  echo
  echo "Usage: $progName [options] <VMWE17 dir> <output dir>"
  echo
  echo "  Trains models from the VMWE 17 Shared Task data, available at:"
  echo "  https://gitlab.com/parseme/sharedtask-data."
  echo "  The tasks to run for every language are written to <output dir>/tasks"
  echo
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -g <parameters for generating patterns> parameter string which specifies"
  echo "       which patterns are generated; transmitted as option -s when calling"
  echo "       script generate-patterns.pl; call this script with -h for more details."
  echo "    -i <list of patterns file> use this specific list of pattern files instead"
  echo "       of generating the list automatically."
  echo
}




OPTIND=1
while getopts 'hg:i:' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"g" ) generatePatternsString="$OPTARG";;
	"i" ) patternsFile="$OPTARG";;
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
inputDir="$1"
outputDir="$2"

[ -d "$outputDir" ] || mkdir "$outputDir"

if [ -z "$patternsFile" ]; then
    patternsFile="$outputDir/patterns.list"
    rm -rf "$outputDir/patterns"
    mkdir "$outputDir/patterns"
    opts=""
    if [ ! -z "$generatePatternsString" ]; then
	opts="-s \"$generatePatternsString\""
    fi
    echo "* Generating patterns to '$patternsFile';" 1>&2
    comm="generate-patterns.pl $opts \"$outputDir/patterns/\" >\"$patternsFile\""
    eval "$comm"
    if [ $? -ne 0 ]; then
	echo "An error occured when running '$comm', aborting" 1>&2
	exit 5
    fi
fi

for trainFile in "$inputDir"/*/*train.parsemetsv; do
    lang0=$(dirname "$trainFile")
    lang=$(basename "$lang0")
    echo -en "\rConverting to IOB for $lang" 1>&2
    untokenize.pl -i -f parseme -C 1 -B T "$trainFile" >"$outputDir/$lang.iob"
    comm="advanced-training.sh -q -i -m 0 -e \"$outputDir/$lang.iob\" \"$patternsFile\" \"$outputDir/$lang\""
    echo "$comm"
done > "$outputDir/tasks"
echo  1>&2

#!/bin/bash



progName=$(basename "$BASH_SOURCE")


ud2Dir=""
ud2Location="https://lindat.mff.cuni.cz/repository/xmlui/bitstream/handle/11234/1-1983/ud-treebanks-v2.0.tgz"
outputDir=""


function usage {
  echo
  echo "Usage: $progName [options] <output directory>"
  echo
  echo "  Trains multiple tokenizers using the Universal Dependencies 2.0 corpus, with"
  echo "  the same options as the original experiment (paper submitted at LREC 18)."
  echo "  Expected duration: 2 hours."
  echo
  echo "  Options:"
  echo "    -h this help"
  echo "    -a <UD2 address>; default: $ud2Location"
  echo "    -i <UD2 directory>; default: UD2 data downloaded and extracted."
  echo
}




OPTIND=1
while getopts 'ha:i:o:' option ; do 
    case $option in
	"h" ) usage
 	      exit 0;;
	"a" ) ud2Location="$OPTARG";;
	"i" ) ud2Dir="$OPTARG";;
	"o" ) outputDir="$OPTARG";;
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

outputDir="$1"

[ -d "$outputDir" ] || mkdir "$outputDir"

if [ -z "$ud2Dir" ]; then
    echo 1>&2
    echo "* Downloading UD2 data from $ud2Location..." 1>&2
    wget -O "$outputDir/ud-treebanks-v2.0.tgz" "$ud2Location"
    echo 1>&2
    echo "* Extracting archive in $outputDir..." 1>&2
    pushd "$outputDir" >/dev/null
    tar xfz ud-treebanks-v2.0.tgz
    popd >/dev/null
    ud2Dir="$outputDir/ud-treebanks-v2.0"
fi

if [ ! -d "$ud2Dir" ]; then
    echo "Error: directory $ud2Dir does not exist" 1>&2
    exit 2
fi

echo 1>&2
echo "* Training tokenizers..." 1>&2
comm="train-multiple-tokenizers.sh -e -m 0 -g 3,8,1,2,2,1 ud-treebanks-v2.1/ $outputDir"
eval "$comm"

#!/bin/bash
#. ${BASH_SOURCE%/*}/bedfriend.sh 
B=${BASH_SOURCE##*/};
usage="
FUNCT: sum scores of reads overlapping with target entries
USAGE: $B [options] <target> <read>
 [options] 
	-h : help
	-s : count same strand
	-z : exclude zero counts 
"

S=""; Z=0;
while getopts "hsz" arg; do
	case $arg in
		z) Z=1;;
		s) S="-s";;
		?) echo "$usage"; exit 1;;
	esac
done
shift $(( OPTIND - 1 ))
if [ $# -ne 2 ];then echo "$usage"; exit 1; fi

TARG=$1;
READ=$2;

echo "$B $@" >&2
## 
intersectBed -a $TARG -b $READ -wa -wb $S \
| groupBy -g 1,2,3,4,5,6 -c 11 -o sum \
| awk -v OFS="\t" '{ print $1,$2,$3,$4,$5,$6,$7;}' 
## handle zero counts 
if [ $Z = 0 ]; then
    intersectBed -a $TARG -b $READ $S -v -wa \
    | awk -v OFS="\t" '{ print $1,$2,$3,$4,$5,$6,0;}' 
fi


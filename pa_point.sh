#!/bin/bash 
B=${BASH_SOURCE##*/};
cmd="#$B $@"

M="single"; ## paired

usage="
FUNCT: modify read alignments and sum the phred scores 
USAGE: $THIS $FUNCNAME [options] <bam>
    [options]:
     -q <int> : minimum MAPQ threshold 0-255 (default 0)
     -Q <int> : upper open boundary of MAPQ threshold 0-255 
	 -m <str> : select sequencing protocol  
		single : single-end oligo dT (default)
		paired : paired-end system (take first segment in the template) 
	 -c <str> : scoring scheme : count, phred (default)
"
M="single"
C="phred"
OPTIONS="";
FILTER="";
while getopts "hq:Q:m:c:" arg;do
	case $arg in
		q) OPTIONS="$OPTIONS -q ${OPTARG}";;
		Q) FILTER="$FILTER | awk -v Q=${OPTARG} -v OFS='\t' '\$5<Q'";;
		m) M=${OPTARG};; 
		c) C=${OPTARG};;
		?) echo "$usage"; exit 1;
	esac
done; shift $(( OPTIND - 1 ));
if [ $# -lt 1 ];then echo "$usage"; exit 1; fi

## see https://gist.github.com/davfre/8596159 for flag options
OPTIONS="$OPTIONS -F 0x4"; ## get mapped
if [ $M = "paired" ];then
	OPTIONS="$OPTIONS -f 0x2 -f 0x40 "; ## take properly paired, first segment in the template 
fi

cmd="$cmd
	samtools view -b $OPTIONS $@ | bamToBed $FILTER | bed_shift.sh -5w - | bed_sum.sh -c $C -
"
echo "$cmd" >&2;
eval "$cmd"

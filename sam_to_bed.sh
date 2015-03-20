#!/bin/bash
B=${BASH_SOURCE##*/};
cmd="$B $@";
##links
## http://left.subtree.org/2012/04/13/counting-the-number-of-reads-in-a-bam-file/
## http://bowtie-bio.sourceforge.net/bowtie2/manual.shtml#paired-inputs : AS:, XS:

usage="
FUNCT: convert sam to bed6 
USAGE: $B [options] <sam> 
 [options] 
	-h : help
	-u : pass unique hits 
	-U : pass non-unique hits 
	-p : pass properly paired hits 
	-l : first segment in the template 
	-r : last segment in the template 
	-q <int> : MAPQ threshold  (default 0)
"
FLAGS="-F 0x4"; # only report segments mapped 
FILTER=""; # nofilter
Q=0;
while getopts "q:uUlrp" arg; do
	case $arg in
		u) FILTER="$FILTER | fgrep -v -w XS:i";; ## sometimes -f 0x100 flag for multiple hits does not work
		U) FILTER="$FILTER | fgrep -w XS:i";;
		p) FLAGS="$FLAGS -f 0x2";; ## properly paired
		q) Q=${OPTARG};;
		l) FLAGS="$FLAGS -f 0x40";;
		r) FLAGS="$FLAGS -f 0x80";;
		?) echo "$usage"; exit 1;;
	esac
done
shift $(( OPTIND - 1 ))

if [ $# -ne 1 ];then echo "$usage"; exit 1; fi
cmd="#$cmd :
	samtools view -q $Q $FLAGS $1 $FILTER | sam_to_bed.pl
"
echo "$cmd" >&2
eval "$cmd";

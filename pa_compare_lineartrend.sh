#!/bin/bash
. util.sh
THIS=${BASH_SOURCE##*/}
usage="
USAGE: $THIS [options] <target> <ctr_cluster> <trt_cluster>
	[options]:
	-F <bed> : filter regions in which counts are ignored
"
echo "#$THIS $@" >&2
FILT="cat";
while getopts "hF:" arg
do
	case $arg in 
		F) FILT="intersectBed -a stdin -b ${OPTARG} -v -s";;
		?) echo "$usage"; exit 1;;
	esac
done
shift $(( OPTIND -1 ))
if [ $# -lt 3 ];then
	echo "$usage"; exit 1;
fi

filter(){
	eval $FILT
}
	tmpd=`makeTempDir`;
	cat $2 | awk -v OFS="\t" '{print $1,$4,$4+1,$4 ";" $2 "," $3, $5, $6;}' | filter > $tmpd/a
	cat $3 | awk -v OFS="\t" '{print $1,$4,$4+1,$4 ";" $2 "," $3, $5, $6;}' | filter > $tmpd/b
	bed_sex.sh -w 100 -s $1 $tmpd/a $tmpd/b \
		| perl -ne 'chomp; my @a=split/\t/,$_; 
			my @b=split/;/,$a[6]; my @c=split/;/,$a[7];
			print $b[0],"\t",$b[2],"\t",$c[0],"\t",$c[2],"\t",join ("\t",@a),"\n";
		' | test_lineartrend.sh - \
		| awk -v OFS="\t" '{ s=1; if($10=="-"){ s=-1;} print $5,$6,$7,$8,$9,$10,$1,$2,$3,$4,s*$(NF-1),$(NF);}' \
		| padjust.sh - -1 



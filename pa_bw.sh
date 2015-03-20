#!/bin/bash
usage="
	$0 <pa> <chrom.size> <out>
"

if [ $# -ne 3 ]; then
	echo "$usage"; exit;
fi

makeTemp(){
    mktemp 2>/dev/null || mktemp -t $0;
}
make_bw(){
    PA=$1; CSIZE=$2; OUT=$3;
    tmp=`makeTemp`;
    cat $PA | awk -v OFS="\t" '{if($6=="+"){ print $1,$2,$3,$5;}}' | sort -k1,1 -k2,3n > $tmp
    bedGraphToBigWig $tmp $CSIZE ${OUT}_fwd.bw
    cat $PA | awk -v OFS="\t" '{if($6=="-"){ print $1,$2,$3,$5;}}' | sort -k1,1 -k2,3n > $tmp
    bedGraphToBigWig $tmp $CSIZE ${OUT}_bwd.bw
}

make_bw $1 $2 $3



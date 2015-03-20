#!/bin/bash
THIS=${BASH_SOURCE##*/};
usage="
USAGE: $THIS <command>
	<command>:
	 get3utr <gtf file>
"

get3utr(){
	cat $1 | gtf_to_bed12.sh |bed12_to_lastexon.sh | perl -ne 'chomp;my @a=split/\t/,$_;
		$a[3]=~s/::ENST\d+//g; 
		$a[0]=$a[0]."@".$a[3];  ## avoid merging 3utrs of different genes
		$a[4]=0; 
		print join("\t",@a),"\n";' \
	| sort -u -k1,1 -k2,3n -k6,6 \
	| mergeBed -i stdin -s -c 4,5,6 -o distinct,count,distinct \
	| awk -v OFS="\t" '{ split($1,a,"@");$1=a[1];print $0;}'
}

if [[ $# -eq 2 && $1 = "get3utr" ]];then
	get3utr ${@:2}
	exit 0
fi
echo "$usage"; exit 1;


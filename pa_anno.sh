#!/bin/bash
THIS=${BASH_SOURCE##*/};
THIS_D=${BASH_SOURCE%/*};
usage="
USAGE: $THIS <command>
	<command>:
	 get3utr <gtf file> 
	 getGene <gtf file>
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
getGene(){
	cat $1 | gtf_to_bed12.sh | perl -ne 'chomp;my @a=split/\t/,$_;
		$a[3]=~s/::ENST\d+//g; 
		$a[0]=$a[0]."@".$a[3];  ## avoid merging 3utrs of different genes
		$a[4]=0; 
		print join("\t",@a),"\n";' \
	| sort -u -k1,1 -k2,3n -k6,6 \
	| mergeBed -i stdin -s -c 4,5,6 -o distinct,count,distinct \
	| awk -v OFS="\t" '{ split($1,a,"@");$1=a[1];print $0;}'
}

ensgToGeneName(){
	cat $1 | perl -e 'use strict;
		my %eg=();
		my $file=$ARGV[0];
		open(F,$file) or die;
		while(<F>){ my ($k,$v)=split /\s/,$_; $eg{$k}=$v; }
		close(F);
		while(<STDIN>){ chomp;
			if($_=~/(ENSG\d+)/){
				my $tmp=$eg{$1};
				if(defined $tmp){
					$_=~s/ENSG\d+/$tmp/g;
				}
			}
			print $_,"\n";
		}
	' $THIS_D/data/hg19/ensgToGenename.txt 
}
if [[ $# -eq 2 && $1 = "get3utr" ]];then
	get3utr ${@:2}; exit 0
elif [[ $# -eq 2 && $1 = "getName" ]];then
	ensgToGeneName ${@:2}; exit 0
elif [[ $# -eq 2 && $1 = "getGene" ]];then
	getGene ${@:2}; exit 0
fi
echo "$usage"; exit 1;


#!/bin/bash
THIS=${BASH_SOURCE##*/};
D=${BASH_SOURCE%/*}; if [ $D = "" ];then D="."; fi
#. $D/nb_filter.sh

usage="
FUNCTION: pass real pAs ( Prob(site|real) > .5)
USAGE: $THIS <bed> <fasta>
"
if [ $# -ne 2 ];then echo "$usage"; exit 1; fi

cmd="$THIS $@";
echo "#$cmd" >&2
$D/bed_seq.sh -s -l 39 -r 30 $1 $2 \
| perl -ne 'chomp;my @a=split/\t/,$_;
        my $s=pop @a; $s=~ s/,//g;
        print join("@",@a),"\t",$s,"\n"; '\
| $D/pa_filter_nb.sh predict - \
| perl -e 'use strict; my $offset=40; my %S=();
	my $total_sum=0; my $passed_sum=0;
	my $total_pos=0; my $passed_pos=0;
	while(<>){ chomp;
		chomp;my ($bed,$seq,$pos,$score) = split/\t/,$_;
		next if $score eq "";
		my @a=split /@/,$bed;
		$total_pos ++;
		$total_sum += $a[4];
		if($#a >=5 && $a[5] eq "-"){
			my @b=split/,/,$score;
			$score = join(",",reverse @b);
		}
		if($score > 0.5){
			print join( "\t",@a),"\t$score\n";
			$passed_pos ++;
			$passed_sum += $a[4];
		}
	}
	print {*STDERR} "\ttotal_reads:$total_sum,passed_reads:$passed_sum,total_pos:$total_pos,passed_pos:$passed_pos\n"; 
'

#echo -e "chr12\t6647462\t6647564" | filter.sh - /media/db/Ucsc/hg19/

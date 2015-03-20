#!/bin/bash
THIS=${BASH_SOURCE##*/};

bowtie(){
cat $1 | perl -ne 'chomp; 
	if($_=~/==> (.+)\/log.bowtie <==/){ $name=$1;
	}elsif($_=~/(\d+) reads/){ $tot=$1;
	}elsif($_=~/(\d+).+aligned concordantly exactly 1 time/){ $read_u+=2*$1; 
	}elsif($_=~/(\d+).+aligned concordantly >1 times/){ $read_m+=$1; 
	}elsif($_=~/(.+) aligned exactly 1 time/){ $read_u+=$1;
	}elsif($_=~/(.+) aligned >1 times/){ $read_m+=$1; } 
	if($_=~/(.+) overall alignment rate/){ 
		print "$name\t$tot\t$read_u\t$read_m\t",($read_m+$read_u)/$tot*100,"\t=$1\n";
	}' 
}
point(){
	tmpd=`mktemp -d`;
	for f in "$@";do
		awk -v N=$f -v OFS="\t" '{S1 ++; S2 += $5;}END{ print N,S1,S2; }' $f;
	done
}
bam(){
	echo -e "data total mapped Q10" | tr " " "\t";
	for f in "$@";do
		n=${f%/*.bam};
		paired=`samtools view -F 0x4 -f 0x2 -c $f`
		PAIR="";
		if [ $paired -gt 0 ];then PAIR="$PAIR -f 0x40 "; fi
		total=`samtools view $PAIR -c $f`
		mapped=`samtools view $PAIR -F 0x4 -c $f`
		q10=`samtools view $PAIR -F 0x4 -c -q 10 $f`
		echo "$n $total $mapped $q10 $paired" | tr " " "\t" 
	done;
}
cor1(){
	R --no-save -q -e 'tt=read.table("stdin",header=F);cat(paste("res:",cor(tt[,1],tt[,2],method="spearman"),"\n",sep="\t")) ' | awk '$1=="res:"{ print $2;}'
}
cor(){
	tmpd=`mktemp -d`;
	cat $1 > $tmpd/a
	cat $2 > $tmpd/b
	nf_a=`head -n 10 $tmpd/a| awk 'END{ print NF;}';`
	nf_b=`head -n 10 $tmpd/b| awk 'END{ print NF;}';`
	intersectBed -a $tmpd/a -b $tmpd/b -wa -wb -s | cut -f 5,$(( nf_a + 5 )) > $tmpd/ab 
	intersectBed -a $tmpd/a -b $tmpd/b -wa -wb -s -v | awk -v OFS="\t" '{print $5,0;}' > $tmpd/a_only
	intersectBed -b $tmpd/a -a $tmpd/b -wa -wb -s -v | awk -v OFS="\t" '{print 0,$5;}' > $tmpd/b_only 
	ab=(`awk -v OFS="\t" '{S1+=$1;S2+=$2; N++;}END{ print N,S1,S2;}'  $tmpd/ab` )
	a=(`awk -v OFS="\t" '{S1+=$1;S2+=$2; N++;}END{ print N,S1,S2;}'  $tmpd/a_only` )
	b=(`awk -v OFS="\t" '{S1+=$1;S2+=$2; N++;}END{ print N,S1,S2;}'  $tmpd/b_only` )
	cor_all=`cat $tmpd/ab $tmpd/a_only $tmpd/b_only | cor1`
	cor_inter=`cat $tmpd/ab | cor1`
	#echo "$n_ab $n_a $n_b";
	echo -e "\tcor:$cor_all,cor.inter:$cor_inter";
}
comp(){
	echo -e "file\tup\tdown"
	for f in "$@";do
		up=`awk '$(NF)<=0.05 && $(NF-2) < 0' $f | wc -l`
		dn=`awk '$(NF)<=0.05 && $(NF-2) > 0' $f | wc -l`
		echo -e "$f\t$up\t$dn";
	done 
}
usage="
USAGE : 
	report cor <bed> <bed>	: calc spearman correlation 
	report point <bed> 		: report points
	report bam <bam>        : calc mapping rate and multi-hits ...
	report comp <file>      : output of linear trend or fisher's exact tests  
" 
if [ $# -lt 2 ]; then
	echo "$usage" >&2; exit 1
fi

if [ $# -gt 1 ];then
	echo "#$THIS $@" >&2
	eval "$1 ${@:2}"
fi

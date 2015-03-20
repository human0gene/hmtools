#!/bin/bash 
makeTemp(){
    mktemp 2>/dev/null || mktemp -t $0;
}
makeTempDir(){
    mktemp -d 2>/dev/null || mktemp -d -t $0;
}

plot_cluster(){
cmd='
	str2a<-function(x){
		lapply(strsplit(as.character(x),","),as.numeric)[[1]];
	}
	tt=read.table("stdin",header=F,sep="\t");
	x=str2a(tt[1,1]);
	y=str2a(tt[1,2]);
	ss=str2a(tt[1,3]);
	ee=str2a(tt[1,4]);
	cc=str2a(tt[1,5]);
	zz=str2a(tt[1,6]);
	png("out.png")
	ylim=c(min(y),max(zz));
	plot(x,y,col=1,ylim=ylim);
	points(cc,zz,col=2);
	dev.off();
'
	tmp=`makeTemp`;
	echo "$cmd" > $tmp
	R --no-save -q -f $tmp
	display out.png
}

foreach(){
# usage: foreach "<file>" '<func>'
    OIFS=$IFS; IFS=$'\n\r';
    EALL=( `cat "$1" ` ); FUNC=$2;
    for E in ${EALL[@]};do
        if [ ${E:0:1} != "#" ]; then
            IFS=$OIFS; set $E;
            eval "$FUNC";
            IFS=$'\n\r';
        fi
    done;
    IFS=$OIFS;
}
#
#echo "1 2
#3 4
#5 6" | foreach - 'echo $1';

getChroms(){
    ifile=$1;
    if [ "${ifile##*.}" = "bam" ]; then
        if [ ! -f $ifile.bai ]; then
            echo "making bam index " >&2
            samtools index $ifile;
        fi
        samtools idxstats $ifile | awk '$1 != "*" && $3 > 0 {print $1;}';
    else
        cut -f 1 $ifile | sort -u;
    fi
}

foreachChrom(){
usage=" 
    usage: $FUNCNAME <bed|bam> <function>
    function and its arguments need to be quoted
     ex)  $FUNCNAME <bam> \"grep chr22 | head\"
"
    if [ $# -ne 2 ]; then echo "$usage"; return; fi
    IFILE=$1; FUNC=$2;
    chroms=( `getChroms $IFILE` )
    for chrom in ${chroms[@]}; do
        echo $chrom >&2
        if [ ${IFILE##*.} = "bam" ]; then
            samtools view -b $IFILE $chrom | eval $FUNC
        else
            awk -v CHROM=$chrom '$1 == CHROM' $IFILE | eval $FUNC
        fi
    done
}



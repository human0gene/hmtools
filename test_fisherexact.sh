#!/bin/bash
usage(){
echo -e "usage:
	${0##*/} [options] <file>
	 [options]
		-g <columns> : specify the columns (1-based) for the grouping (default 1)
		-c <columns> : specify the columns (1-based) for control and treatment counts (default 2,3)
"
	exit 1;
}
makeTemp(){
    mktemp 2>/dev/null || mktemp -t $0;
}
runRStdio(){
	cmd=$1;
	tmpout=`makeTemp`;tmpcmd=`makeTemp`;	
	cmd=${cmd/stdout/$tmpout}
	echo "$cmd" > $tmpcmd
	R --no-save -f $tmpcmd >&2; 
	cat $tmpout
}
quote(){ 
	perl -ne 'chomp; my @a = map{ "\"$_\"" } split /,/,$_; print join ",",@a; '; 
}
GRS=1;
CLS="2,3";
while getopts "hc:g:" arg
do
	case $arg in
		h) usage;;
		c) CLS=${OPTARG};;
		g) GRS=${OPTARG};;
	esac
done
shift $(( OPTIND - 1 ))
if [ $# -lt 1 ]; then usage; fi

## INPUT: comma separated control and treatment EI file ( bed6 + exclusion + inclusion)
## OUTPUT: bed6 + logFC + pvalue 
rcmd='
	cols=c(CLS);
	grp=c(GRS);
	tt=read.table("stdin",header=F);
	#print(tt[1:10,]);
	if(length(grp) == 1){
		G=tt[,grp];
	}else{
		G=apply(tt[,grp],1,function(x){ paste(x,collapse="|");});
	}	
	gs=ave(1:length(G),G,FUN=length); ## group sum
	G=G[gs>1]; tt=tt[gs>1,];
	m=tt[,cols];
	M=apply(m,2,function(x){ ave(x,G,FUN=sum)}) ## group sum
	p=unlist(apply(cbind(m,M-m),1,function(x){ fisher.test(matrix(x,byrow=F,nrow=2))$p.value }))
	fdr=p.adjust(p,method="fdr")
	log2fc= log2((0.5+m[,2])/(m[,1]+0.5)*M[,2]/M[,1]);
	tt$log2FC=log2fc; tt$pval=p; tt$FDR=fdr;
	write.table(file="stdout",tt,row.names=F,col.names=T,quote=F,sep="\t");
'
rcmd=${rcmd/CLS/$CLS}
rcmd=${rcmd/GRS/$GRS}
cat $1 | runRStdio "$rcmd" 
#data="1\t10\t20\n1\t10\t10"
#echo -e "$data" | runRStdio "$rcmd"



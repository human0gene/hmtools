#!/bin/bash
usage="
USAGE: ${0} [options] <bed>
 [options] 
	-5 <int> : trim 5'end 
	-3 <int> : trim 3'end
	-p <str> : pass matched seq at 5'end
	-t       : trim until non-T meets (to remove dT barcoding)
	-m <int> : minimum length after triming (default 20)
"
if [ $# == 0 ]; then echo "$usage"; exit 1; fi

FIVE=0;THREE=0;TT=0;MINL=20; PATT="";
while getopts "h5:3:m:tp:" arg
do
    case $arg in
        h) echo "$usage"; exit 1 ;;
        5) FIVE=${OPTARG} ;;
        3) THREE=${OPTARG};;
		p) PATT=${OPTARG};;
        m) MINL=${OPTARG};;
		t) TT=1;;
		?) echo "$usage"; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))
CMD="# CMD: $BASH_SOURCE $@" 
IN=$1;

cat $IN | awk -v OFS="\t" '{
	if(NR % 4 == 0){ print $0;
	}else{ printf("%s\t",$0); }
}' | awk -v FS="\t" -v PATT=$PATT -v TT=$TT -v FIVE=$FIVE -v THREE=$THREE -v MINL=$MINL '{ 
	S=substr($2,FIVE+1,length($2)-FIVE-THREE);
	Q=substr($4,FIVE+1,length($4)-FIVE-THREE);
	E=0;
	if(TT == 1){
		L=split(S,a,"");
		for( i=1; i<=L; i++){ if(a[i] != "T"){ E=i; break; } }
	}
	if (length(S)-E >= MINL && substr(S,0,length(PATT)+1)==PATT){
		print $1;
		print substr(S,E,length(S));
		print $3;
		print substr(Q,E,length(Q));
	}
}'
#

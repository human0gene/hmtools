#!/bin/bash 
. util.sh
THIS=${BASH_SOURCE##*/}
echo "#$THIS $@" >&2
usage="
FUNCTION: Starts Ends and Scores relative to <target>
Usage: $THIS [options] <target> <bed> [<bed>..]
	[options]:
	 -w <int> : flanking window (default 1000)
	 -s       : only consider reads on the same strand as target 
	 -S       : only consider reads on the reverse strand as target 
	 -f <filter> : any script filter or modifier  
"

#TMP=`mktemp -d`;
TMP=tmp
mkdir -p $TMP;
OPTIONS="";
FILTER="";
while getopts "hw:sS" arg; do
	case $arg in
		w) OPTIONS="$OPTIONS -w ${OPTARG}";;
	    s) OPTIONS="$OPTIONS -sm";;
	    S) OPTIONS="$OPTIONS -Sm";;
		?) echo "$usage";exit 1;;	
	esac
done 
shift $(( OPTIND -1 ))
if [ $# -lt 2 ]; then
	echo "$usage"; exit 1;
fi

fa=$TMP/a; fb=$TMP/b; F=( $@ );
cat $1 > $fa;
nf=`head -n 1 $fa | awk '{print NF;}'`
for f in ${F[@]:1};do
	windowBed $OPTIONS -a $fa -b $f \
		| awk -v C=$nf -v OFS="\t" '{ print $1,$2,$3,$4,$5,$6,$(C+2)-$2,$(C+3)-$2,$(C+5);}' \
		| groupBy -g 1,2,3,4,5,6 -c 7,8,9 -o collapse,collapse,collapse \
		| awk -v OFS="\t" '{ print $1,$2,$3,$4 "|" $7 ";" $8 ";" $9 ,$5,$6;}' > $fb
	mv $fb $fa
done
cat $fa | perl -ne 'chomp; my @a=split/\t/,$_;
	my @b=split /\|/,$a[3]; $a[3]=shift @b;
	my $ok=0;	
	foreach my $bi (@b){ if($bi != 0){ $ok=1; break}} 

	if ($ok==1){
		print join( "\t",@a);
		foreach my $bi (@b){ print "\t",$bi; }
		print "\n";
	}
'

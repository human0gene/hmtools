#!/bin/bash
B=${BASH_SOURCE##*/}; cmd="$B $@";
usage="
USAGE: $B [options] <bed> [<bed>]
 [options]:
 -c <method> : summing method (default asis)
	<method>=[phred|asis|count]
"
if [ $# == 0 ]; then echo "$usage"; exit 1; fi
COUNT="asis";
while getopts "hv:c:" arg
do
    case $arg in
        h) echo "$usage"; exit 1 ;;
		c) COUNT=${OPTARG};;
		?) echo "$usage"; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))
FILES=( $@ );
sumscore(){
	sort -k1,1 -k2,3n -k6,6 | groupBy -g 1,2,3,4,6 -c 5 -o sum \
	| awk -v OFS="\t" '{ print $1,$2,$3,$4,$6,$5; }'
}
prepro(){
	awk -v COUNT=$1 -v OFS="\t" '{ 
		if(COUNT=="phred"){ 
			if($5==0){ 
				$5 = 0.1; # assume hits >10 times
			}else{
				$5=1-exp( - $5/10 * log(10)); ## phred to prob
			}
		}else if(COUNT=="count"){ $5=1; }
		$4=".";# ignore read name 
		print $0;
	}'
}
tmpd=`mktemp -d`;
cmd="#$cmd :
	if [ ${#FILES[@]} -gt 1 ];then
		cat ${FILES[0]} | prepro $COUNT | sumscore > $tmpd/a; 
		for f in ${FILES[@]:1};do
			cat \$f | prepro $COUNT | sumscore > $tmpd/b
			cat $tmpd/a $tmpd/b | prepro asis | sumscore > $tmpd/c
			mv $tmpd/c $tmpd/a
		done
		cat $tmpd/a
	else
		cat ${FILES[0]} | prepro $COUNT | sumscore 
	fi	
"
echo "$cmd" >&2;
eval "$cmd";

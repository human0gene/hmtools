#!/bin/bash
. util.sh
MIND=20; #minimum distance between peaks 
D=${BASH_SOURCE/%*}
B=${BASH_SOURCE##*/}
usage="
FUNCT: cluster proximal points 
USAGE: $B [options] <bed> 
 [options]:
	-d <int> : minimum distance between peak centers (default $MIND);
"

while getopts "hd:" arg; do
	case $arg in
		d) MIND=${OPTARG};;
		?) echo "$usage"; exit 1;;
	esac
done
shift $(( OPTIND - 1));
if [ $# -lt 1 ]; then
	echo "$usage";exit 1;
fi


echo "#$B $@" >&2
	tmpd=`makeTempDir`;
	#tmpd='tmpd'; #mkdir -p $tmpd
	#sort -k1,1 -k2,3n $1 \
	bed_sum.sh "$@" \
	| mergeBed -i stdin -s -c 6,2,5 -o distinct,collapse,collapse -d $MIND > $tmpd/a.bed

	cat $tmpd/a.bed | awk -v OFS="\t" -v M=$MIND '
	$3-$2 < M {
		L=split($5,a,","); split($6,b,",");
		n=0; s=0; y=0;
		for(i=1; i<=L; i++){
			s += a[i] * b[i];
			n += b[i];
		}
		print $1,$2,$3,int(s/n),n,$4;
	}'  > $tmpd/b.bed

	cat $tmpd/a.bed | awk -v M=$MIND '$3-$2 >= M' \
	 |  ${D}cluster_1d_kmeans.sh -d $MIND -c 5,6 - \
	 | awk -v OFS="\t" '{
		L=split($7,a,","); split($8,b,","); split($9,c,","); split($10,d,",");
		for(i=1;i<=L;i++){
			print $1,a[i],b[i],int(c[i]),d[i],$4;
		}
	}' > $tmpd/c.bed
	cat $tmpd/b.bed $tmpd/c.bed | sort -k1,1 -k2,3n


#!/bin/bash
. util.sh
THIS=${BASH_SOURCE##*/}
usage="
USAGE: $THIS <target> <ctr_cluster> <trt_cluster>
"
if [ $# -ne 3 ];then
	echo "$usage"; exit 1;
fi
echo "#$THIS $@" >&2
target=$1;
ctr=$2;
trt=$3; 


groupBed(){
    cmd='use strict;
        while(<STDIN>){
            chomp; my @a=split/\t/,$_;
            my $name = join("|",@a[0..5]);
            $a[9] = $name;
            print join("\t",@a[6..11]),"\n";
        }
    '
    intersectBed -a $1 -b $2 -wa -wb -s | perl -e "$cmd"
}

tmpd=`makeTempDir`
groupBed $target $ctr > $tmpd/ctr_1
groupBed $target $trt > $tmpd/trt_1
intersectBed -a $tmpd/ctr_1 -b $tmpd/trt_1 -wa -wb -f 1 -s \
 | awk -v OFS="\t" '{ print $1,$2,$3,$4,$5+$11,$6,$5,$11;}'\
 | test_fisherexact.sh -g 4 -c 7,8 -



#!/bin/bash 
THIS=${BASH_SOURCE##/}
usage="
USAGE: $THIS <ucsc file .txt>
"
if [ $# -ne 1 ];then
	echo "$usage"; exit 1;
fi
cat $1 | perl -ne ' chomp; my @aa = split /\s/,$_;
    if(scalar @aa < 12){ die "this is not a 12 columned bed file $!";}
    my ($bin,$name,$chr,$strand,$start,$end,$thickStart,$thickEnd,$blockCount,$blockStarts,$blockEnds,$id,$name2) = split /\s/, $_;
    my $itemRgb = "255,0,0";
    my $score = 0;

    if(defined $name2){
        $name = $name."|".$name2;
    }
    print $chr,"\t",$start,"\t",$end,"\t",$name,"\t",$score,"\t",$strand,"\t",$thickStart,"\t",$thickEnd,"\t",$itemRgb,"\t",$blockCount,"\t";
    my @ss = split /,/,$blockStarts;
    my @ee = split /,/,$blockEnds;
    for(my $i=0;$i<$blockCount;$i++){
        my $length = $ee[$i]-$ss[$i];
        print $length,",";
    }
    print "\t";
    for(my $i=0;$i<$blockCount;$i++){
        my $relstart = $ss[$i]-$start;
        print $relstart,",";
    }
    print "\n";
'



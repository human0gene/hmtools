#!/usr/bin/perl -w
use strict;
my $usage = " usage: $0 -i <ucsc file> 
    ucsc file: refer to http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/refGene.sql
";

if(scalar @ARGV < 2){ print $usage,"\n";exit(-1);}

my $fin;
my $fh;

while(@ARGV){
    my $e = shift @ARGV;
    if($e eq "-i"){ $fin = shift @ARGV;}
    else{ print $usage,"\n";exit(-1);}
}
if($fin eq "stdin"){ $fh = *STDIN;
}else{ open($fh, $fin) or die "$fin $!";}

while(<$fh>){
    chomp;$_=~s/\r//g;
    my @aa = split /\s/,$_;
    if(scalar @aa < 12){ die "this is not a 12 columned bed file $!";}
#585     R0020C  2micron -       1886    3008    1886    3008    1       1886,   3008,   n/a
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

}

if($fin ne "stdin"){ close($fh);}


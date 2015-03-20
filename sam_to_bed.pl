#!/usr/bin/env perl 
## source optained from  : http://rth.dk/resources/dba/bam2bed.php bam_to_bed.pl
use strict;
sub checkFormat{
    my ($entry, $format) = @_;
    if($format eq "SAM"){
        my @l = split(/\t+/, $entry);
        if($l[3] !~ /\d+/){die "file is not in SAM format -> $entry\n";}
        if($l[1] != 0 && $l[1] != 16 && $l[1] != 4){die "It seems your file consists of paired end reads.\nUnfortunately, we do not suppo
rt these experiments.\n";}
    }
}

sub sam{
    my ($line) = @_;
    my @entry = split(/\t/,$line);
    my $id = $entry[0];
    my $chr = $entry[2];
    #my $strand = $entry[1]?"-":"+"; # $strand="-" if $flag & (0x10);
    my $strand = ($entry[1] & (0x10)) ?"-":"+"; # $strand="-" if $flag & (0x10);
    my $seq = $entry[9]; if($strand eq "-"){$seq = reverseComplement($seq);}
    my $start = $entry[3];
    my $cigar = $entry[5];
    my $length = 0; my $tmp = $cigar; $tmp =~ s/(\d+)[MD]/$length+=$1/eg;
    my $end = $entry[3] + $length;
    $start--; $end--;
    return ($id, $chr, $strand, $seq, $start, $end, $cigar);
}

sub getSpliceParts{
    my ($cigar, $start) = @_;
    my @parts = ();
    my $length = 0; my $value = "";
    for(my $i = 0; $i <= length($cigar); $i++){
        my $v = substr($cigar,$i,1);
        if($v=~/\d/){$value.=$v;}
        if($v=~/\D/){
            if($v eq "M" || $v eq "D"){$length+=$value;$value="";}
            if($v eq "N"){
                my $end += $start + $length + 1;
                push(@parts, "$start|$end");
                $start = $start + $length + $value;
                $length = 0;$value="";
                        }
                        else {$value="";}
                }
        }
    my $end += $start + $length + 1;
    push(@parts, "$start|$end");
    return @parts;
}
sub reverseComplement{
    my ($seq) = @_;
    my $revcomp = reverse($seq);
    $revcomp =~ tr/ACGTUacgtu/TGCAAtgcaa/;
    return $revcomp;
}
## main
while(<STDIN>){ chomp; my @a=split /\t/,$_; 
	next if ($_ =~ /^[@]/ || $_ =~ /^\s*$/ || $a[2] eq "*");
	my $flag=$a[1]; my $score=$a[4];
	my ($id, $chr, $strand, $seq, $start, $end, $cigar) = sam($_);
	print join("\t",($chr,$start,$end,$id,$score,$strand,$cigar)),"\n";
}

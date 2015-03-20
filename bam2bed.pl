#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Getopt::Std;
use List::Util;
use Cwd;
use IO::File;
use POSIX qw(tmpnam);

# -----------------------------------------------------------------------------
# GLOBALS

use vars qw ($help $inputFile $outputFile $sam $read $uniqOnly $uniqSeqOnly $verbose $isPE $processor);
$processor=1;

# -----------------------------------------------------------------------------
# OPTIONS

GetOptions (
"i=s"       => \$inputFile,
"o=s"       => \$outputFile,
"s"         => \$sam,
"q"         => \$uniqSeqOnly,
"u"         => \$uniqOnly,
"w"         => \$isPE,
"p=i"       => \$processor,
"r"         => \$read,
"v"         => \$verbose,
"help"      => \$help,
"h"         => \$help);
usage() if ($help || !$inputFile || !$outputFile);

## parse options
sub usage {
    print STDERR "\nusage: bam2bed.pl -i <file> -o <file> [OPTIONS]\n";
    print STDERR "Convert read mapping from bam to bed format. Also include frequency (normalized) with which the reads are mapped\n";
    print STDERR "\n";
    print STDERR "[INPUT]\n";
    print STDERR " -i <file>    [input BAM file]\n";
    print STDERR " -o <file>    [output BED file]\n";
    print STDERR " -h <file>    [help]\n";
    print STDERR "[OPTIONS]\n";
    print STDERR " -s           [input file is in sam format]\n";
    print STDERR " -q           [print only uniquely mapped reads. Identified based on actual nucleotide sequence. Only for single-end reads]\n";
    print STDERR " -u           [print only uniquely mapped reads. Identified based on read identifiers. Only for single-end reads]\n";
    print STDERR " -w           [print only uniquely mapped reads. Identified based on quality score. Useful for paired-end reads]\n";
    #print STDERR " -p <int>     [number of processors (default: 1)]\n";
    print STDERR " -r           [print read sequence also]\n";
    print STDERR " -v           [verbose]\n";
    print STDERR "[VERSION]\n";
    print STDERR " 28-08-2014\n";
    print STDERR "[BUGS]\n";
    print STDERR " Please report bugs to sachin\@rth.dk\n";
    print STDERR "[CREDITS]\n";
    print STDERR " This script is adapted from map2bed.pl provided by david\@bioinf.uni-leipzig.de\n";
    print STDERR "[IMPORTANT NOTE]\n";
    print STDERR " If the tag id is in the form <tag id>|<read count>, then the program will consider the term after the pipe (|) as the read count\n";
    print STDERR "\n";
    exit(-1);
}


# -----------------------------------------------------------------------------
# MAIN

printHeader();

if(!defined($uniqOnly) && !defined($isPE)) {
	sam2bed($inputFile, $outputFile);
}
elsif(defined($isPE)) {
    #grep -P "^\@|NH:i:1{0,1}\s+" Sample_PRI_7XVL_SS_321.sam | samtools view -bS - | bedtools bamtobed | perl -ane '($id, $expr)=split(/\|/,$F[3]); print "$F[0]\t$F[1]\t$F[2]\t$id"."_1\t$expr\t$F[5]\n";' | less
    # -q 1 to extract uniquely mapped reads aligned by BWA. Alternative can be XT:A:U
    if($sam && $inputFile=~/gz$/) {
        system("zless $inputFile | samtools view - -q 1 -bS | bedtools bamtobed -i stdin -split -bed12 | perl -ane 'if(\$F[0]=~/[\_\.]+/) { next; } if(\$F[0]!~/chr/) { \$F[0]=\"chr\".\$F[0]; } \@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' > $outputFile.tmp");
        system("sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 $outputFile.tmp > $outputFile");
    }
    elsif($sam){
        system("samtools view $inputFile -q 1 -bS | bedtools bamtobed -i stdin -split -bed12 | perl -ane 'if(\$F[0]=~/[\_\.]+/) { next; } if(\$F[0]!~/chr/) { \$F[0]=\"chr\".\$F[0]; } \@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' > $outputFile.tmp");
        system("sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 $outputFile.tmp > $outputFile");
    }
    elsif($inputFile=~/gz$/) {
        system("zless $inputFile | samtools view - -q 1 -b | bedtools bamtobed -i stdin -split -bed12 | perl -ane 'if(\$F[0]=~/[\_\.]+/) { next; } if(\$F[0]!~/chr/) { \$F[0]=\"chr\".\$F[0]; } \@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' > $outputFile.tmp");
        system("sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 $outputFile.tmp > $outputFile");
    }
    else {
        system("samtools view $inputFile -q 1 -b | bedtools bamtobed -i stdin -split -bed12 | perl -ane 'if(\$F[0]=~/[\_\.]+/) { next; } if(\$F[0]!~/chr/) { \$F[0]=\"chr\".\$F[0]; } \@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' > $outputFile.tmp");
        system("sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 $outputFile.tmp > $outputFile");
    }
    ## remove temporary file	
    system("rm $outputFile.tmp");
}
else {
    if($sam && $inputFile=~/gz$/) {
        system("zgrep \"^\@\" $inputFile > $outputFile.tmp");
        system("zgrep -v \"^\@\" $inputFile | sort -k 1,1 | perl -ane 'if(!defined(\$last_seen)) { \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]!~/^\\Q\$last_seen\\E\$/) { if(defined(\$line)) { print \$line; } \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]=~/^\\Q\$last_seen\\E\$/) { \$line=(); } END { if(defined(\$line)) { print \$line; } }' >> $outputFile.tmp");
        system("samtools view $outputFile.tmp -bS | bedtools bamtobed -i stdin | perl -ane '\@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' | sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 > $outputFile");
    }
    elsif($sam){
        system("grep \"^\@\" $inputFile > $outputFile.tmp");
        system("grep -v \"^\@\" $inputFile | sort -k 1,1 | perl -ane 'if(!defined(\$last_seen)) { \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]!~/^\\Q\$last_seen\\E\$/) { if(defined(\$line)) { print \$line; } \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]=~/^\\Q\$last_seen\\E\$/) { \$line=(); } END { if(defined(\$line)) { print \$line; } }' >> $outputFile.tmp");
        system("samtools view $outputFile.tmp -bS | bedtools bamtobed -i stdin | perl -ane '\@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' | sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 > $outputFile");
    }
    elsif($inputFile=~/gz$/) {
        system("zless $inputFile | samtools view -H > $outputFile.tmp");
        system("zless $inputFile | samtools view - | sort -k 1,1 | perl -ane 'if(!defined(\$last_seen)) { \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]!~/^\\Q\$last_seen\\E\$/) { if(defined(\$line)) { print \$line; } \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]=~/^\\Q\$last_seen\\E\$/) { \$line=(); } END { if(defined(\$line)) { print \$line; } }' >> $outputFile.tmp");
        system("samtools view $outputFile.tmp -bS | bedtools bamtobed -i stdin | perl -ane '\@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' | sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 > $outputFile");
    }
    else {
        system("samtools view $inputFile -H > $outputFile.tmp");
        system("samtools view $inputFile | sort -k 1,1 | perl -ane 'if(!defined(\$last_seen)) { \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]!~/^\\Q\$last_seen\\E\$/) { if(defined(\$line)) { print \$line; } \$line=\$_; \$last_seen=\$F[0]; } elsif(\$F[0]=~/^\\Q\$last_seen\\E\$/) { \$line=(); } END { if(defined(\$line)) { print \$line; } }' >> $outputFile.tmp");
        system("samtools view $outputFile.tmp -bS | bedtools bamtobed -i stdin | perl -ane '\@t=split(/\\|/,\$F[3]); \$F[3]=~s/[\\#\\|]+.+/_1/g; \$freq=1; if(defined(\$t[1])) { \$freq=\$t[1]; } print \"\$F[0]\\t\$F[1]\\t\$F[2]\\t\$F[3]\\t\$freq\\t\$F[5]\n\";' | sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 > $outputFile");
    }
    ## remove temporary file	
    system("rm $outputFile.tmp");
}

# -----------------------------------------------------------------------------
# FUNCTIONS

sub prettyTime{
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my ($second, $minute, $hour, $dayOfMonth, $month,
    $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
    my $year = 1900 + $yearOffset;
    return "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
}

sub printHeader{
    print "# bam2bed.pl started " . prettyTime() . "\n";
    print "# input file: $inputFile\n";
    print "#\n";
}

sub sam2bed{
    my ($inputFile, $outputFile) = @_;
    my %tags = (); my $c = 0; my %coor = ();
    if($sam && $inputFile=~/gz$/) {
        open(FILE, "zless $inputFile | ") || die "cannot open $inputFile\n";
    }
    elsif($sam){
        open(FILE, "<$inputFile") || die "cannot open $inputFile\n";
    }elsif($inputFile=~/gz$/) {
        open(FILE, "zless $inputFile | samtools view - | ") || die "cannot open $inputFile\n";
    }else{
        open(FILE, "samtools view $inputFile | ") || die "cannot open $inputFile\n";
    }

    while(<FILE>){
        chomp;
        my @entry = split(/\t/,$_);
        if ($_ =~ /^[@]/ || $_ =~ /^\s*$/ || $entry[2] eq "*") {
					print STDERR "Skipping line $_ (".prettyTime().")\n" if(defined($verbose));
					next;
				}
        checkFormat($_, "SAM");
        my ($id, $chr, $strand, $seq, $start, $end, $cigar) = sam($_);
				print STDERR "Processing read $id ...\t" if(defined($verbose));

        # name tag
        if(!exists($tags{$seq}{tag})){
            $c++;
            my $tagId = $inputFile;
            $tagId=~s/^.+\///g;
            $tagId=~s/\.[bs]am*//g;
						$tagId=~s/\.gz//g;
            $tags{$seq}{tag} = $tagId."_".$c;
        }
        # count reads
        # the count of distict ids for a seq in bam file is the expression of a read
        #if(!exists($tags{$seq}{reads}{$id})){
            $tags{$seq}{reads}{$id}++;
        #}
        # count loci
        if($cigar !~ /N/){
            $tags{$seq}{loci}{"$chr|$start|$end|$strand"}++;
            $coor{$seq}{$id}{"$chr|$start|$end|$strand"}++;
        }else{
            my @parts = getSpliceParts($cigar, $start);
            foreach my $part (@parts){
                ($start, $end) = split(/\|/, $part);
                $tags{$seq}{loci}{"$chr|$start|$end|$strand"}++;
                $coor{$seq}{$id}{"$chr|$start|$end|$strand"}++;
            }
        }

        foreach my $col (@entry){
            if($col =~ /XA:Z:/ && $col !~ /XA:Z:Q/){
                $col =~ s/XA:Z://;
                my @multi = split(/\;/,$col);
                foreach my $mm (@multi){
                    ($chr, $start, $cigar) = split(/\,/, $mm);
                    if($start =~ /\+/){$strand = "+";}else{$strand = "-";}
                    $start =~ s/[\+\-]//;
                    my $length = 0; my $tmp = $cigar; $tmp =~ s/(\d+)[MD]/$length+=$1/eg;
                    my $end = $start + $length;
                    $start--; $end--;
                    if($cigar !~ /N/){
                        $tags{$seq}{loci}{"$chr|$start|$end|$strand"}++;
                    }
                    else{
                        my @parts = getSpliceParts($cigar, $start);
                        foreach my $part (@parts){
                            ($start, $end) = split(/\|/, $part);
                            $tags{$seq}{loci}{"$chr|$start|$end|$strand"}++;
                        }
                    }
                }
            }
        }
				print STDERR "done (".prettyTime().")\n" if(defined($verbose));
    }
    close(FILE);
		print STDERR "Starting printing output (".prettyTime().")\n" if(defined($verbose));

    my %chroms = ();
    foreach my $seq (keys %tags){
				print STDERR "Printing $seq\t" if(defined($verbose));
        #print "$seq\t".keys(%{$tags{$seq}{loci}})."\t".keys(%{$tags{$seq}{reads}})."\t";
        #my $sum=0;
        #foreach(keys(%{$tags{$seq}{reads}})) {$sum+=$tags{$seq}{reads}{$_};}
        #print "$sum\n";
        my $file=();
        foreach my $locus (keys %{$tags{$seq}{loci}}){
						print STDERR "$locus\t" if(defined($verbose));
            my ($chr, $start, $end, $strand) = split(/\|/,$locus);
						$file=();
						if($chr!~/\_/) {
	            if(!exists($chroms{$chr})){($chroms{$chr}{fileName},$chroms{$chr}{fileHandle}) = openBin();}
							print STDERR "$chroms{$chr}{fileName}\t$chroms{$chr}{fileHandle}\t" if(defined($verbose));
    	        $file = $chroms{$chr}{fileHandle};
						}
						else {
	            if(!exists($chroms{'chr_anonymous'})){($chroms{'chr_anonymous'}{fileName},$chroms{'chr_anonymous'}{fileHandle}) = openBin();}
							print STDERR "$chroms{'chr_anonymous'}{fileName}\t$chroms{'chr_anonymous'}{fileHandle}\t" if(defined($verbose));
    	        $file = $chroms{'chr_anonymous'}{fileHandle};
						}
            my $uniqTags=0; my $duplTags=0;
            foreach my $id(keys(%{$tags{$seq}{reads}})) {
								print STDERR "$id\t" if(defined($verbose));
                if($tags{$seq}{reads}{$id}==1) {
                    foreach my $coor(keys(%{$coor{$seq}{$id}})) {
                        if($coor=~/^\Q$locus\E$/) {
													my ($name, $expr) = split(/\|/,$id);
													#print "$name\t$expr\n";
													if(defined($expr)) { $uniqTags+=$expr; }
													else { $uniqTags++; }
												}
                    }
                }
                else {
                    foreach my $coor(keys(%{$coor{$seq}{$id}})) {
                        if($coor=~/^\Q$locus\E$/) {
													my ($name, $expr) = split(/\|/,$id);
													#print "$name\t$expr\n";
													if(defined($expr)) { $duplTags+=$expr; }
													else { $duplTags++; }
												}
                    }
                }
            }
            if($uniqTags>0) {
								if($read) {
	                printf $file "%s\t%d\t%d\t%s_1\t%0.3f\t%s\t%s\n", $chr, $start, $end, $tags{$seq}{tag}, $uniqTags, $strand, $seq;
								}
								else {
	                printf $file "%s\t%d\t%d\t%s_1\t%0.3f\t%s\n", $chr, $start, $end, $tags{$seq}{tag}, $uniqTags, $strand;
								}
            }
            if($duplTags>0 && !defined($uniqSeqOnly)) {
								my $count=keys(%{$tags{$seq}{loci}});
								if($read) {
	                printf $file "%s\t%d\t%d\t%s_%d\t%0.3f\t%s\t%s\n", $chr, $start, $end, $tags{$seq}{tag}, $count, $duplTags / $count, $strand, $seq;
								}
								else {
	                printf $file "%s\t%d\t%d\t%s_%d\t%0.3f\t%s\n", $chr, $start, $end, $tags{$seq}{tag}, $count, $duplTags / $count, $strand;
								}
            }
						print STDERR "\tdone (".prettyTime().")\n" if(defined($verbose));
        }
    }
    closeBins(%chroms);
    mergeAndSort(%chroms);
    deleteBins(%chroms);
}

sub checkFormat{
    my ($entry, $format) = @_;
    if($format eq "SAM"){
        my @l = split(/\t+/, $entry);
        if($l[3] !~ /\d+/){die "file is not in SAM format -> $entry\n";}
        if($l[1] != 0 && $l[1] != 16 && $l[1] != 4){die "It seems your file consists of paired end reads.\nUnfortunately, we do not support these experiments.\n$entry\nPlease instead try using the program with -p argument.\n";}
    }
}

sub sam{
    my ($line) = @_;
    my @entry = split(/\t/,$line);
    my $id = $entry[0];
    my $chr = $entry[2];
    my $strand = $entry[1]?"-":"+";
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

sub openBin{
    my ($fileName, $file) = ();
    do {$fileName = tmpnam()} until $file = IO::File->new($fileName, O_RDWR|O_CREAT|O_EXCL);
    return ($fileName, $file);
}

sub deleteBins{
    my (%bins) = @_;
    foreach my $id (keys %bins){
        unlink($bins{$id}{fileName});
    }
}

sub closeBins{
    my (%bins) = @_;
    foreach my $id (keys %bins){
        close($bins{$id}{fileHandle});
    }
}

sub mergeAndSort{
    my (%chroms) = @_;
    my %ids = ();
    foreach my $c (keys %chroms){
        my ($fileName,$fileHandle) = openBin();
        #system("nohup sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 -o $fileName $chroms{$c}{fileName}  2>&1 1>/dev/null &");
        system("nohup sort -k 1,1 -k 6,6 -k 2n,2 -k 3n,3 -o $fileName $chroms{$c}{fileName}  2> /dev/null &");
        $ids{$fileName}{fileName} = $fileName;
        $ids{$fileName}{fileHandle} = $fileHandle;
    }
    while(checkFiles(%ids) != 1){
        #print "sleep(10)\t".prettyTime()."\n\n";
        sleep(10);
    }
    closeBins(%ids);

    if(-e $outputFile){system("rm $outputFile");}
    foreach my $id (keys %ids){
        system("cat $ids{$id}{fileName} >> $outputFile");
    }
    deleteBins(%ids);
}

sub checkFiles{
    my (%ids) = @_;
    my $ps = `ps -f`;
    #print "$ps\n";
    foreach my $id (keys %ids){
        if(defined($ps) && $ps =~ /$id/){return 0;};
    }

    return 1;
}


#!/usr/bin/perl -w
use strict;
my $usage = "
	Author: Hyunmin Kim (hyun.kim\@ucdenver.edu)
	Version: v0.1
	Output: UCSC URL
	Warning: the URLs not existing on TWiki track will be deleted in a month!

	usage: $0 [options] <file>
		<file>: .bw or .bb

";
my $user = 'BentleyLab'; 
my $password = 'qpsxmfflfoq';
my $host = 'bentleylab';

my @INP = ();
while(@ARGV){
	my $e = shift @ARGV;
	if($e eq '-host'){
		$host = shift @ARGV;
	}else{
		push @INP, $e;
	}
}

if(scalar @INP < 1){ print $usage,"\n";exit(-1);}


my $cmd_template = q{
track type=@TYPE name="@NAME" description="@DESC" bigDataUrl=http://bentleylab.ucdenver.edu/LabUrl/@FILE
};


for my $f (@INP){
	my @tmp = split /\//,$f;
	my $file = $tmp[$#tmp];
	if($file =~ /(\S+)\.(\S+)$/){
		my ($head,$ext) = ($1,$2);
		my $type = "";

		if( $ext eq "bw"){ $type = "bigWig";
		}elsif( $ext eq "bb"){ $type = "bigBed"; }

		my $cmd = $cmd_template;
		$cmd =~ s/\@NAME/$head/g;
		$cmd =~ s/\@DESC/$head/g;
		$cmd =~ s/\@FILE/$file/g;
		$cmd =~ s/\@TYPE/$type/g;
		print $cmd;
	}
}

print "passwd: $password\n";
my $files = join " ",@INP;
my 	$cmd = q{ scp @FILES @USER@bentleylab.ucdenver.edu:~/Site };
$cmd =~ s/\@USER/$user/g;
$cmd =~ s/\@FILES/$files/g;
print '##',$cmd,"\n";
system($cmd);

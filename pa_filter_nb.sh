#!/bin/bash
usage="
 $BASH_SOURCE <cmd> ...
	<cmd>: 
	 train <input> : class_id 5'sequence 3'sequence
	 predict <input> [<model>]
"
MODEL=${BASH_SOURCE%/*}/nb.model

program='
	use strict;
	my $PI = 3.141593;
	my $SQRT2PI= sqrt(2*$PI);
	sub mean_sd{
		my ($x, $n) = @_; ## $n: total to handle entiries with non-existing features
		my $esp = 0.001;
		my $sum = 0; my $sumsq = 0; 
		foreach my $v (@$x){
			$sum += $v; $sumsq += $v*$v;
		}
		my $mean = $sum/$n;
		my $std = ($n > 1)? sqrt(($sumsq - $sum * $sum/$n)/($n-1)): $esp;
		return ($mean,$std);
	}
	sub dnorm{
		my ($x,$mean,$sd) = @_;
		return (1/($SQRT2PI*$sd)*exp(-($x-$mean)**2/(2*$sd**2)));
	}
	#	print "1.6549~",dnorm(2.02,2,0.24),"\n";return;
	#my ($m,$std) = mean_sd([1,2,3,4,5]); print $m," ",$std,"\n";

	sub makeMotifFeature{
		my ($seq, $motif_len, $tag, $F) = @_;
		for(my $i=0;$i<length($seq) - $motif_len + 1;$i++){
			my $motif = substr($seq,$i,$motif_len);
			$F->{$tag.":".$motif} ++;
		}
	}
	sub makeMotifDistalFeature{
		my ($seq, $motif, $tag, $F) = @_;
		my $s = 0; my $n = 0;
		for(my $i=0;$i<length($seq) - length($motif) + 1;$i++){
			if(substr($seq,$i,length($motif)) eq $motif){
				$s += $i+1; # 1-base
				$n ++;
			}
		}
		$F->{$tag.":".$motif} = ($n >0)? $s/$n: length($seq);
	}
	sub makeFeature{
		my ($upseq,$dnseq) = @_;
		my %F = ();
		makeMotifFeature($upseq,6,"B",\%F);
		makeMotifFeature($dnseq,2,"N",\%F);
		makeMotifFeature($dnseq,1,"N",\%F);
		makeMotifDistalFeature($dnseq,"A","D",\%F);
		return \%F;
	}
	sub updateFeature{
		my ($F,$f,$op) = @_;
		print $f," ",$F->{$f}," ",$op,"\n";	
		my $type = [split /:/,$f]->[0];
		
		if($type eq "D" || $type eq "C"){ 
			if($op eq "inc"){ $F->{$f} ++;
			}elsif(defined $F->{$f}){
				$F->{$f} --;
				if ($F->{$f} == 0){ delete $F->{$f}; }
			}
		}elsif($type eq "B"){
			my ($ave,$n) = (split /:/,$F->{$f});
			if($op eq "inc"){
				$ave = $n/($n+1)*$ave + (30)/($n+1);
				$n++;
			}else{
				$ave =($n+1)/$n*$ave - (1)/$n;	 #  ave1 = n / n+1 ave0  + v/n+1 => ave0=  n+1/n (ave1 - v/n+1 )
				$n--;
			}
		}
	}
		
	sub printFeature{
		my ($f) = @_;
		foreach my $k (keys %$f){ 
			print $k,"\t",$f->{$k},"\n";
		}
	}
	sub collectFeatures{
		my ($y, $f, $F) = @_;
		foreach my $k (keys %$f){	
			if(!defined $F->{$y}->{$k}){
				$F->{$y}->{$k} =  [];
			}
			push @{$F->{$y}->{$k}}, $f->{$k};
		}
	}
	sub genMotifs{
		my ($motif,$m_len) = @_;
		return $motif if $m_len == 0;
		my @res= ();
		for my $nu ("A","C","G","T"){
			push @res,genMotifs($motif.$nu,$m_len-1);
		}
		return @res;
	} #print join("\n", genMotifs("",4)); exit(1);
	sub buildModel{
		my ($F, $NN) = @_;
		my %M = ();
		my $laplace = 1; ## e1071
		my $ny = scalar keys %$F;

		my $TOT=0;
		foreach my $y (keys %$F){
			my $N = $NN->{$y}; $TOT += $N;
			foreach my $k (genMotifs("",6)){
				$k = "B:".$k;
				my $v = $F->{$y}->{$k};
				my $n = (defined $v)? scalar @{$v}: 0;
				my $p=($n+$laplace)/($N + $laplace * $ny);	
				$M{$y}{$k} = $p;
				$M{$y}{"b:"} += log(1-$p);
			}
			
			foreach my $k (keys %{$F->{$y}}){
				my $type = [split /:/,$k]->[0];
				my $v = $F->{$y}->{$k};
				if($type eq "N" || $type eq "D"){ ## numeric or distal
					my ($mean,$sd) = mean_sd($v, $N); 
					$M{$y}{$k}= "$mean,$sd";
				}
			}
		}	
		foreach my $y (keys %$NN){ ## apriori
			$M{$y}{"T:"} = $NN->{$y}/$TOT;
		}
		return \%M;
	}
	sub writeModel{
	## class\ttype\tfea\tvalues
	## type::B : p(Y|X) = # entries containing X / total
	## type::N|D : p(Y|X) = dnorm(mu, sd)
		my ($fh,$M) = @_;
		foreach my $y (keys %{$M}){
		foreach my $k (keys %{$M->{$y}}){
			print {$fh} $y,"\t",$k,"\t",$M->{$y}->{$k},"\n";
		}}
	}
	sub readModel{
		my ($fh) = @_;
		my %M = ();
		while(<$fh>){ chomp;
			my ($y,$fea,$v) = split /\t/,$_;
			$M{$y}{$fea}=$v;
		}
		return \%M;
	}
	sub s2h{
		my ($s,$h) = @_;
		my %h = ();
		foreach my $kv (@{[split /,/,$s]}){
			my ($k,$v) = split /:/,$kv;
			$h->{$k}=$v;
		}
	}
	sub predict{
		my ($M,$F) = @_;
		my $L=0;
		my $eps = 0.001;
		$L += log( $M->{"T:"}); ## apriori
		$L += $M->{"b:"}; ## sum of non-existence prob.
		foreach my $k (keys %$F){
			my $type = [split /:/,$k]->[0];
			my $v = $F->{$k};
			my $m = $M->{$k};
			next unless defined $m;
			if($type eq "B"){
				$L += log($m);
				$L -= log(1-$m); ## remove non-existance probs
			}elsif($type eq "N" || $type eq "D"){
				my ($mean,$sd) = split /,/,$m;
				my $p = dnorm($v,$mean,$sd);
				$L += log($p);
			}
		}
		return($L);
	}

	if("CMD" eq "predict"){
		open(my $fh, "<","MODELL");
		my $M = readModel($fh);
		close($fh);
		my $up_len = 40;
		my $dn_len = 30;

		my @classes = sort {$a<=>$b} keys %$M;
		while(<>){ chomp;
			my ($id,$seq) = split /\t/,$_;
			my @res_x=();
			my @res_y=();

			for(my $i=0; $i < length($seq) - $up_len - $dn_len + 1; $i++){
				my $up=substr($seq,$i,$up_len);
				my $dn=substr($seq,$i+$up_len,$dn_len);
				my $F = makeFeature($up,$dn);
				my %llh = ();
				my $denom = 0;
				foreach my $y (@classes){
					$llh{$y}=predict($M->{$y},$F);
					$denom += exp($llh{$y});
				}
				foreach my $y (@classes){
					#push @res, ($i+$up_len).":".$y.":".exp($llh{$y})/$denom;
					if($y == 1){
						push @res_x,($i+$up_len);
						push @res_y, exp($llh{$y})/$denom;
					}
				}
			}
			#print $id,"\t",$seq,"\t",join( ",",@res),"\n";
			print $id,"\t",$seq,"\t",join( ",",@res_x),"\t",join(",",@res_y),"\n";
		}
	}elsif("CMD" eq "train"){
		my %F = ();
		my %N = ();
		while(<>){ chomp;
			my ($y, $ups,$dns) = split /\t/,$_;
			my $f = makeFeature($ups,$dns);
			#print $_,"\n"; printFeature($f);
			collectFeatures($y,$f,\%F);
			$N{$y}++;
		}	
		my $M = buildModel(\%F,\%N);
		writeModel(*STDOUT,$M);
	}
'

data="1	CTGTGTAGTGGGATTTTAAAAATTAATTAATTTATTTACTTATTTATTCTGAGATGGAGTCTCACTCTGTCACCCAGGCTGGAGTGCAGTGGCACAATCTCAGCTCACTGCAAGCTCTGCCTCCCAGGTTCATGCCATTCTCCTGCCTCAGCCCCCC
chr22|19178110|19178111|.|0.921|+	CTGCACTCCCACCTGGGCAACAGAGCAAGACTGTCTCAAAAAAAAAAAAAAAAAAAAAAAGATCACTGNT"


if [ $# -lt 2 ]; then echo "$usage"; exit 1; fi
if [ $1 = "train" ];then
	cmd=$program;
	cmd=${cmd//CMD/train};
	cat $2 | perl -e "$cmd"
elif [ $1 = "predict" ];then
	if [ $# -eq 3 ]; then
		MODEL=$3;
	fi
	cmd=$program;
	cmd=${cmd//CMD/predict};
	cmd=${cmd/MODELL/$MODEL};
	if [ $2 == "test" ]; then 
		echo -e "$data" | perl -e "$cmd";
	else
		cat $2 | perl -e "$cmd"
	fi
else
	echo "$usage"; exit 1;
fi


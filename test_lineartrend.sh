#!/bin/bash
THIS=${BASH_SOURCE##*/}
usage="
OUT: p-value, Pearson Correlation ...
USAGE: $THIS <file>
	<file> : tab delimited file with x1 y1 x2 y2 ...
"
while getopts "h" arg; do
	case $arg in
		?) echo "$usage"; exit 1;;
	esac
done
shift $(( OPTIND - 1 ));
if [ $# -ne 1 ]; then
	echo "$usage"; exit 1;
fi
echo "#$THIS $@">&2

makeTemp(){
    mktemp 2>/dev/null || mktemp -t $0;
}
runPyStdio(){
	cmd=$1; tmpcmd=`makeTemp`;	
	echo "$cmd" > $tmpcmd
	python $tmpcmd
}

cmd='
from scipy.stats.stats import pearsonr
from scipy.stats import chi2
import sys

def test_lineartrend(x1,y1,x2,y2):
	if len(x1) < 2 or len(x2) < 2 or sum(y1) == 0 or sum(y2) == 0:
		raise ValueError
	sx = [];
	sy = [];
	for i in range(len(x1)):
			for j in range(y1[i]):
				sx.append(x1[i]);
				sy.append(1);
	for i in range(len(x2)):
			for j in range(y2[i]):
				sx.append(x2[i]);
				sy.append(2);
	if len(set(sx)) == 1 :
		return 0,1;
	r,pval = pearsonr(sx,sy);
	s = r*r*(len(sx)-1);
	pval = 1-chi2.cdf(s,1)
	return r,pval

def s2a(x):
	return [ int(float(x)) for x in x.split(",")];

for line in sys.stdin:
	if line[0] == "#":
		print line.rstrip();
		continue;
	a = line.rstrip().split("\t");
	x1,y1,x2,y2 = map(s2a, a[:4]);
	try:
		r,p = test_lineartrend(x1,y1,x2,y2)
		print "\t".join(map(str, a + [r,p]))
	except ValueError:
		1
'
cat $1 | runPyStdio "$cmd" #\
# | $HM_HOME/hm/stats/padjust.sh - -1

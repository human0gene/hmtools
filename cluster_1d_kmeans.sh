#!/bin/bash
. util.sh
MIND=20;
COL="1,2";
usage="
	$BASH_SOURCE [options] <input> 
	 [options]:
	  -d <int> : minimum distance between peak centers (default $MIND)
	  -c <int>,<int> : columns for positions and heights of peaks (default 1,2)
"
CMD="$BASH_SOURCE $*";
while getopts "hd:c:" arg; do
	case $arg in
	 d) MIND=${OPTARG};;
	 c) COL=${OPTARG};;
	 ?) echo "$usage"; exit 1;;
	esac
done
shift $(( OPTIND -1 ));
if [ $# -ne 1 ]; then
	echo "$usage"; exit 1;
fi

cmd='
import numpy,sys,warnings,getopt
def calcDist(xy):
	if len(xy[0]) == 1:	
		ave=numpy.mean([ x for x in xy])
		d = sum( [ (xi - ave ) * (xi - ave) for xi in xy] );
	elif len(xy[0]) == 2:
		n=sum([ y for x,y in xy]);
		ave=sum([ x*y for x,y in xy])/n;
		d = sum( [ (x - ave ) * (x - ave) * y for x,y in xy] );
	else:	
		raise ValueError( "not implemented input dim > 2");
	return d
	
def calcBD(x, K):
	N=len(x)
	D = numpy.array([ -0.1 for i in range(0,N*K)]).reshape(K,N)
	B = numpy.array([ 0 for i in range(0,N*K)]).reshape(K,N)
	for k in range(0,K):
		D[k][0] = 0;
		B[k][0] = 0;
	for k in range(0,K):
		for i in range(1,N):
			if k== 0:
				D[k][i] = calcDist(x[0:(i+1)]);
				B[k][i] = 0;
			else:
				D[k][i] = -1;
				for j in range(i,-1,-1):
					d = calcDist(x[j:(i+1)]);
					if D[k][i] == -1:
						if j == 0:
							D[k][i]=d;
							B[k][i]=j;
						else:
							D[k][i]=d + D[k-1][j-1];
							B[k][i]=j;
					else:
						if j == 0 and d <= D[k][i]:
							D[k][i]=d;
							B[k][i]=j;
						elif d + D[k-1][j-1] < D[k][i]:
							D[k][i] = d + D[k-1][j-1];
							B[k][i]=j;
	return B,D
				
def report(xy,B,K):
	N = len(xy);
	#K = B.shape[0]; 
	cluster_right=N-1;
	cluster_left=0;
	nClusters = K;
	cluster = [ 0 for i in range(N)]
	centers = [ 0.0 for i in range(K)] 
	starts = [ 0 for i in range(K)] 
	ends= [ 0 for i in range(K)] 
	values= [ 0.0 for i in range(K)] 
	size =[ 0.0 for i in range(K)]  
	for k in range(K-1,-1,-1):
		cluster_left = B[k][cluster_right];
		starts[k] = xy[cluster_left][0];
		ends[k] = xy[cluster_right][0]+1;
		for i in range(cluster_left,cluster_right+1):
			cluster[i] = k;
			xyloc=xy[cluster_left:(cluster_right+1)];	
			size[k] = cluster_right - cluster_left + 1;
			if len(xy[0]) == 1:
				centers[k] = sum( [ xi for xi in xyloc])/float(size[k]);
				values[k] = float(len(xy));
			elif len(xy[0]) == 2:
				centers[k] = int(sum( [ xi*yi for xi,yi in xyloc])/float(sum([ yi for xi,yi in xyloc])) + 0.5);
				values[k] = sum( [ yi for xi,yi in xyloc] );
		if k > 0: cluster_right = cluster_left - 1
	return cluster,centers,size,values,starts,ends
def jo(x):
	return ",".join(map(str,x));
def min_d(x):
	# x needs to be sorted
	if len(x) == 1: 
		return 0;
	mx = x[1]-x[0];	
	for i in range(2,len(x)):
		d= x[i]-x[i-1];
		if d < mx: mx=d;
	return mx
mind=MIND;
	
cols=[COL];
for line in sys.stdin:
	tmp = line.rstrip().split("\t")
	a=tmp[cols[0] -1];	b=tmp[cols[1] -1];	
	x=map(int,a.split(","));
	y=map(float,b.split(","));
	d={};
	for i in range(len(x)):
		d[x[i]] = d.get(x[i],0) + y[i];
	xy = sorted(d.items())

	maxK=int(len(xy)/mind)+1;
	B,D = calcBD(xy,maxK);
	proper_k=1;
	for k in range(maxK, 0 , -1):
		cl,ce,si,va,ss,es = report(xy,B,k);
		if min_d(ce) >= mind: 
			proper_k=k;
			break;
	#print maxK, proper_k, xy;
	cl,ce,si,va,ss,es = report(xy,B,proper_k);
	id = line.rstrip();
	#for i in range(0,len(ss)):
	#	print "%s\t%s\t%s" % (id,ss[i],es[i]);
	print line.rstrip()+"\t"+"\t".join( (jo(ss),jo(es),jo(ce),jo(va)) )
'
cmd=${cmd/MIND/$MIND};
cmd=${cmd/COL/$COL};


tmp=`makeTemp`;
echo "$cmd" > $tmp;
python $tmp

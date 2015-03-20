usage="
	$BASH_SOURCE <file> <column>
	 <column>: 1-base column index (-1 last column)
"
if [ $# -ne 2 ];then
	echo "$usage"; exit 1;
fi
makeTemp(){
    mktemp 2>/dev/null || mktemp -t $0;
}
cmd='
## obtained from http://stackoverflow.com/questions/7450957/how-to-implement-rs-p-adjust-in-python
def padjust(pvalues, correction_type = "Benjamini-Hochberg"):                
    """                                                                                                   
    consistent with R - print correct_pvalues_for_multiple_testing([0.0, 0.01, 0.029, 0.03, 0.031, 0.05, 0.069, 0.07, 0.071, 0.09, 0.1]) 
    """
    from numpy import array, empty                                                                        
    pvalues = array(pvalues) 
    n = float(pvalues.shape[0])                                                                           
    new_pvalues = empty(n)
    if correction_type == "Bonferroni":                                                                   
        new_pvalues = n * pvalues
    elif correction_type == "Bonferroni-Holm":                                                            
        values = [ (pvalue, i) for i, pvalue in enumerate(pvalues) ]                                      
        values.sort()
        for rank, vals in enumerate(values):                                                              
            pvalue, i = vals
            new_pvalues[i] = (n-rank) * pvalue                                                            
    elif correction_type == "Benjamini-Hochberg":                                                         
        values = [ (pvalue, i) for i, pvalue in enumerate(pvalues) ]                                      
        values.sort()
        values.reverse()                                                                                  
        new_values = []
        for i, vals in enumerate(values):                                                                 
            rank = n - i
            pvalue, index = vals                                                                          
            new_values.append((n/rank) * pvalue)                                                          
        for i in xrange(0, int(n)-1):  
            if new_values[i] < new_values[i+1]:                                                           
                new_values[i+1] = new_values[i]                                                           
        for i, vals in enumerate(values):
            pvalue, index = vals
            new_pvalues[index] = new_values[i]                                                                                                                  
    return new_pvalues


#p=[0.0, 0.01, 0.029, 0.0,0.03, 0.031, 0.05,0.1, 0.069, 0.07, 0.071, 0.09, 0.1];
#print p
#print padjust(p);
import sys
pv=[];
col=COL;
f=open("FIN","r");
for line in f:
	if line[0] == "#": continue;
	a = line.rstrip().split("\t");
	if col < 0: j=len(a)+col;
	else: j=col-1;
	if a[j] == "nan": a[j]=1;
	pv.append( float(a[ j ]));
f.close();
fdr=padjust(pv);
f=open("FIN","r");
i=0;
for line in f:
	if line[0] == "#": 
		print line.rstrip();
		continue;
	print line.rstrip()+"\t"+str(fdr[i]);
	i += 1;
f.close();
'
FIN=`makeTemp`; cat $1 > $FIN
COL=$2;
cmd=${cmd//COL/$COL}
cmd=${cmd//FIN/$FIN}
echo "$cmd" | python 



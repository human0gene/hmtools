#!/bin/bash 

awk -v OFS="\t" '{ split($11,sizes,",");split($12,starts,",");
    if($6=="+"){ i=$10;}else{ i=1;}
    s=$2+starts[i]; e=s+sizes[i];
    print $1,s,e,$4,i,$6;
}'


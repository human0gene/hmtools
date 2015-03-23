gunzip -dc Homo_sapiens.Ensembl.GRCh37.65.gtf.gz | perl -ne 'chomp; if($_=~/(ENSG\d+)\"; transcript_id \"(ENST\d+)/){ print $2,"\t",$1,"\n";}' | sort -k1 > enstToensg.txt
sort -k1 ensemblToGeneName.txt | join - enstToensg.txt 
sort -k1 ensemblToGeneName.txt | join - enstToensg.txt | awk -v OFS="\t" '{ print $3,$2;}' | sort -uk1 > ensgToGenename.txt 



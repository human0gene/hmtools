#1/bin/bash

tmp=`cat << EOF
#!/usr/bin/env python
"""
This source code was obtained from MATs program
(http://intron.healthcare.uiowa.edu/MATS/): 
processGTF.SAMs.py  file
"""
import sys
chunk = 1000
geneGroup = {}
genes = {}
supple = {}
cds={}
for line in sys.stdin: ## for each line
  ele = line.strip().split('\t');
  chr = ele[0];
  type = ele[2]; ## exon, intron, CDS, start_codon, stop_codon..
  sC = ele[3]; ## start coord, 1-base
  eC = ele[4]; ## end coord, 1-base
  group = range(int(sC)/chunk, int(eC)/chunk + 1); ## groups this line could belong to
  group = list(set(group));  ## remove duplicate groups
  strand = ele[6];
  desc = ele[8].split(';');
  gID=['','']; txID=['','']; ## init..
  for dEle in desc: ## for each element of description
	if len(dEle.strip())==0:
	  continue; ## probably the last description
	dName = dEle.strip().split(' ')[0];
	dVal = dEle.strip().split(' ')[1];
	if dName.upper() == 'GENE_ID': ## it is a description for gene_id
	  gID = [dName,dVal];
	elif dName.upper() == 'TRANSCRIPT_ID': ## it is a description for transcript_id
	  txID = [dName, dVal];

  if gID[0].upper()!='GENE_ID' or txID[0].upper() != 'TRANSCRIPT_ID': ## wrong one..
	print("This line does not have correct description for gID or txID: %s, %s" % (gID, txID));
	print("Incorrect description: %s" % ele);
	continue; ## process next line

  for i in group: ## for each possible group
	if i in geneGroup: ## this group already exist
	  geneGroup[i].append(gID[1]); ## duplicate geneIDs will get removed after the outer for loop
	else: ## first time accesing this group
	  geneGroup[i] = [gID[1]];

  if type=='exon':  ## process exon
	if gID[1] in genes: # already processed this gID
	  if txID[1] in genes[gID[1]]: ## this transcript is added already
		genes[gID[1]][txID[1]].append([int(sC), int(eC)]); ## add exon to the existing Tx
	  else: ## first time processing this Tx
		genes[gID[1]][txID[1]] = [[int(sC), int(eC)]]; ## add first exon
	else:  ## new gene ID
	  genes[gID[1]] = {};
	  genes[gID[1]][txID[1]] = [[int(sC), int(eC)]]; ## add first exon
	  supple[gID[1]] = [gID[1], chr, strand]; ## geneID, chromosom and strand
  if type=='CDS': ## coding region
	if gID[1] in cds: # already processed this gID
	  if txID[1] in cds[gID[1]]: ## this transcript is added already
		cds[gID[1]][txID[1]].append([int(sC), int(eC)]); ## add CDS to the existing Tx
	  else: ## first time processing this Tx
		cds[gID[1]][txID[1]] = [[int(sC), int(eC)]]; ## add first CDS
	else:  ## new gene ID
	  cds[gID[1]] = {};
	  cds[gID[1]][txID[1]] = [[int(sC), int(eC)]]; ## add first exon

## get unique gene lists per group 
for gg in geneGroup: ## for all groups in geneGroup
  geneGroup[gg] = list(set(geneGroup[gg]));

nGene=len(genes); ## number of genes in genes dict
nTx=0; ## number of transcripts
oneTx=0; ## number of one-tx genes
nExon = 0; ## number of exons
oneExon=0; ## number of one-exon transcripts
oneTxOneExon=0;

for id in genes: ## for each gene
  nTx += len(genes[id]); 
  if len(genes[id])==1:
	oneTx += 1; ## one-transcript gene
  for tx in genes[id]: ## for each tx
	nExon += len(genes[id][tx]);
	#print id, tx, genes[id][tx]
	chrom = supple[id][1]
	strand = supple[id][2]

	## 1base to 0base
	ends = map(lambda x: x[1], genes[id][tx])
	starts = map(lambda x: x[0]-1, genes[id][tx]) # 0base
	start = min(starts)
	end = max(ends)
	rstarts0 = map(lambda x: x - start,starts)
	sizes0 = map(lambda x: x[1]-x[0]+1, genes[id][tx]) # 0base 

	## sort by rstarts oannes
	order = zip(*sorted((e,i) for i,e in enumerate(rstarts0)))[1]
	sizes = map(lambda x: sizes0[x], order);
	rstarts = map(lambda x: rstarts0[x], order);

#chr1	12140	12177	HISEQ:69:C2675ACXX:5:1103:8808:4762/1	0	+	12140	12177	255,0,0	1	37	0
	print '\t'.join(map(str, (chrom,start,end,id.replace('"',"")+'::'+tx.replace('"',""),\
		0,strand, start,end,"0,0,0", len(sizes),','.join(map(str,sizes)),','.join(map(str,rstarts)))))
	if len(genes[id][tx])==1: ## one exon tx
	  oneExon += 1;
	  if len(genes[id])==1: ## one tx gene
		oneTxOneExon+=1;
sys.stderr.write("There are %d distinct gene ID in the gtf file\n" % nGene);
sys.stderr.write("There are %d distinct transcript ID in the gtf file\n" % nTx);
sys.stderr.write("There are %d one-transcript genes in the gtf file\n" % oneTx);
sys.stderr.write("There are %d exons in the gtf file\n" % nExon);
sys.stderr.write("There are %d one-exon transcripts in the gtf file\n" % oneExon);
sys.stderr.write("There are %d one-transcript genes with only one exon in the transcript\n" % oneTxOneExon);
EOF
	`
	python -c "$tmp"


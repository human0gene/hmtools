# hmtools
Hyunmin's Tools for Studying Bioinformatics 

INSTALL
--------

0. clone hmtools to a directory, e.g., /my/hmtools

  ```
  git clone https://github.com/human0gene/hmtools.git
  ```
0. include /my/hmtools to $PATH
  
  ```
  echo 'PATH='`pwd`/hmtools':$PATH''; export PATH' >> ~/.bash_profile 
  source ~/.bash_profile 
  ```
0. type pa
  
  ```
  pa
  # this will show the below  
TOOL  : PolyA Analysis Tools @ BED BASH & BEYOND (v0.1)
AUTHOR: Hyunmin Kim (Hyeonmin.gim@gmail.com)
USAGE : 
	pa data     : list available datasets
	pa point	: find clevage sites
	pa filter	: filter out inter-primed artifacts 
	pa cluster	: cluster proximate points 
	pa comp     : compare clusters
	pa report	: report statistics
	pa anno     : gene annotation tools 
	pa sum		: merge read counts

	Checking existing tools:
	samtools 1.1 detected  ## or, not existing 
	bedtools 2.22.0 detected ## or, not existing

  ```
0. install bedtools and samtools if not installed
  * samtools: http://www.htslib.org/
  * bedtools: http://bedtools.readthedocs.org/en/latest/

0. download fasta file(s) and unzip it
  * hg19 : http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/chromFa.tar.gz
  * bowtie2 hg19 indice : ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/hg19.zip

EXAMPLE
--------

* list data

  ```
  pa data
  ```

* make a polyA point file out of a bam file

  ```
  pa point -q 10 http://bentleylab.ucdenver.edu:/LabUrl/fu_mcf-10a.bam chr22 > fu_mcf-10a.chr22.point
  pa point -q 10 http://bentleylab.ucdenver.edu:/LabUrl/fu_mcf-7.bam chr22 > fu_mcf-7.chr22.point
  ```
* mapping and triming
  ```
  ## one way of making a bam file out of a fastQ file using bowtie2 with a default option
  ## fill in <bowtie_index> with a proper bowtie2 index file
  gunzip -dc fastq.gz | fastq_trim.sh -5 12 -t - \
    	| bowtie2 -x <bowtie_index> -U - \
        | samtools view -bS - | samtools sort - output;
  ```

* filter out internal-priming artifacts 

  ```
  ## imagine your human genome sequence is in hg19.fa
  pa filter fu_mcf-10a.chr22.point hg19.fa > fu_mcf-10a.chr22.true
  pa filter fu_mcf-7.chr22.point hg19.fa > fu_mcf-7.chr22.true
  ```
* cluster peaks
  
  ```
  # make peak clusters with pooled data
  pa cluster -d20 *.true > trues.cluster
  # for each cluster count reads of individual samples 
  bed_count.sh -s trues.cluster fu_mcf-10a.chr22.true | awk -v OFS="\t" '{print $1,$2,$3,$4,$7,$6;}' > fu_mcf-10a.chr22.cluster
  bed_count.sh -s trues.cluster fu_mcf-7.chr22.true | awk -v OFS="\t" '{print $1,$2,$3,$4,$7,$6;}' > fu_mcf-7.chr22.cluster
  ```
  
* make 3'utr file
  
  ```
  gunzip -dc Homo_sapiens.Ensembl.GRCh37.65.gtf.gz | pa anno get3utr - > 3utr.bed
  ```
* test linear trend
  
  ```
  pa comp linearTrend 3utr.bed fu_mcf-10a.chr22.cluster fu_mcf-7.chr22.cluster > fu_mcf-10a_vs_fu_mcf-7.lt
  
  ```
 

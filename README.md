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


EXAMPLE
--------

* list data

  ```
  pa data
  ```

* make a polyA point file out of a bam file

  ```
  pa point -q 10 http://bentleylab.ucdenver.edu:/LabUrl/fu_mcf-10a.bam chr22 > fu_mcf-10a.chr22.point
  ```

* filter out internal-priming artifacts 

  ```
  pa filter fu_mcf-10a.chr22.point hg19.fa > fu_mcf-10a.chr22.true
  ```
 

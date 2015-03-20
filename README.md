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
  echo 'PATH='`pwd`/hmtools':$PATH''; export $PATH' >> ~/.bash_profile 
  source ~/.bash_profile 
  ```
0. type pa
  
  ```
  pa
  ```

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
 

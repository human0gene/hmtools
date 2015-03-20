#!/bin/bash
THIS=${BASH_SOURCE##*/};
THISD=${BASH_SOURCE%/*};
data=`ls ${THISD}/data/*`;
urls=`cat ${THISD}/data/urls.txt`
echo "
#DATA:
$data
#URLS:
$urls
"


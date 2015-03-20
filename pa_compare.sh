#!/bin/bash
. util.sh
D=${BASH_SOURCE/%*}
THIS=${BASH_SOURCE##*/}

usage="
$THIS <command>
	<command> :
		linearTrend
		fisherExact	
"
if [ $# -lt 1 ]; then
	echo "$usage"; exit 1;
fi

if [ $1 == "linearTrend" ];then
	pa_compare_lineartrend.sh ${@:2}
elif [ $1 == "fisherExact" ]; then
	pa_compare_fisherexact.sh ${@:2}
fi

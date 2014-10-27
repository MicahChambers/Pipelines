#!/bin/bash

export HCPPIPEDIR=/ifs/students/mchambers/hcp_pipeline
source $HCPPIPEDIR/SetUpHCPPipeline.sh

#queuing_command="qsub -b "
queuing_command="qsub"
qsub_opts="-l h_vmem=16G -b yes -v HCPPIPEDIR=$HCPPIPEDIR"

if [[ "$#" != 2 ]] && [[ "$#" != 3 ]] ; then
	echo "Usage:"
	echo $0 inputlistfile studyfolder pipeline
	echo "inputlist: file should just be a list of paths to subject input directories"
	echo "studyfolder: output path (should already exist"
	echo "pipeline: named pipeline (default is HCP, others include UCLA)"
	exit -1
fi

infile=`readlink -f $1`
StudyFolder=`readlink -f $2`
PIPE="$3"

echo $PIPE
if [[ "$PIPE" == "" ]]; then
	PIPE=HCP
fi

if [ ! -f "$infile" ]; then
	echo 'Error input file doesnt exist: ' $infile
	exit -1
fi

if [ ! -d "$StudyFolder" ]; then
	echo 'Error study folder doesnt exist: ' $StudyFolder
	exit -1
fi

cat $infile | while read line; do 
	sub=""
	opath="$StudyFolder"/`basename $line`
	mkdir -p $opath
	if [[ "$queuing_command" == "qsub" ]]; then
		subcmd="$queuing_command $qsub_opts -wd $opath -o $opath -e $opath"
	fi
	echo $subcmd $HCPPIPEDIR/runners/$PIPE.sh `basename $line` `dirname $line` $StudyFolder
	$subcmd $HCPPIPEDIR/runners/$PIPE.sh `basename $line` `dirname $line` $StudyFolder
done

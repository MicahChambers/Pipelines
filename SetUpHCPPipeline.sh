#!/bin/bash 
set -x
#echo "This script must be SOURCED to correctly setup the environment prior to running any of the other HCP scripts contained here"
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	# if $SOURCE was a relative symlink, we need to resolve it relative to the
	#path where the symlink file was located
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
export HCPPIPEDIR=$DIR

# Set up FSL (if not already done so in the running environment)
if [ ! -d "$FSLDIR" ]; then
#	FSLDIR=/usr/local/fsl-5.0.7_64bit/
	FSLDIR=/usr/local/fsl-5.0.6_64bit/
fi
source ${FSLDIR}/etc/fslconf/fsl.sh

# Set up FreeSurfer (if not already done so in the running environment)
if [ ! -d "$FREESURFER_HOME" ]; then
	export FREESURFER_HOME=/usr/local/freesurfer-5.3.0/
fi
${FREESURFER_HOME}/SetUpFreeSurfer.sh 

if [ ! -d "$CARET7DIR" ]; then
	export CARET7DIR=/ifs/students/mchambers/connectome-workbench-1.0/bin_rh_linux64
fi

# Set Up DCM2NII
export PATH=$PATH:/ifs/students/mchambers/mricron/

# gradunwarp, from https://github.com/Washington-University/gradunwarp.git
export PATH=$PATH:/ifs/students/mchambers/anaconda/bin/

export HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
export HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries
export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config

export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
export HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
export HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
export HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
export HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
export HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts
export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography/scripts
export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
export HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts
export MSMBin=${HCPPIPEDIR}/MSMBinaries

## WASHU config - as understood by MJ - (different structure from the GIT repository)
## Also look at: /nrgpackages/scripts/tools_setup.sh

# Set up FSL (if not already done so in the running environment)
#FSLDIR=/nrgpackages/scripts
#. ${FSLDIR}/fsl5_setup.sh

# Set up FreeSurfer (if not already done so in the running environment)
#FREESURFER_HOME=/nrgpackages/tools/freesurfer5
#. ${FREESURFER_HOME}/SetUpFreeSurfer.sh

#NRG_SCRIPTS=/nrgpackages/scripts#. ${NRG_SCRIPTS}/epd-python_setup.sh

#export HCPPIPEDIR=/home/NRG/jwilso01/dev/Pipelines
#export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
#export HCPPIPEDIR_FS=/data/intradb/pipeline/catalog/StructuralHCP/resources/scripts
#export HCPPIPEDIR_PostFS=/data/intradb/pipeline/catalog/StructuralHCP/resources/scripts

#export HCPPIPEDIR_FIX=/data/intradb/pipeline/catalog/FIX_HCP/resources/scripts
#export HCPPIPEDIR_Diffusion=/data/intradb/pipeline/catalog/DiffusionHCP/resources/scripts
#export HCPPIPEDIR_Functional=/data/intradb/pipeline/catalog/FunctionalHCP/resources/scripts

#export HCPPIPETOOLS=/nrgpackages/tools/HCP
#export HCPPIPEDIR_Templates=/nrgpackages/atlas/HCP
#export HCPPIPEDIR_Bin=${HCPPIPETOOLS}/bin
#export HCPPIPEDIR_Config=${HCPPIPETOOLS}/conf
#export HCPPIPEDIR_Global=${HCPPIPETOOLS}/scripts_v2

#export CARET7DIR=${HCPPIPEDIR_Bin}/caret7/bin_linux64
## may or may not want the above variables to be setup as above
##    (if so then the HCPPIPEDIR line needs to go before them)
## end of WASHU config


# The following is probably unnecessary on most systems
#PATH=${PATH}:/vols/Data/HCP/pybin/bin/
#PYTHONPATH=/vols/Data/HCP/pybin/lib64/python2.6/site-packages/


#echo "Unsetting SGE_ROOT for testing mode only"
#unset SGE_ROOT

PATH=/ifs/students/mchambers/anaconda/bin:$PATH
PYTHONPATH="/ifs/students/mchambers/anaconda/"


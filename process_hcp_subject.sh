#!/bin/bash
set -x
SubjectId=$1
SourceDir=$2
StudyFolder=$3
if [ $# != 3 ]; then 
	echo "Usage:"
	echo "$0 SubjectId SourceDir StudyFolder"
	exit -1
fi

echo Study Folder: $StudyFolder
echo Subject Id: $SubjectId
StudyFolder=`readlink -f $StudyFolder`/$SubjectId
SourceDir=`readlink -f $SourceDir`
echo Subject Folder: $

source $HCPPIPEDIR/SetUpHCPPipeline.sh
source $HCPPIPEDIR/HCPDefaults.sh

T1wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*T1w*.nii.gz | xargs | tr ' ' '@'`;
MagnitudeInputName=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Magnitude.nii.gz | xargs | tr ' ' '@'`;
PhaseInputName=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Phase.nii.gz | xargs | tr ' ' '@'`;
T2wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T2w*/$SubjectId*T2w*.nii.gz | xargs | tr ' ' '@'`;
DWIPosData=`ls $SourceDir/$SubjectId/unprocessed/3T/Diffusion/*DWI_dir95_RL.nii.gz | xargs | tr ' ' '@'`;
DWINegData=`ls $SourceDir/$SubjectId/unprocessed/3T/Diffusion/*DWI_dir95_LR.nii.gz | xargs | tr ' ' '@'`;

echo $T1wInputImages
echo $T2wInputImages
echo $MagnitudeInputName
echo $PhaseInputName
echo $DWINegData
echo $DWIPosData

if [ "$T1wInputImages" == "" ] || [ "$T2wInputImages" == "" ] || 
	[ "$MagnitudeInputName" == "" ] || [ "$PhaseInputName" == "" ] || 
	[ "$DWINegData" == "" ] || [ "$DWIPosData" == "" ] ; then
	echo "Some Files Not Found"
	exit -1
fi

>&2 echo "Pre-Freesurfer"
echo Pre-Freesurfer
${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
 --path="$StudyFolder/$SubjectId" \
 --SubjectId="$SubjectId" \
 --t1="$T1wInputImages" \
 --t2="$T2wInputImages" \
 --t1template="$T1wTemplate" \
 --t1templatebrain="$T1wTemplateBrain" \
 --t1template2mm="$T1wTemplate2mm" \
 --t2template="$T2wTemplate" \
 --t2templatebrain="$T2wTemplateBrain" \
 --t2template2mm="$T2wTemplate2mm" \
 --templatemask="$TemplateMask" \
 --template2mmmask="$Template2mmMask" \
 --brainsize="$BrainSize" \
 --fnirtconfig="$FNIRTConfig" \
 --fmapmag="$MagnitudeInputName" \
 --fmapphase="$PhaseInputName" \
 --echodiff="$TE" \
 --SEPhaseNeg="NONE" \
 --SEPhasePos="NONE" \
 --echospacing="NONE" \
 --seunwarpdir="NONE" \
 --t1samplespacing="$T1wSampleSpacing" \
 --t2samplespacing="$T2wSampleSpacing" \
 --unwarpdir="$T1UnwarpDir" \
 --gdcoeffs="$GradientDistortionCoeffs" \
 --avgrdcmethod="$AvgrdcSTRING" \
 --topupconfig="NONE" \
 --printcom=$PRINTCOM

>&2 echo "Freesurfer"
echo FreeSurfer Processing
${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
 --SubjectDIR="$StudyFolder" \
 --subject="$SubjectId" \
 --T1wImage="$StudyFolder"/"$SubjectId"/T1w/T1w.nii.gz \
 --T1wImageBrain="$StudyFolder"/"$SubjectId"/T1w/BrainExtraction_FNIRTbased \
 --T2wImage="$StudyFolder"/"$SubjectId"/T2w/T2w.nii.gz
#
#>&2 echo "Post-Freesurfer"
#echo Post-FreeSurfer Processing
#${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh \
# --path="$StudyFolder" \
# --subject="$SubjectId" \
# --surfatlasdir="$SurfaceAtlasDIR" \
# --grayordinatesdir="$GrayordinatesSpaceDIR" \
# --grayordinatesres="$GrayordinatesResolutions" \
# --hiresmesh="$HighResMesh" \
# --lowresmesh="$LowResMeshes" \
# --subcortgraylabels="$SubcorticalGrayLabels" \
# --freesurferlabels="$FreeSurferLabels" \
# --refmyelinmaps="$ReferenceMyelinMaps" \
# --regname="$RegName" \
# --printcom=$PRINTCOM
#
#>&2 echo "Diffusion Processing"
#echo Diffusion Processing
#${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
# --path="${StudyFolder}" \
# --SubjectId="${SubjectId}" \
# --posData="${DWIPosData}" \
# --negData="${DWINegData}" \
# --echospacing="${EchoSpacing}" \
# --PEdir=${PEdir} \
# --gdcoeffs="${Gdcoeffs}" \
# --printcom=$PRINTCOM
#
#>&2 echo "fMRI Task Processing"
#echo fMRI Task Processing 
#Tasklist="tfMRI_EMOTION_RL tfMRI_EMOTION_LR"
#for fMRIName in $Tasklist ; do
#    fMRITimeSeries="${StudyFolder}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_${fMRIName}.nii.gz"
#	
#	# A single band reference image (SBRef) is recommended if using multiband,
#	# set to NONE if you want to use the first volume of the timeseries for
#	# motion correction
#	fMRISBRef="${StudyFolder}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_${fMRIName}_SBRef.nii.gz"
#
#	# For the spin echo field map volume with a negative phase encoding direction 
#	# LR in HCP data
#	# AP in 7T HCP data
#	# NONE if using regular FIELDMAP
#	FMRISpinEchoPhaseEncodeNegative="${StudyFolder}/${Subject}/unprocessed/3T/"\
#		"${fMRIName}/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz" 
#	
#	# RL in HCP data
#	# PA in 7T HCP data
#	SpinEchoPhaseEncodePositive="${StudyFolder}/${Subject}/unprocessed/3T/"\
#		"${fMRIName}/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz" 
#
#    ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
#     --path=$StudyFolder \
#     --subject=$SubjectId \
#     --fmriname=$fMRIName \
#     --fmritcs=$fMRITimeSeries \
#     --fmriscout=$fMRISBRef \
#     --SEPhaseNeg=$FMRISpinEchoPhaseEncodeNegative \
#     --SEPhasePos=$FMRISpinEchoPhaseEncodePositive \
#     --fmapmag="NONE" \
#     --fmapphase="NONE" \
#     --echospacing=$FMRIDwellTime \
#     --echodiff="NONE" \
#     --unwarpdir=$FMRIUnwarpDir \
#     --fmrires=$FinalFMRIResolution \
#     --dcmethod=$FMRIDistortionCorrection \
#     --gdcoeffs="NONE" \
#     --topupconfig=$TopUpConfig \
#     --printcom=$PRINTCOM
#
#done

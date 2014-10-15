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

StudyFolder=`readlink -f $StudyFolder`
SourceDir=`readlink -f $SourceDir`

source $HCPPIPEDIR/SetUpHCPPipeline.sh
source $HCPPIPEDIR/HCPDefaults.sh

T1wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*T1w*.nii.gz | xargs | tr ' ' '@'`;
MagnitudeInputName=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Magnitude.nii.gz | xargs | tr ' ' '@'`;
PhaseInputName=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Phase.nii.gz | xargs | tr ' ' '@'`;
T2wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T2w*/$SubjectId*T2w*.nii.gz | xargs | tr ' ' '@'`;
DWI_PosData=`ls $SourceDir/$SubjectId/unprocessed/3T/Diffusion/*DWI_dir95_RL.nii.gz | xargs | tr ' ' '@'`;
DWI_NegData=`ls $SourceDir/$SubjectId/unprocessed/3T/Diffusion/*DWI_dir95_LR.nii.gz | xargs | tr ' ' '@'`;

echo $T1wInputImages
echo $T2wInputImages
echo $MagnitudeInputName
echo $PhaseInputName
echo $DWI_NegData
echo $DWI_PosData

if [ "$T1wInputImages" == "" ] || [ "$T2wInputImages" == "" ] || 
	[ "$MagnitudeInputName" == "" ] || [ "$PhaseInputName" == "" ] || 
	[ "$DWI_NegData" == "" ] || [ "$DWI_PosData" == "" ] ; then
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
 --subjectDIR="$StudyFolder/$SubjectId/T1w/" \
 --subject="$SubjectId" \
 --t1="$StudyFolder"/"$SubjectId"/T1w/T1w.nii.gz \
 --t1brain="$StudyFolder"/"$SubjectId"/T1w/T1w_acpc_brain.nii.gz \
 --t2="$StudyFolder"/"$SubjectId"/T2w/T2w.nii.gz

>&2 echo "Post-Freesurfer"
echo Post-FreeSurfer Processing
${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh \
 --path="$StudyFolder" \
 --subject="$SubjectId" \
 --surfatlasdir="$SurfaceAtlasDIR" \
 --grayordinatesdir="$GrayordinatesSpaceDIR" \
 --grayordinatesres="$GrayordinatesResolutions" \
 --hiresmesh="$HighResMesh" \
 --lowresmesh="$LowResMeshes" \
 --subcortgraylabels="$SubcorticalGrayLabels" \
 --freesurferlabels="$FreeSurferLabels" \
 --refmyelinmaps="$ReferenceMyelinMaps" \
 --regname="$RegName" \
 --printcom=$PRINTCOM

>&2 echo "Diffusion Processing"
echo Diffusion Processing
${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
 --path="${StudyFolder}" \
 --subject="${SubjectId}" \
 --posData="${DWI_PosData}" \
 --negData="${DWI_NegData}" \
 --echospacing="${DWI_EchoSpacing}" \
 --PEdir=${DWI_PEdir} \
 --gdcoeffs="${DWI_Gdcoeffs}" \
 --printcom=$PRINTCOM

>&2 echo "fMRI Task Processing"
echo fMRI Task Processing 
Tasklist="tfMRI_EMOTION_RL tfMRI_EMOTION_LR"
for FMRI_Name in $Tasklist ; do
    FMRI_TimeSeries="${SourceDir}/${SubjectId}/unprocessed/3T/${FMRI_Name}/${SubjectId}_3T_${FMRI_Name}.nii.gz"
	
	# A single band reference image (SBRef) is recommended if using multiband,
	# set to NONE if you want to use the first volume of the timeseries for
	# motion correction
	FMRI_SBRef="${SourceDir}/${SubjectId}/unprocessed/3T/${FMRI_Name}/${SubjectId}_3T_${FMRI_Name}_SBRef.nii.gz"

	# For the spin echo field map volume with a negative phase encoding direction 
	# LR in HCP data
	# AP in 7T HCP data
	# NONE if using regular FIELDMAP
	FMRI_SpinEchoPhaseEncodeNegative="${SourceDir}/${Subject}/unprocessed/3T/${FMRI_Name}/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz" 
	
	# RL in HCP data
	# PA in 7T HCP data
	FMRI_SpinEchoPhaseEncodePositive="${SourceDir}/${Subject}/unprocessed/3T/${FMRI_Name}/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz" 

    ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
     --path=$StudyFolder \
     --subject=$SubjectId \
     --fmriname=$FMRI_Name \
     --fmritcs=$FMRI_TimeSeries \
     --fmriscout=$FMRI_SBRef \
     --SEPhaseNeg=${FMRI_SpinEchoPhaseEncodeNegative} \
     --SEPhasePos=${FMRI_SpinEchoPhaseEncodePositive} \
     --fmapmag="NONE" \
     --fmapphase="NONE" \
     --echospacing=${FMRI_DwellTime} \
     --echodiff="NONE" \
     --unwarpdir=${FMRI_UnwarpDir} \
     --fmrires=${FMRI_FinalResolution} \
     --dcmethod=${FMRI_DistortionCorrection} \
     --gdcoeffs="NONE" \
     --topupconfig=${FMRI_TopUpConfig} \
     --printcom=$PRINTCOM

done

# MOVE TO MULTI SUBJECT
#for FinalSmoothingFWHM in $SmoothingList ; do
#  echo $FinalSmoothingFWHM
#
#  i=1
#  for LevelTwoTask in $LevelTwoTaskList ; do
#    echo "  ${LevelTwoTask}"
#
#    LevelOneTasks=`echo $LevelOneTasksList | cut -d " " -f $i`
#    LevelOneFSFs=`echo $LevelOneFSFsList | cut -d " " -f $i`
#    LevelTwoTask=`echo $LevelTwoTaskList | cut -d " " -f $i`
#    LevelTwoFSF=`echo $LevelTwoFSFList | cut -d " " -f $i`
#    for Subject in $Subjlist ; do
#      echo "    ${Subject}"
#
#      if [ -n "${command_line_specified_run_local}" ] ; then
#          echo "About to run ${HCPPIPEDIR}/TaskfMRIAnalysis/TaskfMRIAnalysis.sh"
#          queuing_command=""
#      else
#          echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/TaskfMRIAnalysis/TaskfMRIAnalysis.sh"
#          queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
#      fi
#
#      ${queuing_command} ${HCPPIPEDIR}/TaskfMRIAnalysis/TaskfMRIAnalysis.sh \
#        --path=$StudyFolder \
#        --subject=$Subject \
#        --lvl1tasks=$LevelOneTasks \
#        --lvl1fsfs=$LevelOneFSFs \
#        --lvl2task=$LevelTwoTask \
#        --lvl2fsf=$LevelTwoFSF \
#        --lowresmesh=$LowResMesh \
#        --grayordinatesres=$GrayOrdinatesResolution \
#        --origsmoothingFWHM=$OriginalSmoothingFWHM \
#        --confound=$Confound \
#        --finalsmoothingFWHM=$FinalSmoothingFWHM \
#        --temporalfilter=$TemporalFilter \
#        --vba=$VolumeBasedProcessing
#
#  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...
#
#        echo "set -- --path=$StudyFolder \
#        --subject=$Subject \
#        --lvl1tasks=$LevelOneTasks \
#        --lvl1fsfs=$LevelOneFSFs \
#        --lvl2task=$LevelTwoTask \
#        --lvl2fsf=$LevelTwoFSF \
#        --lowresmesh=$LowResMesh \
#        --grayordinatesres=$GrayOrdinatesResolution \
#        --origsmoothingFWHM=$OriginalSmoothingFWHM \
#        --confound=$Confound \
#        --finalsmoothingFWHM=$FinalSmoothingFWHM \
#        --temporalfilter=$TemporalFilter \
#        --vba=$VolumeBasedProcessing"
#
#        echo ". ${EnvironmentScript}"
#
#    done
#    i=$(($i+1))
#  done
#done

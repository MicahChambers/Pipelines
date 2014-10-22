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

# Convert Images From Dicom
for dd in `ls -d $SourceDir/$SubjectId/*`; do
	fname=$dd/`ls $dd -1 | head -n 1`
	echo $fname;
	mkdir -p $StudyFolder/$SubjectId/nii
	dcm2nii -r n -x n -a n -d n -e n -f y -g y -i n -n y -p n -o $StudyFolder/$SubjectId/nii $fname
	oname=`basename $fname`
	oname=${oname%.*}
	oname=`echo $oname | tr -d '.'`
	mv $StudyFolder/$SubjectId/nii/$oname.nii.gz $StudyFolder/$SubjectId/nii/`basename $dd`.nii.gz
	if [[ -e $StudyFolder/$SubjectId/nii/$oname.bvec ]]; then
		mv $StudyFolder/$SubjectId/nii/$oname.bvec  $StudyFolder/$SubjectId/nii/`basename $dd`.bvec
	fi
	if [[ -e $StudyFolder/$SubjectId/nii/$oname.bval ]]; then
		mv $StudyFolder/$SubjectId/nii/$oname.bval $StudyFolder/$SubjectId/nii/`basename $dd`.bval
	fi
done

source $HCPPIPEDIR/UCLADefaults.sh

if [[ ! "$MULTIINPUTS" == "true" ]]; then
	T1wInputImages="${T1wInputImages%@*}"
	T2wInputImages="${T2wInputImages%@*}"
	T1T2_FMAP_PhaseImages="${T1T2_FMAP_PhaseImages%@*}"
	T1T2_FMAP_MagImages="${T1T2_FMAP_MagImages%@*}"
	T1T2_SE_PhaseNegImages="${T1T2_SE_PhaseNegImages%@*}"
	T1T2_SE_PhasePosImages="${T1T2_SE_PhasePosImages%@*}"
	DWI_NegImages="${DWI_NegImages%@*}"
	DWI_PosImages="${DWI_posImages%@*}"
fi

echo $T1wInputImages
echo $T2wInputImages
echo $MagnitudeInputName
echo $PhaseInputName
echo $DWI_NegData
echo $DWI_PosData

if [ "$T1wInputImages" == "" ] ; then
	echo "T1 input not found"
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
 --fmapmag="$T1T2_FMAP_MagImages" \
 --fmapphase="$T1T2_FMAP_PhaseImages" \
 --echodiff="$T1T2_FMAP_TE" \
 --SEPhaseNeg="$T1T2_SE_PhaseNegImages" \
 --SEPhasePos="$T1T2_SE_PhasePosImages" \
 --echospacing="$T1T2_SE_DwellTime" \
 --seunwarpdir="$T1T2_SE_UnwarpDir" \
 --topupconfig="$T1T2_SE_TopUpConfig" \
 --t1samplespacing="$T1wSampleSpacing" \
 --t2samplespacing="$T2wSampleSpacing" \
 --unwarpdir="$T1UnwarpDir" \
 --gdcoeffs="$GradientDistortionCoeffs" \
 --avgrdcmethod="$AvgrdcSTRING" \
 --printcom=$PRINTCOM

>&2 echo "Freesurfer"
echo FreeSurfer Processing
${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
 --subject="$SubjectId" \
 --subjectDIR="$StudyFolder/$SubjectId/T1w/" \
 --t1="$StudyFolder"/"$SubjectId"/T1w/T1w_acpc_dc_restore.nii.gz \
 --t1brain="$StudyFolder"/"$SubjectId"/T1w/T1w_acpc_dc_restore_brain.nii.gz \
 --t2="$StudyFolder"/"$SubjectId"/T1w/T2w_acpc_dc_restore.nii.gz

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

if [[ -e ${DWI_NegImages%@*} ]] && [[ -e ${DWI_PosImages%@*} ]]; then
	>&2 echo "Diffusion Processing"
	echo Diffusion Processing
	${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
	--path="${StudyFolder}" \
	--subject="${SubjectId}" \
	--posData="${DWI_PosImages}" \
	--negData="${DWI_NegImages}" \
	--echospacing="${DWI_EchoSpacing}" \
	--PEdir=${DWI_PEdir} \
	--gdcoeffs="${DWI_Gdcoeffs}" \
	--printcom=$PRINTCOM
fi

#>&2 echo "fMRI Task Processing"
#echo fMRI Task Processing
#
#Tasklist=("RFMRI_REST_AP_FIRST" "RFMRI_REST_AP_SECOND" "RFMRI_REST_AP_" "RFMRI_REST_AP")
#PhaseEncodinglist=("y" "y" "y-" "y-") #x for RL, x- for LR, y for PA, y- for AP
#for (( i=0; i<${#Tasklist[@]}; i++ )) ; do
#    UnwarpDir=${PhaseEncodinglist[$i]}
#	fMRIName=${Tasklist[$i]}
#
#    fMRITimeSeries="$StudyFolder/$SubjectId/nii/${fMRIName}/${SubjectId}_3T_${fMRIName}.nii.gz"
#	
#	# A single band reference image (SBRef) is recommended if using multiband,
#	# set to NONE if you want to use the first volume of the timeseries for
#	# motion correction
#    fMRISBRef="${StudyFolder}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_${fMRIName}_SBRef.nii.gz"
#
#	# For the spin echo field map volume with a negative phase encoding
#	# direction (LR in HCP data, AP in 7T HCP data), set to NONE if using
#	# regular FIELDMAP
#    SpinEchoPhaseEncodeNegative="${StudyFolder}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_SpinEchoFieldMap_LR.nii.gz"
#    SpinEchoPhaseEncodePositive="${StudyFolder}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_SpinEchoFieldMap_RL.nii.gz"
#
#    ${queuing_command} ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
#      --path=${StudyFolder} \
#      --subject=${SubjectId} \
#      --fmriname=${fMRIName} \
#      --fmritcs=${fMRITimeSeries} \
#      --fmriscout=${fMRISBRef} \
#      --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
#      --SEPhasePos=${SpinEchoPhaseEncodePositive} \
#      --fmapmag="NONE" \
#      --fmapphase="NONE" \
#      --echospacing=${FMRI_DwellTime} \
#      --echodiff="NONE" \
#      --unwarpdir=${UnwarpDir} \
#      --fmrires=${FMRI_FinalResolution} \
#      --dcmethod="TOPUP" \
#      --gdcoeffs="NONE"\
#      --topupconfig=$FMRI_TopUpConfig \
#      --printcom=$PRINTCOM
#done
#
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

##### from Example
####Tasklist="tfMRI_EMOTION_RL tfMRI_EMOTION_LR"
####PhaseEncodinglist="x x-" #x for RL, x- for LR, y for PA, y- for AP
####
####for Subject in $Subjlist ; do
####  echo $Subject
####
####  i=1
####  for fMRIName in $Tasklist ; do
####    echo "  ${fMRIName}"
####    UnwarpDir=`echo $PhaseEncodinglist | cut -d " " -f $i`
####    fMRITimeSeries="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${Subject}_3T_${fMRIName}.nii.gz"
####    fMRISBRef="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${Subject}_3T_${fMRIName}_SBRef.nii.gz" #A single band reference image (SBRef) is recommended if using multiband, set to NONE if you want to use the first volume of the timeseries for motion correction
####    DwellTime="0.00058" #Echo Spacing or Dwelltime of fMRI image, set to NONE if not used. Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples): DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode, DICOM field (0051,100b) AcquisitionMatrixText first value (# of phase encoding samples).  On Siemens, iPAT/GRAPPA factors have already been accounted for.
####    DistortionCorrection="TOPUP" #FIELDMAP or TOPUP, distortion correction is required for accurate processing
####    SpinEchoPhaseEncodeNegative="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz" #For the spin echo field map volume with a negative phase encoding direction (LR in HCP data, AP in 7T HCP data), set to NONE if using regular FIELDMAP
####    SpinEchoPhaseEncodePositive="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz" #For the spin echo field map volume with a positive phase encoding direction (RL in HCP data, PA in 7T HCP data), set to NONE if using regular FIELDMAP
####    MagnitudeInputName="NONE" #Expects 4D Magnitude volume with two 3D timepoints, set to NONE if using TOPUP
####    PhaseInputName="NONE" #Expects a 3D Phase volume, set to NONE if using TOPUP
####    DeltaTE="NONE" #2.46ms for 3T, 1.02ms for 7T, set to NONE if using TOPUP
####    FinalFMRIResolution="2" #Target final resolution of fMRI data. 2mm is recommended for 3T HCP data, 1.6mm for 7T HCP data (i.e. should match acquired resolution).  Use 2.0 or 1.0 to avoid standard FSL templates
####    # GradientDistortionCoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" #Gradient distortion correction coefficents, set to NONE to turn off
####    GradientDistortionCoeffs="NONE" # SEt to NONE to skip gradient distortion correction
####    TopUpConfig="${HCPPIPEDIR_Config}/b02b0.cnf" #Topup config if using TOPUP, set to NONE if using regular FIELDMAP
####
####    if [ -n "${command_line_specified_run_local}" ] ; then
####        echo "About to run ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh"
####        queuing_command=""
####    else
####        echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh"
####        queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
####    fi
####
####    ${queuing_command} ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
####      --path=$StudyFolder \
####      --subject=$Subject \
####      --fmriname=$fMRIName \
####      --fmritcs=$fMRITimeSeries \
####      --fmriscout=$fMRISBRef \
####      --SEPhaseNeg=$SpinEchoPhaseEncodeNegative \
####      --SEPhasePos=$SpinEchoPhaseEncodePositive \
####      --fmapmag=$MagnitudeInputName \
####      --fmapphase=$PhaseInputName \
####      --echospacing=$DwellTime \
####      --echodiff=$DeltaTE \
####      --unwarpdir=$UnwarpDir \
####      --fmrires=$FinalFMRIResolution \
####      --dcmethod=$DistortionCorrection \
####      --gdcoeffs=$GradientDistortionCoeffs \
####      --topupconfig=$TopUpConfig \
####      --printcom=$PRINTCOM
####
####  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...
####
####  echo "set -- --path=$StudyFolder \
####      --subject=$Subject \
####      --fmriname=$fMRIName \
####      --fmritcs=$fMRITimeSeries \
####      --fmriscout=$fMRISBRef \
####      --SEPhaseNeg=$SpinEchoPhaseEncodeNegative \
####      --SEPhasePos=$SpinEchoPhaseEncodePositive \
####      --fmapmag=$MagnitudeInputName \
####      --fmapphase=$PhaseInputName \
####      --echospacing=$DwellTime \
####      --echodiff=$DeltaTE \
####      --unwarpdir=$UnwarpDir \
####      --fmrires=$FinalFMRIResolution \
####      --dcmethod=$DistortionCorrection \
####      --gdcoeffs=$GradientDistortionCoeffs \
####      --topupconfig=$TopUpConfig \
####      --printcom=$PRINTCOM"
####
####  echo ". ${EnvironmentScript}"
####	
####    i=$(($i+1))
####  done
####done
####
####

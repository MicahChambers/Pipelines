#!/bin/bash

set -x
## TODO add indicators for DONE sections, then only re-run if --force is given
MULTIINPUTS=false

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

DiffusionTypes=("${SubjectId}_3T_DWI_dir95" "${SubjectId}_3T_DWI_dir96" "${SubjectId}_3T_DWI_dir97")

if [[ "$MULTIINPUTS" == "true" ]]; then
	T1wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*T1w*.nii.gz | xargs | tr ' ' '@'`;
	T1T2_FMAP_MagImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Magnitude.nii.gz | xargs | tr ' ' '@'`;
	T1T2_FMAP_PhaseImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Phase.nii.gz | xargs | tr ' ' '@'`;
	T2wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T2w*/$SubjectId*T2w*.nii.gz | xargs | tr ' ' '@'`;
else
	T1wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*T1w*.nii.gz | head -n 1`
	T1T2_FMAP_MagImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Magnitude.nii.gz | head -n 1`
	T1T2_FMAP_PhaseImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T1w*/$SubjectId*FieldMap_Phase.nii.gz | head -n 1`
	T2wInputImages=`ls $SourceDir/$SubjectId/unprocessed/3T/T2w*/$SubjectId*T2w*.nii.gz | head -n 1`
fi

if [ "$T1wInputImages" == "" ] || [ "$T2wInputImages" == "" ] ||
	[ "$T1T2_FMAP_MagImages" == "" ] || [ "$T1T2_FMAP_PhaseImages" == "" ] ; then
	echo "Some Files Not Found"
	exit -1
fi

if [[ -e $StudyFolder/$SubjectId/prefreesurfer.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/prefreesurfer.done` -eq 1 ]]; then
   echo "Skipping Pre-Freesurfer Processing, to force it, remove " \
   		"$StudyFolder/$SubjectId/prefreesurfer.done "
else
	>&2 echo "Pre-Freesurfer Processing"
	echo Pre-Freesurfer Processing
	${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
	 --path="$StudyFolder" \
	 --subject="$SubjectId" \
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
	 echo '1' > $StudyFolder/$SubjectId/prefreesurfer.done
	 rm -f $StudyFolder/$SubjectId/freesurfer.done
fi

if [[ -e $StudyFolder/$SubjectId/freesurfer.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/freesurfer.done` -eq 1 ]]; then
   echo "Skipping Freesurfer Processing, to force it, remove " \
   		"$StudyFolder/$SubjectId/freesurfer.done "
else
		>&2 echo "Freesurfer Processing"
		echo FreeSurfer Processing
		${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
		--subject="$SubjectId" \
		--subjectDIR="$StudyFolder/$SubjectId/T1w/" \
		--t1="$StudyFolder"/"$SubjectId"/T1w/T1w_acpc_dc_restore.nii.gz \
		--t1brain="$StudyFolder"/"$SubjectId"/T1w/T1w_acpc_dc_restore_brain.nii.gz \
		--t2="$StudyFolder"/"$SubjectId"/T1w/T2w_acpc_dc_restore.nii.gz

		echo '1' > $StudyFolder/$SubjectId/freesurfer.done
		rm -f $StudyFolder/$SubjectId/postfreesurfer.done
fi

if [[ -e $StudyFolder/$SubjectId/postfreesurfer.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/postfreesurfer.done` -eq 1 ]]; then
   echo "Skipping Post-Freesurfer Processing, to force it, remove " \
   		"$StudyFolder/$SubjectId/posfreesurfer.done "
else
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
	echo '1' > $StudyFolder/$SubjectId/postfreesurfer.done
	rm -f $StudyFolder/$SubjectId/diffusion.done
	rm -f $StudyFolder/$SubjectId/genericfmri.done
fi

if [[ -e $StudyFolder/$SubjectId/diffusion.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/diffusion.done` -eq 1 ]]; 
then
   echo "Skipping Diffusion Processing, to force it, remove " \
   		"$StudyFolder/$SubjectId/diffusion.done "
else
	>&2 echo "Diffusion Processing"
	echo Diffusion Processing
	for img in $DiffusionTypes; do 
		DWI_Pos="$SourceDir/$SubjectId/unprocessed/3T/Diffusion/${img}_RL.nii.gz"
		DWI_Neg="$SourceDir/$SubjectId/unprocessed/3T/Diffusion/${img}_LR.nii.gz"

		${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
		--path="${StudyFolder}" \
		--subject="${SubjectId}" \
		--posData="${DWI_Pos}" \
		--negData="${DWI_Neg}" \
		--echospacing="${DWI_EchoSpacing}" \
		--PEdir=${DWI_PEdir} \
		--gdcoeffs="${DWI_Gdcoeffs}" \
		--printcom=$PRINTCOM
	done
	
	echo '1' > $StudyFolder/$SubjectId/diffusion.done
fi

if [[ -e $StudyFolder/$SubjectId/genericfmri.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/genericfmri.done` -eq 1 ]]; 
then
   echo "Skipping fMRI Task Processing, to force it, remove " \
   		"$StudyFolder/$SubjectId/posfreesurfer.done "
else
	>&2 echo "fMRI Task Processing"
	echo fMRI Task Processing

	#x for RL, x- for LR, y for PA, y- for AP
	PhaseEncodinglist=(
	"x-" "x" \
	"x-" "x" \
	"x-" "x" \
	"x-" "x" \
	"x-" "x" \
	"x-" "x" \
	"x-" "x" \
	"x-" "x" \
	"x-" "x")

	Tasklist=(
	"rfMRI_REST1_LR" "rfMRI_REST1_RL" \
	"rfMRI_REST2_LR" "rfMRI_REST2_RL" \
	"tfMRI_EMOTION_LR" "tfMRI_EMOTION_RL" \
	"tfMRI_GAMBLING_LR" "tfMRI_GAMBLING_RL" \
	"tfMRI_LANGUAGE_LR" "tfMRI_LANGUAGE_RL" \
	"tfMRI_MOTOR_LR" "tfMRI_MOTOR_RL" \
	"tfMRI_RELATIONAL_LR" "tfMRI_RELATIONAL_RL" \
	"tfMRI_SOCIAL_LR" "tfMRI_SOCIAL_RL" \
	"tfMRI_WM_LR" "tfMRI_WM_RL")

	for (( i=0; i<${#Tasklist[@]}; i++ )) ; do
		UnwarpDir=${PhaseEncodinglist[$i]}
		fMRIName=${Tasklist[$i]}

		fMRITimeSeries="${SourceDir}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_${fMRIName}.nii.gz"

		# A single band reference image (SBRef) is recommended if using multiband,
		# set to NONE if you want to use the first volume of the timeseries for
		# motion correction
		fMRISBRef="${SourceDir}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_${fMRIName}_SBRef.nii.gz"

		# For the spin echo field map volume with a negative phase encoding
		# direction (LR in HCP data, AP in 7T HCP data), set to NONE if using
		# regular FIELDMAP
		SpinEchoPhaseEncodeNegative="${SourceDir}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_SpinEchoFieldMap_LR.nii.gz"
		SpinEchoPhaseEncodePositive="${SourceDir}/${SubjectId}/unprocessed/3T/${fMRIName}/${SubjectId}_3T_SpinEchoFieldMap_RL.nii.gz"

		${queuing_command} ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
		--path=${StudyFolder} \
		--subject=${SubjectId} \
		--fmriname=${fMRIName} \
		--fmritcs=${fMRITimeSeries} \
		--fmriscout=${fMRISBRef} \
		--SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
		--SEPhasePos=${SpinEchoPhaseEncodePositive} \
		--fmapmag="NONE" \
		--fmapphase="NONE" \
		--echospacing=${FMRI_DwellTime} \
		--echodiff="NONE" \
		--unwarpdir=${UnwarpDir} \
		--fmrires=${FMRI_FinalResolution} \
		--dcmethod="TOPUP" \
		--gdcoeffs="NONE" \
		--topupconfig=$FMRI_TopUpConfig \
		--printcom=$PRINTCOM
	done
	
	echo '1' > $StudyFolder/$SubjectId/genericfmri.done
fi

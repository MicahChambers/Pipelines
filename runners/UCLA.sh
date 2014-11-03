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

if [[ -e $StudyFolder/$SubjectId/fileconvert.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/fileconvert.done` -eq 1 ]]; then
	>&2 echo 'Skipping File Conversion Processing'
	echo Skipping File Convesion Processing
else
	>&2 echo 'File Conversion Processing'
	echo File Convesion Processing
	rm -fr $StudyFolder/$SubjectId/nii
	mkdir -p $StudyFolder/$SubjectId/nii
	# Convert Images From Dicom
	for dd in `ls -d $SourceDir/$SubjectId/*`; do
		fname=$dd/`ls $dd -1 | head -n 1`
		echo $fname;
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

	## Create Simlinks for fMRI Runs/ Spin Echo Images
	
	# DWI
	APCOUNT=0
	PACOUNT=0
	find ${StudyFolder}/$SubjectId/nii/ -type f -iname '*DWI*.nii.gz' -not -iname '*SBREF*.nii.gz' | sort | 
	while read line; do
		tmp=${line%.nii.gz}
		if [[ $tmp == *_AP_* ]]; then
			tmp=${tmp%_AP_*}_${APCOUNT}_AP
			ln -v -s -T $line $tmp.nii.gz
			if [[ -e ${line%.nii.gz}.bval ]]; then
				ln -s -T ${line%.nii.gz}.bval $tmp.bval
				ln -s -T ${line%.nii.gz}.bvec $tmp.bvec
			fi
			APCOUNT=$((APCOUNT+1))
		elif [[ $tmp == *_PA_* ]]; then
			tmp=${tmp%_PA_*}_${PACOUNT}_PA
			ln -s -T $line $tmp.nii.gz
			if [[ -e ${line%.nii.gz}.bval ]]; then
				ln -s -T ${line%.nii.gz}.bval $tmp.bval
				ln -s -T ${line%.nii.gz}.bvec $tmp.bvec
			fi
			PACOUNT=$((PACOUNT+1))
		fi
	done
	APCOUNT=0
	PACOUNT=0
	find ${StudyFolder}/$SubjectId/nii/ -type f -iname '*SBREF*.nii.gz' -iname '*DWI*.nii.gz' | sort |
	while read line; do
		tmp=${line%.nii.gz}
		if [[ $tmp == *_AP_* ]]; then
			tmp=${tmp%_AP_*}_${APCOUNT}_AP
			ln -v -s -T $line ${tmp}_SBREF.nii.gz
			APCOUNT=$((APCOUNT+1))
		elif [[ $tmp == *_PA_* ]]; then
			tmp=${tmp%_PA_*}_${PACOUNT}_PA
			ln -s -T $line ${tmp}_SBREF.nii.gz
			PACOUNT=$((PACOUNT+1))
		fi
	done
	
	# FMRI
	APCOUNT=0
	PACOUNT=0
	find ${StudyFolder}/$SubjectId/nii/ -type f -iname '*FMRI*.nii.gz' -not -iname '*SBREF*.nii.gz' | sort |
	while read line; do
		tmp=${line%.nii.gz}
		if [[ $tmp == *_AP_* ]]; then
			tmp=${tmp%_AP_*}_${APCOUNT}_AP
			ln -s -T $line ${tmp}.nii.gz
			APCOUNT=$((APCOUNT+1))
		elif [[ $tmp == *_PA_* ]]; then
			tmp=${tmp%_PA_*}_${PACOUNT}_PA
			ln -s -T $line ${tmp}.nii.gz
			PACOUNT=$((PACOUNT+1))
		fi
	done
	APCOUNT=0
	PACOUNT=0
	find ${StudyFolder}/$SubjectId/nii/ -type f -iname '*SBREF*.nii.gz' -iname '*FMRI*.nii.gz' | sort | 
	while read line; do
		tmp=${line%.nii.gz}
		if [[ $tmp == *_AP_* ]]; then
			tmp=${tmp%_AP_*}_${APCOUNT}_AP
			ln -v -s -T $line ${tmp}_SBREF.nii.gz
			APCOUNT=$((APCOUNT+1))
		elif [[ $tmp == *_PA_* ]]; then
			tmp=${tmp%_PA_*}_${PACOUNT}_PA
			ln -s -T $line ${tmp}_SBREF.nii.gz
			PACOUNT=$((PACOUNT+1))
		fi
	done
	
	# SPin Echo Fieldmaps
	APCOUNT=0
	PACOUNT=0
	find ${StudyFolder}/$SubjectId/nii/ -type f -name '*SPINECHOFIELDMAP*.nii.gz' | sort | 
	while read line; do 
		tmp=${line%.nii.gz}
		if [[ $tmp == *_PA_* ]]; then
			tmp=${tmp%_PA_*}_${PACOUNT}_PA
			ln -v -s -T $line ${tmp}_${PACOUNT}.nii.gz
			PACOUNT=$((PACOUNT+1))
		elif [[ $tmp == *_AP_* ]]; then
			tmp=${tmp%*_AP_*}_${APCOUNT}_AP
			ln -s -T $line ${tmp}_${APCOUNT}.nii.gz
			APCOUNT=$((APCOUNT+1))
		fi
	done
	
	echo '1' > $StudyFolder/$SubjectId/fileconvert.done
fi

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

if [ "$T1wInputImages" == "" ] ; then
	echo "T1 input not found"
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
	--echodiff="$T1T2_FMAP_TE" \
	--SEPhaseNeg="$T1T2_SE_PhaseNegImages" \
	--SEPhasePos="$T1T2_SE_PhasePosImages" \
	--echospacing="$T1T2_SE_DwellTime" \
	--seunwarpdir="$T1T2_SE_UnwarpDir" \
	--topupconfig="$T1T2_SE_TopUpConfig" \
	--t1samplespacing="$T1wSampleSpacing" \
	--t2samplespacing="$T2wSampleSpacing" \
	--unwarpdir="$T1UnwarpDir" \
	--gdcoeffs="${GradientDistortionCoeffs}" \
	--avgrdcmethod="$AvgrdcSTRING" \
	--printcom=$PRINTCOM
	 
	echo '1' > $StudyFolder/$SubjectId/prefreesurfer.done
	 rm -f $StudyFolder/$SubjectId/freesurfer.done
fi

if [[ -e $StudyFolder/$SubjectId/freesurfer.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/freesurfer.done` -eq 1 ]]; then
	echo "Skipping Freesurfer Processing, to force it, remove " \
	"$StudyFolder/$SubjectId/freesurfer.done "
	>&2 echo "Skipping Freesurfer Processing, to force it, remove " \
	"$StudyFolder/$SubjectId/freesurfer.done "
else
	>&2 echo "Freesurfer"
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
	[[ `head -n 1 $StudyFolder/$SubjectId/diffusion.done` -eq 1 ]]; then
   >&2 echo "Skipping Diffusion Processing, to force it, remove " \
   "$StudyFolder/$SubjectId/diffusion.done "
   echo "Skipping Diffusion Processing, to force it, remove " \
   "$StudyFolder/$SubjectId/diffusion.done "
else
	>&2 echo "Diffusion Processing"
	echo Diffusion Processing
	for img in $DiffusionTypes; do 
		DWI_Neg=$StudyFolder/$SubjectId/nii/${img}_PA.nii.gz
		DWI_Pos=$StudyFolder/$SubjectId/nii/${img}_AP.nii.gz
		${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline.sh \
		--path="${StudyFolder}" \
		--subject="${SubjectId}" \
		--posData="${DWI_Pos}" \
		--negData="${DWI_Neg}" \
		--echospacing="${DWI_EchoSpacing}" \
		--PEdir=${DWI_PEdir} \
		--gdcoeffs="${GradientDistortionCoeffs}" \
		--printcom=$PRINTCOM
	done
	
	echo '1' > $StudyFolder/$SubjectId/diffusion.done
fi

if [[ -e $StudyFolder/$SubjectId/genericfmri.done ]] && 
	[[ `head -n 1 $StudyFolder/$SubjectId/genericfmri.done` -eq 1 ]]; 
then
   >&2 echo "Skipping fMRI Processing, to force it, remove " \
   		"$StudyFolder/$SubjectId/genericfmri.done "
   echo "Skipping fMRI Processing, to force it, remove " \
   		"$StudyFolder/$SubjectId/genericfmri.done "
else
	>&2 echo "fMRI Processing"
	echo fMRI Processing

	Tasklist=("RFMRI_REST_AP_0" "RFMRI_REST_AP_1" "RFMRI_REST_PA_0" "RFMRI_REST_PA_1")
	PhaseEncodinglist=("y" "y" "y-" "y-") #x for RL, x- for LR, y for PA, y- for AP
	for (( i=0; i<${#Tasklist[@]}; i++ )) ; do
		UnwarpDir=${PhaseEncodinglist[$i]}
		fMRIName=${Tasklist[$i]}

		fMRITimeSeries=`ls $StudyFolder/$SubjectId/nii/${fMRIName}.nii.gz`

		# A single band reference image (SBRef) is recommended if using multiband,
		# set to NONE if you want to use the first volume of the timeseries for
		# motion correction
		fMRISBRef=`ls $StudyFolder/$SubjectId/nii/${fMRIName}_SBREF.nii.gz`

		# For the spin echo field map volume with a negative phase encoding
		# direction (LR in HCP data, AP in 7T HCP data), set to NONE if using
		# regular FIELDMAP
		SpinEchoPhaseEncodeNegative=`ls ${StudyFolder}/${SubjectId}/nii/SPINECHOFIELDMAP_AP_0.nii.gz`
		SpinEchoPhaseEncodePositive=`ls ${StudyFolder}/${SubjectId}/nii/SPINECHOFIELDMAP_PA_0.nii.gz`

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
		--gdcoeffs="${GradientDistortionCoeffs}" \
		--topupconfig=$FMRI_TopUpConfig \
		--printcom=$PRINTCOM
	done
	
	echo '1' > $StudyFolder/$SubjectId/genericfmri.done
fi

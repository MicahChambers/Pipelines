#!/bin/bash

###############################################################################
# Readout Distortion Correction:
###############################################################################

# Averaging and readout distortion correction methods: 
# "NONE" = average any repeats with no readout correction 
# "FIELDMAP" = average any repeats and use field map for readout correction 
# "TOPUP" = use spin echo field map
AvgrdcSTRING="FIELDMAP" 
  
# Using Regular Gradient Echo Field Maps (same as for fMRIVolume pipeline)
# 2.46ms for 3T
# 1.02ms for 7T
# set to NONE if not using
TE="2.46" 
###############################################################################
#Templates
###############################################################################
T1wTemplate="${HCPPIPEDIR_Templates}/MNI152_T1_0.7mm.nii.gz" 
T1wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T1_0.7mm_brain.nii.gz" 
T1wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz" 
T2wTemplate="${HCPPIPEDIR_Templates}/MNI152_T2_0.7mm.nii.gz" 
T2wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T2_0.7mm_brain.nii.gz" 
T2wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz" 
TemplateMask="${HCPPIPEDIR_Templates}/MNI152_T1_0.7mm_brain_mask.nii.gz" 
Template2mmMask="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz" 

##############################################################################
# Structural Scan Settings (set all to NONE if not doing readout distortion correction)
###############################################################################

# DICOM field (0019,1018) in s 
# "NONE" if not used
T1wSampleSpacing="0.0000074" 

# DICOM field (0019,1018) in s 
# "NONE" if not used
T2wSampleSpacing="0.0000021" 

# z appears to be best or 
# "NONE" if not used
T1UnwarpDir="z" 

###############################################################################
#Other Config Settings
###############################################################################

# BrainSize in mm, 150 for humans
BrainSize="150" 
FNIRTConfig="${HCPPIPEDIR_Config}/T1_2_MNI152_2mm.cnf" #FNIRT 2mm T1w Config

# Location of Coeffs file or "NONE" to skip
#GradientDistortionCoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" 
GradientDistortionCoeffs="NONE" # Set to NONE to skip gradient distortion correction

##############################################################################
# Diffusion Weighted Imaging Settings
##############################################################################

# Echo Spacing or Dwelltime of dMRI image, set to NONE if not used.
# Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples):
# DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode
# DICOM field (0051,100b) AcquisitionMatrixText first value (# of phase encoding # samples)
# On Siemens, iPAT/GRAPPA factors have already been accounted for.
EchoSpacing=0.78 

# 1 for Left-Right Phase Encoding, 
# 2 for Anterior-Posterior
PEdir=1 

# Config Settings
# Gdcoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" 
# Coefficients that describe spatial variations of the scanner gradients. 
# Use NONE if not available.
Gdcoeffs="NONE" 

#################################################################
# Post Freesurfer
#################################################################

## Paths
SurfaceAtlasDIR="${HCPPIPEDIR_Templates}/standard_mesh_atlases"
GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/91282_Greyordinates"
ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"

## Configururation
# Usually 2mm, if multiple delimit with @, must already exist in templates dir
GrayordinatesResolutions="2" 

#Usually 164k vertices
HighResMesh="164" 

#Usually 32k vertices, if multiple delimit with @, must already exist in templates dir
LowResMeshes="32" 

#MSMSulc is recommended, if binary is not available use FS (FreeSurfer)
#RegName="MSMSulc" 
RegName="FS" 

####################################################################
# fMRI Tasks
####################################################################

# Echo Spacing or Dwelltime of fMRI image, set to NONE if not used. 
# Dwelltime = # 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples)
# DICOM field # (0019,1028) = BandwidthPerPixelPhaseEncode
# DICOM field (0051,100b) = AcquisitionMatrixText first value (# of phase encoding samples)
# On Siemens iPAT/GRAPPA factors have already been accounted for.
FMRIDwellTime="0.00058" 
FMRIPhaseEncodinglist="x x-" #x for RL, x- for LR, y for PA, y- for AP
FMRIUnwarpDir=`echo $FMRIPhaseEncodinglist | cut -d " " -f $i`

# FIELDMAP or TOPUP, distortion correction is required for accurate processing
FMRIDistortionCorrection="TOPUP" 

# Target final resolution of fMRI data. 
# 2mm is recommended for 3T HCP data,
# 1.6mm for 7T HCP data (i.e. should match acquired resolution).
# Use 2.0 or 1.0 to avoid standard FSL templates
FinalFMRIResolution="2" 

# Gradient distortion correction coefficents, set to NONE to turn off
#GradientDistortionCoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" 
GradientDistortionCoeffs="NONE" # SEt to NONE to skip gradient distortion correction

TopUpConfig="${HCPPIPEDIR_Config}/b02b0.cnf" #Topup config if using TOPUP, set to NONE if using regular FIELDMAP


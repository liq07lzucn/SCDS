# bash scripts for running SCDS studies

###################   parmaters setting     #################################
patDir=Pt27;  ## patient number: 10146002


echo "Setting parameters..."

## default data storgage settings
binaryFolder=/home/xiaoxiao/work/bin/SCDS/bin
scriptsFolder=/home/xiaoxiao/work/src/SCDS/scripts/SCDS-cbct/diaphragmSCDS

dataFolder=/media/Xiaoxiao_Backup/proj/SCDS/MSKCC_DATA/$patDir

cbctFolder=$dataFolder/cbct
rcctFolder=$dataFolder/rcct

# output dirs
cbctImageFolder=$dataFolder/cbct/image/original
rcctImageFolder=$dataFolder/rcct/image/original
rcctResampledImageFolder=$dataFolder/rcct/image/original
shapeFolder=$rcctFolder/shape
statsFolder=$rcctFolder/stats
resultsFolder=$dataFolder/results
scdsPredictionFolder=$dataFolder/results/SCDS_predict
scdsWarpFolder=$dataFolder/results/SCDS_warp

mkdir -p $cbctImageFolder
mkdir -p $rcctImageFolder
mkdir -p $shapeFolder
mkdir -p $statsFolder
mkdir -p $resultsFolder
mkdir -p $scdsPredictionFolder
mkdir -p $scdsWarpFolder
mkdir -p $rcctResampledImageFolder





# Converting CBCT Dicom image series *.dcm to Metadata format *.mhd
echo "Converting CBCT Dicom image series *.dcm to Metadata format *.mhd ..."
for i in 05 15 25 35 45 55 65 75 85 95;
  do $binaryFolder/DICOMSeriesTo3DImage $cbctFolder/CBCT_A/ampl_$i  $cbctImageFolder/phase$i\.mhd ; done


# Converting RCCT Dicom image series *.dcm to Metadata format *.mhd
echo "Converting RCCT Dicom image series *.dcm to Metadata format *.mhd ..."
for i in 05 15 25 35 45 55 65 75 85 95;
  do $binaryFolder/DICOMSeriesTo3DImage $rcctFolder/RCCT1_A/RCCT1_APR$i  $rcctImageFolder/cinePhase$i\.mhd ; done

########################[Optional]
# align RCCT images using ImReg
# Obtaining shifting paramters from ImReg and apply to all phase_X (X != reference phase)  images
# shift : [0.0 0.0 -8.5] cm  ----  RCCT phase 05 to phase 55
for n in 05 15 25 35 45  65 75 85 95
do $binaryFolder/TranslateImage $rcctFolder/image/original/cinePhase$n\.mhd  $rcctFolder/image/align/cinePhase$n\.mhd 0 0 8.5 -1024
done


# use the original phase 55 rcct in align folder 
ln  $rcctFolder/image/original/cinePhase55.mhd $rcctFolder/image/align/cinePhase55.mhd
ln  $rcctFolder/image/original/cinePhase55.raw $rcctFolder/image/align/cinePhase55.raw

#Resampling  RCCT to have the same spacing as CBCT
#spacing=(0.908394 0.908394 1.99496)  # CBCT's image sapcing for resampling purpose
#for i in 0 1 2 3 4 5 6 7 8 9 ; do $binaryFolder/ResamplingImageBySpacing  3 $rcctImageFolder/cinePhase$i.mhd   $rcctResampledImageFolder/cinePhase$i.mhd ${spacing[0]} ${spacing[1]} ${spacing[2]}; done

########################[Optional] end
#2. Find out intersection using
$scriptsFolder/intersectionRegionExtract_RCCT_CBCT.m





##############################   Training atlas  ################################################
$scriptsFolder/fWarpRCCT.sh




############################   Predict CBCT deformations (DVFs) ##################################
$scriptsFolder/run.......m


# apply the predicted deformation
mkdir  $resultsFolder/Diaphgram_predict/deformedImage
cd $resultsFolder/Diaphgram_predict/deformedImage

for n in 05 15 25 35 45  65 75 85 95
do
	$binaryFolder/txApply -b -i $cbctFolder/image/inter/phase$n.mhd -h $resultsFolder/Diaphgram_predict/Hfield/pred-hfield-phase$n.mhd  -o deformedPhase$n
done


# for comparison purpose: get the Euclidean mean
$binaryFolder/AtlasWerks --outputImageFilenamePrefix=averageImage_  --scaleLevel=1 --numberOfIterations=0   *.mhd




qsub $scriptsFolder/cfWarp.bash





###############################        evaluation     ###########################################

## segment tumor using LSTK

$binaryFolder/IntensityWindowFilter  /media/Xiaoxiao_Backup/proj/SCDS/MSKCC_DATA/Pt06/results/Diaphgram_predict/deformedImage/averageImage_initial.mhd  ~/work/tmp/testInput.mhd  0 1 -1024 2542

 ~/work/bin/ITK/Release/bin/LesionSegmentation  -InputImage ~/work/tmp/testInput.mhd -OutputImage ~/work/tmp/tumorSegPt05AverageCBCT.mha -Seeds 3 326.2 231.9 172.6 -MaximumRadius 20 -OutputROI ~/work/tmp/tumorSegPt05ROI.mhd -OutputMesh ~/work/tmp/tumorSegPt05_segMesh.stl -Visualize 1 -Screenshot ~/work/tmp/tumorSegPt05




evaluateROI.bash

evaluteLungContour.bash ### not done yet






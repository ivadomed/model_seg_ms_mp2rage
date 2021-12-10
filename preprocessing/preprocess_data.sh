#!/bin/bash
#
# Preprocess data.
#
# Dependencies (versions):
# - SCT (5.4.0)
#
# Usage:
#   ./preprocess_data.sh <SUBJECT>
#
#
# Manual segmentations or labels should be located under:
# PATH_DATA/derivatives/labels/SUBJECT/<CONTRAST>/

# The following global variables are retrieved from the caller sct_run_batch
# but could be overwritten by uncommenting the lines below:
# PATH_DATA_PROCESSED="~/data_processed"
# PATH_RESULTS="~/results"
# PATH_LOG="~/log"
# PATH_QC="~/qc"

# Uncomment for full verbose
set -x

# Immediately exit if error
set -e -o pipefail

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT


# CONVENIENCE FUNCTIONS
# ======================================================================================================================

segment_if_does_not_exist() {
  ###
  #  This function checks if a manual spinal cord segmentation file already exists, then:
  #    - If it does, copy it locally.
  #    - If it doesn't, perform automatic spinal cord segmentation.
  #  This allows you to add manual segmentations on a subject-by-subject basis without disrupting the pipeline.
  ###
  local file="$1"
  local contrast="$2"
  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  FILESEGMANUAL="${PATH_DATA}/derivatives/labels/${SUBJECT}/anat/${FILESEG}-manual.nii.gz"
  echo
  echo "Looking for manual segmentation: $FILESEGMANUAL"
  if [[ -e $FILESEGMANUAL ]]; then
    echo "Found! Using manual segmentation."
    rsync -avzh $FILESEGMANUAL ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found. Proceeding with automatic segmentation."
    # Segment spinal cord
    sct_deepseg_sc -i ${file}.nii.gz -c $contrast -brain 1 -centerline cnn -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}

# Retrieve input params and other params
SUBJECT=$1

# get starting time:
start=`date +%s`


# SCRIPT STARTS HERE
# ==============================================================================
# Display useful info for the log, such as SCT version, RAM and CPU cores available
sct_check_dependencies -short

# Go to folder where data will be copied and processed
cd $PATH_DATA_PROCESSED

# Copy BIDS-required files to processed data folder (e.g. list of participants)
if [[ ! -f "participants.tsv" ]]; then
  rsync -avzh $PATH_DATA/participants.tsv .
fi
if [[ ! -f "participants.json" ]]; then
  rsync -avzh $PATH_DATA/participants.json .
fi
if [[ ! -f "dataset_description.json" ]]; then
  rsync -avzh $PATH_DATA/dataset_description.json .
fi
if [[ ! -f "README" ]]; then
  rsync -avzh $PATH_DATA/README .
fi

# Copy source images
rsync -avzh $PATH_DATA/$SUBJECT .

# Copy segmentation ground truths (GT)
mkdir -p derivatives/labels
rsync -avzh $PATH_DATA/derivatives/labels/$SUBJECT derivatives/labels/.

# Go to subject folder for source images
cd ${SUBJECT}/anat

# Define variables
file="${SUBJECT}_UNIT1"

# Make sure the image metadata is a valid JSON object
if [[ ! -s ${file}.json ]]; then
  echo "{}" >> ${file}.json
fi

# Spinal cord segmentation. Here, we are dealing with MP2RAGE contrast. We 
# specify t1 contrast because the cord is bright and the CSF is dark (like on 
# the traditional MPRAGE T1w data).
segment_if_does_not_exist ${file} t1
file_seg="${FILESEG}"

# Dilate spinal cord mask
sct_maths -i ${file_seg}.nii.gz -dilate 5 -shape ball -o ${file_seg}_dilate.nii.gz

# Use dilated mask to crop the original image and manual MS segmentations
sct_crop_image -i ${file}.nii.gz -m ${file_seg}_dilate.nii.gz -o ${file}_crop.nii.gz

# Go to subject folder for segmentation GTs
cd $PATH_DATA_PROCESSED/derivatives/labels/$SUBJECT/anat

# Define variables
file_gt1="${SUBJECT}_UNIT1_lesion-manual"
file_gt2="${SUBJECT}_UNIT1_lesion-manual2"
file_gtc="${SUBJECT}_UNIT1_lesion-manual-majvote"
file_soft="${SUBJECT}_UNIT1_lesion-manual-soft"
# 'c' stands for the consensus GT

# Redefine variable for final SC segmentation mask as path changed
file_seg_dil=${PATH_DATA_PROCESSED}/${SUBJECT}/anat/${file_seg}_dilate

# Make sure the first rater metadata is a valid JSON object
if [[ ! -s ${file_gt1}.json ]]; then
  echo "{}" >> ${file_gt1}.json
fi

# Aggregate multiple raters if second rater is present
if [[ -f ${file_gt2}.nii.gz ]]; then
  # Make sure the second rater metadata is a valid JSON object
  if [[ ! -s ${file_gt2}.json ]]; then
    echo "{}" >> ${file_gt2}.json
  fi
  # Create consensus ground truth by majority vote
  sct_maths -i ${file_gt1}.nii.gz -add ${file_gt2}.nii.gz -o lesion_sum.nii.gz
  sct_maths -i lesion_sum.nii.gz -sub 1 -o lesion_sum_minusone.nii.gz
  # binarize: everything that is 0.5 and below 0.5 becomes 0.
  sct_maths -i lesion_sum_minusone.nii.gz -thr 0.5 -o ${file_gtc}.nii.gz

  # Create soft ground truth by averaging all raters
  sct_maths -i lesion_sum.nii.gz -div 2 -o ${file_soft}.nii.gz

  # Crop the manual segs
  sct_crop_image -i ${file_gt2}.nii.gz -m ${file_seg_dil}.nii.gz -o ${file_gt2}_crop.nii.gz
  sct_crop_image -i ${file_gtc}.nii.gz -m ${file_seg_dil}.nii.gz -o ${file_gtc}_crop.nii.gz
  sct_crop_image -i ${file_soft}.nii.gz -m ${file_seg_dil}.nii.gz -o ${file_soft}_crop.nii.gz
fi

# Crop the manual seg
sct_crop_image -i ${file_gt1}.nii.gz -m ${file_seg_dil}.nii.gz -o ${file_gt1}_crop.nii.gz

# Go back to the root output path
cd $PATH_OUTPUT

# Create and populate clean data processed folder for training
PATH_DATA_PROCESSED_CLEAN="${PATH_DATA_PROCESSED}_clean"
mkdir -p $PATH_DATA_PROCESSED_CLEAN $PATH_DATA_PROCESSED_CLEAN/${SUBJECT} $PATH_DATA_PROCESSED_CLEAN/${SUBJECT}/anat
rsync -avzh $PATH_DATA_PROCESSED/dataset_description.json $PATH_DATA_PROCESSED_CLEAN/
rsync -avzh $PATH_DATA_PROCESSED/participants.* $PATH_DATA_PROCESSED_CLEAN/
rsync -avzh $PATH_DATA_PROCESSED/README $PATH_DATA_PROCESSED_CLEAN/
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}_crop.nii.gz $PATH_DATA_PROCESSED_CLEAN/${SUBJECT}/anat/${file}.nii.gz
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}.json $PATH_DATA_PROCESSED_CLEAN/${SUBJECT}/anat/${file}.json
mkdir -p $PATH_DATA_PROCESSED_CLEAN/derivatives $PATH_DATA_PROCESSED_CLEAN/derivatives/labels $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT} $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT}/anat/
rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_gt1}_crop.nii.gz $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT}/anat/${file_gt1}.nii.gz
rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_gt1}.json $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT}/anat/${file_gt1}.json
# If second rater is present, copy the other files
if [[ -f ${PATH_DATA_PROCESSED}/derivatives/labels/${SUBJECT}/anat/${file_gt2}.nii.gz ]]; then
  # Copy the second rater GT and aggregated GTs if second rater is present
  rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_gt2}_crop.nii.gz $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT}/anat/${file_gt2}.nii.gz
  rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_gt2}.json $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT}/anat/${file_gt2}.json
  rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_gtc}_crop.nii.gz $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT}/anat/${file_gtc}.nii.gz
  rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_soft}_crop.nii.gz $PATH_DATA_PROCESSED_CLEAN/derivatives/labels/${SUBJECT}/anat/${file_soft}.nii.gz
fi

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
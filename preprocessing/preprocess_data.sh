#!/bin/bash
#
# Preprocess data.
#
# Dependencies:
# - FSL <TODO: VERSION>
# - SCT <TODO: VERSION>
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

# Spinal cord segmentation. Here, we are dealing with MP2RAGE contrast. We 
# specify t1 contrast because the cord is bright and the CSF is dark (like on 
# the traditional MPRAGE T1w data).
segment_if_does_not_exist ${file} t1
file_seg="${FILESEG}"

# Dilate spinal cord mask
sct_maths -i ${file_seg}.nii.gz -dilate 5 -shape ball -o ${file_seg}_dilate.nii.gz

# Use dilated mask to crop the orginal image and manual MS segmentations
sct_crop_image -i ${file}.nii.gz -m ${file_seg}_dilate.nii.gz -o ${file}_crop.nii.gz

# Go to subject folder for segmentation GTs
cd $PATH_DATA_PROCESSED/derivatives/labels/$SUBJECT/anat

# Define variables
# TODO: Check if multiple rater filenames are correct or not
file_gt1="${SUBJECT}_UNIT1_lesion-manual-rater1"
file_gt2="${SUBJECT}_UNIT1_lesion-manual-rater2"
file_gtc="${SUBJECT}_UNIT1_lesion-manual-majvote"
# 'c' stands for the consensus GT

# Redefine variable for final SC segmentation mask as path changed
file_seg_dil=${PATH_DATA_PROCESSED}/${SUBJECT}/anat/${file_seg}_dilate

# Aggregate multiple raters with majority voting
sct_maths -i ${file_gt1}.nii.gz -add ${file_gt2}.nii.gz -o ${file_gtc}.nii.gz
sct_maths -i ${file_gtc}.nii.gz -sub 1 -o ${file_gtc}.nii.gz
sct_maths -i ${file_gtc}.nii.gz -thr 1 -o ${file_gtc}.nii.gz

# Crop the manual segs
sct_crop_image -i ${file_gt1}.nii.gz -m ${file_seg_dil}.nii.gz -o ${file_gt1}_crop.nii.gz
sct_crop_image -i ${file_gt2}.nii.gz -m ${file_seg_dil}.nii.gz -o ${file_gt2}_crop.nii.gz
sct_crop_image -i ${file_gtc}.nii.gz -m ${file_seg_dil}.nii.gz -o ${file_gtc}_crop.nii.gz

# TODO: Create 'clean' output folder

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
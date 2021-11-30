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

# Copy segmentation GTs
mkdir -p derivatives/labels
rsync -avzh $PATH_DATA/derivatives/labels/$SUBJECT derivatives/labels/.

# (1) Go to subject folder for source images
cd ${SUBJECT}

# TODO: re-think how file variable is defined-- not clean to have folders in there
file_onlyfile="${SUBJECT}_UNIT1"
file="anat/${SUBJECT}_UNIT1"

# Spinal cord extraction
sct_deepseg_sc -i ${file}.nii.gz -c t1 -o ${file_onlyfile}_seg.nii.gz

# Dilate spinal cord mask
sct_maths -i ${file_onlyfile}_seg.nii.gz -dilate 5 -shape ball -o ${file_onlyfile}_seg_dilate.nii.gz

# Compute the bounding box coordinates of SC mask for cropping the VOI
# NOTE: `fslstats -w returns the smallest ROI <xmin> <xsize> <ymin> <ysize> <zmin> <zsize> <tmin> <tsize> containing nonzero voxels
bbox_coords=$(fslstats "${file_onlyfile}"_seg_dilate.nii.gz -w)

# Apply the SC mask to the final forms of both sessions
fslmaths ${file}.nii.gz -mas ${file_onlyfile}_seg_dilate.nii.gz ${file_onlyfile}_masked.nii.gz

# Crop the VOI based on SC mask to minimize the input image size
fslroi ${file_onlyfile}_masked.nii.gz ${file_onlyfile}_masked.nii.gz $bbox_coords

# (2) Go to subject folder for segmentation GTs
cd $PATH_DATA_PROCESSED/derivatives/labels/$SUBJECT

file_gt_onlyfile="${SUBJECT}_UNIT1_lesion-manual"
file_gt="anat/${SUBJECT}_UNIT1_lesion-manual"

# Apply the SC mask to the final forms of all segmentation GTs
fslmaths ${file_gt}.nii.gz -mas $PATH_DATA_PROCESSED/$SUBJECT/${file_onlyfile}_seg_dilate.nii.gz ${file_gt_onlyfile}_masked.nii.gz

# Crop the VOI based on SC mask to minimize the GT image size
fslroi ${file_gt_onlyfile}_masked.nii.gz ${file_gt_onlyfile}_masked.nii.gz $bbox_coords

# Go back to parent folder (i.e. get ready for next subject call!)
cd $PATH_DATA_PROCESSED

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
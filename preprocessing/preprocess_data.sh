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
# <SUBJECT> is the name of the subject in BIDS convention (sub-XXX)
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
  local centerline_method="$3"
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
    # Segment spinal cord based on the specified centerline method
    if [[ $centerline_method == "cnn" ]]; then
      sct_deepseg_sc -i ${file}.nii.gz -c $contrast -brain 1 -centerline cnn -qc ${PATH_QC} -qc-subject ${SUBJECT}
    elif [[ $centerline_method == "svm" ]]; then
      sct_deepseg_sc -i ${file}.nii.gz -c $contrast -centerline svm -qc ${PATH_QC} -qc-subject ${SUBJECT}
    else
      echo "Centerline extraction method = ${centerline_method} is not recognized!"
      exit 1
    fi
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
file_gt1="${SUBJECT}_UNIT1_lesion-manualNeuroPoly"

# Make sure the image metadata is a valid JSON object
if [[ ! -s ${file}.json ]]; then
  echo "{}" >> ${file}.json
fi

# Spinal cord segmentation. Here, we are dealing with MP2RAGE contrast. We 
# specify t1 contrast because the cord is bright and the CSF is dark (like on 
# the traditional MPRAGE T1w data).
segment_if_does_not_exist ${file} t1 svm
file_seg="${FILESEG}"

# Use mask to crop the original image
DILATE="32x3x32"
sct_crop_image -i ${file}.nii.gz -m ${file_seg}.nii.gz -dilate ${DILATE} -o ${file}_crop.nii.gz

# Crop the manual MS lesion segmentation
sct_crop_image -i $PATH_DATA_PROCESSED/derivatives/labels/$SUBJECT/anat/${file_gt1}.nii.gz -m ${file_seg}.nii.gz -dilate ${DILATE} -o $PATH_DATA_PROCESSED/derivatives/labels/$SUBJECT/anat/${file_gt1}_crop.nii.gz

# Make sure a JSON file is present, if not create an empty one
if [[ ! -s $PATH_DATA_PROCESSED/derivatives/labels/$SUBJECT/anat/${file_gt1}.json ]]; then
  echo "{}" >> $PATH_DATA_PROCESSED/derivatives/labels/$SUBJECT/anat/${file_gt1}.json
fi

# Create clean data processed folders for two tasks: spinal cord (SC) segmentation and lesion segmentation
PATH_DATA_PROCESSED_SCSEG="${PATH_DATA_PROCESSED}_scseg"
PATH_DATA_PROCESSED_LESIONSEG="${PATH_DATA_PROCESSED}_lesionseg"

# Copy over required BIDS files to both folders
mkdir -p $PATH_DATA_PROCESSED_SCSEG $PATH_DATA_PROCESSED_SCSEG/${SUBJECT} $PATH_DATA_PROCESSED_SCSEG/${SUBJECT}/anat
mkdir -p $PATH_DATA_PROCESSED_LESIONSEG $PATH_DATA_PROCESSED_LESIONSEG/${SUBJECT} $PATH_DATA_PROCESSED_LESIONSEG/${SUBJECT}/anat
rsync -avzh $PATH_DATA_PROCESSED/dataset_description.json $PATH_DATA_PROCESSED_SCSEG/
rsync -avzh $PATH_DATA_PROCESSED/dataset_description.json $PATH_DATA_PROCESSED_LESIONSEG/
rsync -avzh $PATH_DATA_PROCESSED/participants.* $PATH_DATA_PROCESSED_SCSEG/
rsync -avzh $PATH_DATA_PROCESSED/participants.* $PATH_DATA_PROCESSED_LESIONSEG/
rsync -avzh $PATH_DATA_PROCESSED/README $PATH_DATA_PROCESSED_SCSEG/
rsync -avzh $PATH_DATA_PROCESSED/README $PATH_DATA_PROCESSED_LESIONSEG/

# For SC segmentation task, copy raw subject images as inputs and SC masks as targets
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}.nii.gz $PATH_DATA_PROCESSED_SCSEG/${SUBJECT}/anat/${file}.nii.gz
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}.json $PATH_DATA_PROCESSED_SCSEG/${SUBJECT}/anat/${file}.json
mkdir -p $PATH_DATA_PROCESSED_SCSEG/derivatives $PATH_DATA_PROCESSED_SCSEG/derivatives/labels $PATH_DATA_PROCESSED_SCSEG/derivatives/labels/${SUBJECT} $PATH_DATA_PROCESSED_SCSEG/derivatives/labels/${SUBJECT}/anat/
file_seg_gt="${file}_seg-manual"
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}_seg.nii.gz $PATH_DATA_PROCESSED_SCSEG/derivatives/labels/${SUBJECT}/anat/${file_seg_gt}.nii.gz
# Copy the relevant JSON: use auto-generated JSON for manually corrected and create new JSON for sct_deepseg_sc generated SC segs
if [[ -f $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_seg_gt}.json ]]; then
  rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_seg_gt}.json $PATH_DATA_PROCESSED_SCSEG/derivatives/labels/${SUBJECT}/anat/${file_seg_gt}.json
else
  # Get current datetime and set tabs to 4 spaces
  datetime=$(date +'%Y-%m-%d %H:%M:%S')
  echo -e "{\n    \"Author\": \"Generated with sct_deepseg_sc\",\n    \"Date\": \"${datetime}\"\n}" >> $PATH_DATA_PROCESSED_SCSEG/derivatives/labels/${SUBJECT}/anat/${file_seg_gt}.json
fi

# For lesion segmentation task, copy SC crops as inputs and lesion annotations as targets
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}_crop.nii.gz $PATH_DATA_PROCESSED_LESIONSEG/${SUBJECT}/anat/${file}.nii.gz
rsync -avzh $PATH_DATA_PROCESSED/${SUBJECT}/anat/${file}.json $PATH_DATA_PROCESSED_LESIONSEG/${SUBJECT}/anat/${file}.json
mkdir -p $PATH_DATA_PROCESSED_LESIONSEG/derivatives $PATH_DATA_PROCESSED_LESIONSEG/derivatives/labels $PATH_DATA_PROCESSED_LESIONSEG/derivatives/labels/${SUBJECT} $PATH_DATA_PROCESSED_LESIONSEG/derivatives/labels/${SUBJECT}/anat/
rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_gt1}_crop.nii.gz $PATH_DATA_PROCESSED_LESIONSEG/derivatives/labels/${SUBJECT}/anat/${file_gt1}.nii.gz
rsync -avzh $PATH_DATA_PROCESSED/derivatives/labels/${SUBJECT}/anat/${file_gt1}.json $PATH_DATA_PROCESSED_LESIONSEG/derivatives/labels/${SUBJECT}/anat/${file_gt1}.json

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"

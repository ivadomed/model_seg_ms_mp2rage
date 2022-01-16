"""
Quality control for preprocessing step.
See `preprocess_data.sh` for the preprocessing pipeline.
"""

import argparse
import os
from tqdm import tqdm
from collections import Counter

import pandas as pd
import nibabel as nib
import numpy as np

# Argument parsing
parser = argparse.ArgumentParser(description='Quality control for preprocessing.')
parser.add_argument('-s', '--sct_output_path', type=str, required=True,
                    help='Path to the folder generated by `sct_run_batch`. This folder should contain `data_processed` folder.')
args = parser.parse_args()

# Quick checking of arguments
if not os.path.exists(args.sct_output_path):
    raise NotADirectoryError('%s could NOT be found!' % args.sct_output_path)
else:
    if not os.path.exists(os.path.join(args.sct_output_path, 'data_processed')):
        raise NotADirectoryError('`data_processed` could NOT be found within %s' % args.sct_output_path)

# Get all subjects
subjects_df = pd.read_csv(os.path.join(args.sct_output_path, 'data_processed', 'participants.tsv'), sep='\t')
subjects = subjects_df['participant_id'].values.tolist()

# Log resolutions and sizes for data exploration
resolutions, sizes, crop_sizes = [], [], []

# Log problematic subjects for QC
failed_crop_subjects, shape_mismatch_subjects, left_out_lesion_subjects = [], [], []

# Perform QC on each subject
for subject in tqdm(subjects, desc='Iterating over Subjects'):
    # Get paths
    subject_images_path = os.path.join(args.sct_output_path, 'data_processed', subject, 'anat')
    subject_labels_path = os.path.join(args.sct_output_path, 'data_processed', 'derivatives', 'labels', subject, 'anat')

    # Read original and cropped subject image (i.e. 3D volume) to be used for training
    img_path = os.path.join(subject_images_path, '%s_UNIT1.nii.gz' % subject)
    img_crop_fpath = os.path.join(subject_images_path, '%s_UNIT1_crop.nii.gz' % subject)
    if not os.path.exists(img_crop_fpath):
        failed_crop_subjects.append(subject)
        continue
    img = nib.load(img_path)
    img_crop = nib.load(img_crop_fpath)

    # Get and log size and resolution for each subject image
    size = img.get_fdata().shape
    crop_size = img_crop.get_fdata().shape
    resolution = tuple(img_crop.header['pixdim'].tolist()[1:4])
    resolution = tuple([np.round(r, 1) for r in list(resolution)])
    sizes.append(size)
    crop_sizes.append(crop_size)
    resolutions.append(resolution)

    # Read original and cropped subject ground-truths (GT)
    gt1_fpath = os.path.join(subject_labels_path, '%s_UNIT1_lesion-manual.nii.gz' % subject)
    gt1_crop_fpath = os.path.join(subject_labels_path, '%s_UNIT1_lesion-manual_crop.nii.gz' % subject)
    gt2_fpath = os.path.join(subject_labels_path, '%s_UNIT1_lesion-manual2.nii.gz' % subject)
    gt2_crop_fpath = os.path.join(subject_labels_path, '%s_UNIT1_lesion-manual2_crop.nii.gz' % subject)

    gt1 = nib.load(gt1_fpath)
    gt1_crop = nib.load(gt1_crop_fpath)
    gt2 = nib.load(gt2_fpath)
    gt2_crop = nib.load(gt2_crop_fpath)

    # Basic shape checks
    if not img_crop.shape == gt1_crop.shape == gt2_crop.shape:
        shape_mismatch_subjects.append(subject)
        continue

    # Check if the dilated SC mask leaves out any lesions from GTs (from each rater)
    if not (np.allclose(np.sum(gt1.get_fdata()), np.sum(gt1_crop.get_fdata())) and
            np.allclose(np.sum(gt2.get_fdata()), np.sum(gt2_crop.get_fdata()))):
        left_out_lesion_subjects.append(subject)

print('RESOLUTIONS: ', Counter(resolutions))
print('SIZES: ', Counter(sizes))
print('CROP SIZES: ', Counter(crop_sizes))

print('Could not find cropped image for the following subjects: ', failed_crop_subjects)
print('Found shape mismatch in images and GTs for the following subjects: ', shape_mismatch_subjects)
print('ALERT: Lesion(s) from raters cropped during preprocessing for the following subjects: ', left_out_lesion_subjects)
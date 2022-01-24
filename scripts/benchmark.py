import os
import shutil
import json
from subprocess import call, DEVNULL, STDOUT
import nibabel as nib
from ivadomed.losses import DiceLoss

# Initialize Dice loss for running evaluation
dice_loss = DiceLoss(smooth=1.0)

# Generate output paths
output_path = 'benchmark_output'
sc_output_path = os.path.join(output_path, 'sc')
lesion_output_path = os.path.join(output_path, 'lesion')
print('The prediction images used in benchmarking can be found in `%s` and `%s`!' % (sc_output_path, lesion_output_path))
if not os.path.exists(output_path):
    os.makedirs(output_path)
    os.makedirs(sc_output_path)
    os.makedirs(lesion_output_path)

# Set paths for data, config, and model for (i) SC segmentation and (ii) lesion segmentation
sc_data_path = '../basel-mp2rage-preprocessed/data_processed_scseg'
lesion_data_path = '../basel-mp2rage-preprocessed/data_processed_lesionseg'
sc_config_path = '../config/seg_sc.json'
lesion_config_path = '../config/test_on_rater1.json'
# NOTE: Used `test_on_rater1.json` instead of `seg_lesion.json` to provide one target suffix
sc_model_path = '../seg_sc_output'
lesion_model_path = '../seg_lesion_output'

# Basic checks to ensure paths exist
paths = [sc_data_path, lesion_data_path, sc_config_path, lesion_config_path, sc_model_path, lesion_model_path]
assert all([os.path.exists(path) for path in paths])

# Get prediction paths for both models
sc_predictions_path = os.path.join(sc_model_path, 'pred_masks')
lesion_predictions_path = os.path.join(lesion_model_path, 'pred_masks')

# Clear all predictions from before if applicable
if os.path.exists(sc_predictions_path):
    print('Removing previous predictions from `pred_masks` for SC segmentation!')
    for f in os.listdir(sc_predictions_path):
        os.remove(os.path.join(sc_predictions_path, f))
if os.path.exists(lesion_predictions_path):
    print('Removing previous predictions from `pred_masks` for lesion segmentation!')
    for f in os.listdir(lesion_predictions_path):
        os.remove(os.path.join(lesion_predictions_path, f))

# Run testing on both models to generate prediction files
call(
    ['ivadomed', '--test', '-c', sc_config_path, '-po', sc_model_path, '-pd', sc_data_path],
    stdout=DEVNULL,
    stderr=STDOUT
)
call(
    ['ivadomed', '--test', '-c', lesion_config_path, '-po', lesion_model_path, '-pd', lesion_data_path],
    stdout=DEVNULL,
    stderr=STDOUT
)

# Iterate through SC predictions
print('\nSC Segmentation Benchmarking')
print('-------------------------------------------------')
for f in os.listdir(sc_predictions_path):
    # Skip painted prediction images
    if f.endswith('_painted.nii.gz'):
        continue

    # Get subject, label and JSON path information for SC segmentation
    subject = f.split('_')[0]
    label_path = os.path.join(sc_data_path, 'derivatives', 'labels', subject, 'anat')
    json_path = os.path.join(label_path, '%s_UNIT1_seg-manual.json' % subject)

    # Skip subject if non-corrected SC annotation (i.e. generated with sct_deepseg_sc)
    with open(json_path) as f_:
        author = json.load(f_)['Author']
        if author == "Generated with sct_deepseg_sc":
            print('Skipping subject=%s due to non-corrected SC segmentation!' % subject)
            continue

    # Get image and GT path for SC segmentation
    img_path = os.path.join(sc_data_path, subject, 'anat', '%s_UNIT1.nii.gz' % subject)
    gt_path = os.path.join(label_path, '%s_UNIT1_seg-manual.nii.gz' % subject)

    # Copy image, GT, and model predictions to the relevant benchmark output path
    shutil.copy(img_path, os.path.join(sc_output_path, '%s_UNIT1.nii.gz' % subject))
    shutil.copy(gt_path, os.path.join(sc_output_path, '%s_UNIT1_seg-manual.nii.gz' % subject))
    shutil.copy(os.path.join(sc_predictions_path, f), os.path.join(sc_output_path, f))

    # Load GT and model prediction for SC segmentation as NumPy arrays
    gt = nib.load(gt_path).get_fdata()
    model_prediction = nib.load(os.path.join(sc_predictions_path, f)).get_fdata()[:, :, :, 0]

    # Use sct_deepseg_sc to generate an alternative SC segmentation to compare the model to
    sct_prediction_path = os.path.join(sc_output_path, '%s_sct_deepseg_sc.nii.gz' % subject)
    call(
        ['sct_deepseg_sc', '-i', img_path, '-c', 't1', '-centerline', 'svm', '-o', sct_prediction_path],
        stdout=DEVNULL,
        stderr=STDOUT
    )
    sct_prediction = nib.load(sct_prediction_path).get_fdata()

    # Basic shape check for the predictions
    assert gt.shape == model_prediction.shape == sct_prediction.shape

    # Print basic evaluation scores
    print('\tSubject: ', subject)
    print('\tSC Model Dice Score: ', round(dice_loss(model_prediction, gt), 4))
    print('\tSCT (sct_deepseg_sc) Dice Score: ', round(dice_loss(sct_prediction, gt), 4))
    print('\t-------------------------------')

# Iterate through lesion predictions
print('\nLesion Segmentation Benchmarking')
print('-------------------------------------------------')
for f in os.listdir(lesion_predictions_path):
    # Skip painted prediction images
    if f.endswith('_painted.nii.gz'):
        continue

    # Get subject, label and JSON path information for lesion segmentation
    subject = f.split('_')[0]
    label_path = os.path.join(lesion_data_path, 'derivatives', 'labels', subject, 'anat')

    # Get image and GT paths for lesion segmentation
    img_path = os.path.join(lesion_data_path, subject, 'anat', '%s_UNIT1.nii.gz' % subject)
    gt1_path = os.path.join(label_path, '%s_UNIT1_lesion-manual.nii.gz' % subject)
    gt2_path = os.path.join(label_path, '%s_UNIT1_lesion-manual2.nii.gz' % subject)

    # Copy image, GTs, and model predictions to the relevant benchmark output path
    shutil.copy(img_path, os.path.join(lesion_output_path, '%s_UNIT1.nii.gz' % subject))
    shutil.copy(gt1_path, os.path.join(lesion_output_path, '%s_UNIT1_lesion-manual.nii.gz' % subject))
    shutil.copy(gt2_path, os.path.join(lesion_output_path, '%s_UNIT1_lesion-manual2.nii.gz' % subject))
    shutil.copy(os.path.join(lesion_predictions_path, f), os.path.join(lesion_output_path, f))

    # Load GTs and model prediction for lesion segmentation as NumPy arrays
    gt1 = nib.load(gt1_path).get_fdata()
    gt2 = nib.load(gt2_path).get_fdata()
    model_prediction = nib.load(os.path.join(lesion_predictions_path, f)).get_fdata()[:, :, :, 0]

    # Use sct_deepseg_lesion to generate an alternative lesion segmentation to compare the model to
    sct_prediction_path = os.path.join(lesion_output_path, '%s_sct_deepseg_lesion.nii.gz' % subject)
    call(
        ['sct_deepseg_lesion', '-i', img_path, '-c', 't2', '-centerline', 'svm', '-ofolder', lesion_output_path],
        stdout=DEVNULL,
        stderr=STDOUT
    )
    os.rename(os.path.join(lesion_output_path, '%s_UNIT1_lesionseg.nii.gz' % subject), sct_prediction_path)
    sct_prediction = nib.load(sct_prediction_path).get_fdata()

    # Basic shape check for the predictions
    assert gt1.shape == gt2.shape == model_prediction.shape == sct_prediction.shape

    # Print basic evaluation scores
    print('\tSubject: ', subject)
    print('\tLesion Model Dice Score (Rater 1): ', round(dice_loss(model_prediction, gt1), 4))
    print('\tLesion Model Dice Score (Rater 2): ', round(dice_loss(model_prediction, gt2), 4))
    print('\tSCT (sct_deepseg_lesion) Dice Score (Rater 1): ', round(dice_loss(sct_prediction, gt1), 4))
    print('\tSCT (sct_deepseg_lesion) Dice Score (Rater 2): ', round(dice_loss(sct_prediction, gt2), 4))
    print('\t-------------------------------')

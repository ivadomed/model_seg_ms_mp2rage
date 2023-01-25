# model_seg_ms_mp2rage

Model repository for MS lesion segmentation on MP2RAGE data as discussed [here](https://github.com/ivadomed/ivadomed/issues/821).
This repository contains two models, one for spinal cord (SC) segmentation and one for MS lesion segmentation.

## Model overview 

![model_overview](https://github.com/ivadomed/model_seg_ms_mp2rage/releases/download/r20211223/model_overview.png)

## Dependencies

- [SCT](https://spinalcordtoolbox.com/) commit: 7fd2ea718751dd858840c3823c0830a910d9777c
- [ivadomed](https://ivadomed.org) commit: git-master-93ba03df76d229d8a190c694f757da6c00efa545

## Clone this repository

~~~
git clone https://github.com/ivadomed/model_seg_ms_mp2rage.git
~~~

## Get the data

- git@data.neuro.polymtl.ca:datasets/basel-mp2rage
- Commit: 93110d8ebb65398dcc6e4528bf548eb7828332f1

### Example calls to get the data

~~~
git clone git@data.neuro.polymtl.ca:datasets/basel-mp2rage
cd basel-mp2rage
git annex get .
cd ..
~~~
 
## Prepare the data

The data need to be preprocessed before training. The preprocessing command is:

~~~
sct_run_batch -script <PATH_TO_REPOSITORY>/preprocessing/preprocess_data.sh -path-data <PATH_TO_DATA>/basel-mp2rage/ -path-output basel-mp2rage-preprocessed -jobs <JOBS>
~~~

This command will create a `data_processed_scseg` folder for the SC segmentation task and a 
`data_processed_lesionseg` folder for the lesion segmentation task inside the `basel-mp2rage-preprocessed` 
you specified. Each of these two folders contain only the required files for their respective task.

After running the preprocessing, you can also run the quality-control (QC) script:
```
python preprocessing/qc_preprocess.py -s basel-mp2rage-preprocessed
```
which i) logs resolutions and sizes for each subject image (both raw and cropped) for data exploration, 
ii) performs basic shape checks for spinal cord (SC) cropped images and ground-truths (GTs), and 
most importantly iii) checks if the dilated SC mask leaves out any lesions from the GT of each rater.

## Training

Spinal cord segmentation training was carried out with
```
ivadomed --train -c config/seg_sc.json
```

Lesion segmentation training was carried out with
```
ivadomed --train -c config/seg_lesion.json
```

## Get trained models

```
cp -r ~/duke/temp/uzay/saved_models_basel/seg_sc_output .
cp -r ~/duke/temp/uzay/saved_models_basel/seg_lesion_output .
```

## Performance evaluation

To test a spinal cord segmentation model run
```
ivadomed --test -c config/seg_sc.json
```

To test a lesion segmentation model independently on the two rater's annotations
```
ivadomed --test -c config/test_on_rater1.json
ivadomed --test -c config/test_on_rater2.json
```

Visualize predictions
TODO: update with variable for path
```
SUBJECT=017
julien-macbook:~/temp/rosenberg_nvme $ fsleyes -S ~/data.neuro/basel-mp2rage/sub-P${SUBJECT}/anat/sub-P${SUBJECT}_UNIT1.nii.gz ~/data.neuro/basel-mp2rage/derivatives/labels/sub-P${SUBJECT}/anat/sub-P${SUBJECT}_UNIT1_lesion-manualNeuroPoly.nii.gz -cm green model_seg_lesion_mp2rage_20230124_204632/pred_masks/sub-P017_UNIT1_pred.nii.gz -cm red  
```

## Segment a dataset

To run inference with spinal cord segmentation model on a dataset run
```
ivadomed --segment -c config/seg_sc.json --path-data <PATH_DATA>
```

To run inference with lesion segmentation model on a dataset run
```
ivadomed --segment -c config/seg_lesion.json --path-data <PATH_DATA>
```

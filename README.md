# model_seg_ms_mp2rage

Model repository for MS lesion segmentation on MP2RAGE data as discussed in https://github.com/ivadomed/ivadomed/issues/821.

## Dependencies

- [SCT](https://spinalcordtoolbox.com/) commit: 7fd2ea718751dd858840c3823c0830a910d9777c
- [ivadomed](https://ivadomed.org) commit: XXX

## Clone this repository

~~~
git clone https://github.com/ivadomed/model_seg_ms_mp2rage.git
~~~

## Get the data

- data.neuro.polymtl.ca:basel-mp2rage
- Commit: 88c506eb9855d6a0cb29a2e95c3283b8fd0a8099
 
## Prepare the data

The data need to be preprocessed before training. The general syntax for preprocessing is:

~~~
sct_run_batch -script <PATH_TO_REPOSITORY>/model_seg_ms_mp2rage/preprocessing/preprocess_data.sh -path-data <PATH_TO_DATA>/basel-mp2rage/ -path-output <PATH_OUTPUT> -script-args "-centerline_method <CENTERLINE_METHOD> -task <TASK>" -jobs <JOBS>
~~~

where `<CENTERLINE_METHOD>` is either `cnn` (default value) or `svm` and 
`<TASK>` is either `lesionseg` (default value) or `scseg`. You can leave the `-script-args` 
argument empty to stick to the default values.

To run preprocessing for the spinal cord (SC) segmentation task:

~~~
sct_run_batch -script <PATH_TO_REPOSITORY>/model_seg_ms_mp2rage/preprocessing/preprocess_data.sh -path-data <PATH_TO_DATA>/basel-mp2rage/ -path-output basel-mp2rage-preprocessed-scseg -script-args "svm scseg" -jobs <JOBS>
~~~

To run preprocessing for the lesion segmentation task:

~~~
sct_run_batch -script <PATH_TO_REPOSITORY>/model_seg_ms_mp2rage/preprocessing/preprocess_data.sh -path-data <PATH_TO_DATA>/basel-mp2rage/ -path-output basel-mp2rage-preprocessed-lesionseg -script-args "svm lesionseg" -jobs <JOBS>
~~~

After running the preprocessing, you can also run the quality-control (QC) script:
```
python preprocessing/qc_preprocess.py -s <PATH_OUTPUT>
```
which i) logs resolutions and sizes for each subject image for data exploration, 
ii) performs basic shape checks for images and ground-truths (GTs), and most importantly 
iii) checks if the dilated spinal-cord (SC) mask leaves out any lesions from the GT of each rater.

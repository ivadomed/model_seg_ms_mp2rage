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

The data need to be preprocessed before training. The preprocessing command is:

~~~
sct_run_batch -script <PATH_TO_REPOSITORY>/model_seg_ms_mp2rage/preprocessing/preprocess_data.sh -path-data <PATH_TO_DATA>/basel-mp2rage/ -path-output <PATH_OUTPUT> -jobs <JOBS>
~~~

This command will create a `data_processed_scseg` folder for the SC segmentation task and a 
`data_processed_lesionseg` folder for the lesion segmentation task inside the `<PATH_OUTPUT>` 
you specified. Each of these two folders contain only the required files for their respective task.

After running the preprocessing, you can also run the quality-control (QC) script:
```
python preprocessing/qc_preprocess.py -s <PATH_OUTPUT>
```
which i) logs resolutions and sizes for each SC-cropped subject image for data exploration, 
ii) performs basic shape checks for SC-cropped images and ground-truths (GTs), and most importantly 
iii) checks if the dilated spinal-cord (SC) mask leaves out any lesions from the GT of each rater.

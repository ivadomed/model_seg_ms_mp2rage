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

The data need to be preprocessed before training. Here is the syntax: 

~~~
sct_run_batch -script <PATH_TO_REPOSITORY>/model_seg_ms_mp2rage/preprocessing/preprocess_data.sh -path-data <PATH_TO_DATA>/basel-mp2rage/ -path-output ./data_basel-mp2rage -jobs -2
~~~

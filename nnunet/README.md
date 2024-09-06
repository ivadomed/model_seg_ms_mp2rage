# Installation instructions

## Installation of required libraries

Create a virtual invironment: 
~~~
conda create -n venv_nnunet python=3.9
~~~

Activate the environment with the following command:
~~~
conda activate venv_nnunet
~~~

To install required libraries to train an nnUNet v2:

```
pip install -r requirements_nnunet.txt
```

Install SpinalCordToolbox 6.2 :

Installation link : https://spinalcordtoolbox.com/user_section/installation.html


# Data preparation

Create the following folders:

~~~
mkdir nnUNet_raw
mkdir nnUNet_preprocessed
mkdir nnUNet_results
~~~

~~~
 python convert_bids_to_nnUnetv2.py --path-data data-mp2rage/  --path-out nnUNet_raw --dataset-name ms-seg --label-suffix desc-rater1_label-lesion_seg 
    --dataset-number 401 --contrasts UNIT1 --seed 90 --split 0.8 0.2  --labels-path-name data-mp2rage/derivatives/labels/  --session-name ses-M0
~~~

> **Note**
> The test ratio is 0.2 for 20% (train ratio is therefore 80%). For M0 images, the time point is ses-M0.


# Model training on Compute Canada

Send nnUNet_raw to Compute Canada (see https://docs.alliancecan.ca/wiki/Transferring_data)

Before training the model, nnU-Net performs data preprocessing and checks the integrity of the dataset:

~~~
export nnUNet_raw="/path/to/nnUNet_raw"
export nnUNet_preprocessed="/path/to/nnUNet_preprocessed"
export nnUNet_results="/path/to/nnUNet_results"

nnUNetv2_plan_and_preprocess -d DATASET-ID --verify_dataset_integrity
~~~

You will get the configuration plan for all four configurations (2d, 3d_fullres, 3d_lowres).

To train the model, use the following command:

~~~
CUDA_VISIBLE_DEVICES=Nb nnUNetv2_train DATASET-ID CONFIG FOLD --npz
~~~

## Examples for our training

nnunet/run_pre.sh
nnunet/run_train.sh

## Run :
sbatch run_pre.sh
sbatch run_train.sh

# After training, best configuration found

~~~
nnUNetv2_find_best_configuration DATASET_NAME_OR_ID -c CONFIGURATIONS 
~~~

## For our venv on compute canada
sbatch run_post.sh

# Inference evaluation on test dataset split 

~~~
nnUNetv2_predict -i INPUT_FOLDER -o OUTPUT_FOLDER -d DATASET_NAME_OR_ID -c CONFIGURATION --save_probabilities
~~~

# Evaluate segmentation
`data_analysis/test_metrics_nnunet.ipynb`
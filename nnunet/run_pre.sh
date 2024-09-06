#!/bin/bash
#SBATCH --account=def-jcohen
#SBATCH --time=07-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --gpus-per-node=1
#SBATCH --mail-user=nilser.laines@gmail.com
#SBATCH --mail-type=ALL

source ~/scratch/nnunet-ms/bin/activate
export nnUNet_raw=$(realpath nnUNet_raw)
export nnUNet_preprocessed=$(realpath nnUNet_preprocessed)
export nnUNet_results=$(realpath nnUNet_results)

nnUNetv2_plan_and_preprocess -d 401 --verify_dataset_integrity

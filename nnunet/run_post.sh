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

nnUNetv2_predict -d Dataset401_fov-sc-ms -i nnUNet_raw/Dataset401_fov-sc-ms/imagesTs -o results_nnunet/401 -f  0 1 2 3 4 -tr nnUNetTrainer -c 3d_fullres -p nnUNetPlans


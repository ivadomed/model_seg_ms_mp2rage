#!/bin/bash
#SBATCH --account=def-jcohen
#SBATCH --time=00-00:20:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --gpus-per-node=a100:1
#SBATCH --mail-user=nilser.laines@gmail.com
#SBATCH --mail-type=ALL


module load python/3.10

source ~/scratch/nnunet-ms/bin/activate

export nnUNet_raw=$(realpath nnUNet_raw)
export nnUNet_preprocessed=$(realpath nnUNet_preprocessed)
export nnUNet_results=$(realpath nnUNet_results)

#nnUNetv2_train 405 3d_fullres $SLURM_ARRAY_TASK_ID --npz
#salloc --account=def-jcohen --time=0:20:00 --cpus-per-task=32 --mem=128G --gpus-per-node=a100:1
nnUNetv2_predict -d Dataset403_crop-sc-ms -i nnUNet_raw/Dataset403_crop-sc-ms/imagesTs -o results_nnunet/403 -f  0 1 2 3 4 -tr nnUNetTrainer -c 3d_fullres -p nnUNetPlans





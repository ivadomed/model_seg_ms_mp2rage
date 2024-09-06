#!/bin/bash
#SBATCH --account=def-jcohen
#SBATCH --time=07-00:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --gpus-per-node=1
#SBATCH --mail-user=nilser.laines@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --array=0-4

module load python/3.10

source ~/scratch/nnunet-ms/bin/activate

export nnUNet_raw=$(realpath nnUNet_raw)
export nnUNet_preprocessed=$(realpath nnUNet_preprocessed)
export nnUNet_results=$(realpath nnUNet_results)

nnUNetv2_train 405 3d_fullres $SLURM_ARRAY_TASK_ID --npz





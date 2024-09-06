# model_seg_ms_mp2rage

Model repository for MS lesion segmentation on MP2RAGE data (UNIT1 contrast)

## Model overview 

![uniseg_update](https://github.com/ivadomed/model_seg_ms_mp2rage/assets/77469192/e4b5fbcc-03e9-4bc4-829e-604c32dbdd68)

3D model trained with [nnUNetv2](https://github.com/MIC-DKFZ/nnUNet) framework.

## Dependencies
[SCT 6.4](https://spinalcordtoolbox.com/)

## Datasets for training 

- `basel-mp2rage`
- `nih-ms-mp2rage`
- `marseille-3t-mp2rage`

## Installation 
```bash
sct_deepseg -install-task seg_sc_contrast_agnostic
```
```bash
sct_deepseg -install-task seg_ms_lesion_mp2rage 
```

**Warning:** When running the MS lesion segmentation model, the image first need to be cropped around the spinal cord mask with a dilation of 30 mm in the axial plane and 5 mm in the Z-axis. 

## Launch MS lesion segmentation:
1. Spinal cord segmentation 
```bash
sct_deepseg -i IMAGE_UNIT1 -task seg_sc_contrast_agnostic -o IMAGE_UNIT1_sc
```
2. Cropping with dilation (for axial orientation images with 1mm isotropic resolution)
```bash
sct_crop_image -i IMAGE_UNIT1 -m IMAGE_UNIT1_sc -dilate 30x30x5 -o IMAGE_UNIT1_cropped
```
3. MS lesion segmentation 
```bash
sct_deepseg -i IMAGE_UNIT1_cropped -task seg_ms_lesion_mp2rage 
```

## Model implementation on Slicer

1. Install [3D Slicer version 5.7.0](https://download.slicer.org/), then install the module [SlicerNNUnet](https://github.com/KitwareMedical/SlicerNNUnet) from the extensions explorer.

<img src="https://github.com/spinalcordtoolbox/spinalcordtoolbox/assets/77469192/9d7964d2-66e3-464d-ac1a-04caaaced63b" width="300px;" alt=""/>


2. Download and unzip the [ nnUNetTrainer_seg_ms_lesion_mp2rage__nnUNetPlans__3d_fullres.zip](https://github.com/ivadomed/model_seg_ms_mp2rage/releases/tag/r20240610) file. (~120 Mb)

3. Unzip the `.zip` file and place it inside a folder named `Dataset403_seg_ms_lesion_mp2rage_1mm_322subj`. The final directory structure should look like this:
```
Dataset403_seg_ms_lesion_mp2rage_1mm_322subj
└── nnUNetTrainer_seg_ms_lesion_mp2rage__nnUNetPlans__3d_fullres
    ├── dataset_fingerprint.json
    ├── dataset.json
    ├── dataset_split.md
    ├── datasplits
    │   ├── datasplit_basel-mp2rage.yaml
    │   ├── datasplit_marseille-3t-mp2rage.yaml
    │   └── datasplit_nih-ms-mp2rage.yaml
    ├── fold_3
    │   ├── checkpoint_final.pth
    │   ├── debug.json
    │   ├── progress.png
    │   └── training_log_2024_3_14_20_35_08.txt
    └── plans.json
``` 

4. nnUNet Install: Follow the instructions on first row of:
![Slicer-UNIseg](https://github.com/ivadomed/model_seg_ms_mp2rage/assets/77469192/90207a02-f640-4624-b10d-1abbd6433ba6)

5. Implementation
- Navigate and select the Slicer friendly folder on `Model path`
- Folds: Choose the fold 3
- Apply `model_seg_ms_mp2rage` !! 🚀🚀🚀


## Acknowledgments

- Charidimos Tsagkas (Translational Neuroradiology Section, National Institutes of Health, Bethesda, USA)
- Daniel Reich (Translational Neuroradiology Section, National Institutes of Health, Bethesda, USA)
- Cristina Granziera (Neurologic Clinic and Policlinic, University Hospital Basel and University of Basel, Basel, Switzerland)
- Virginie Callot (Center for Magnetic Resonance in Biology and Medicine, CRMBM-CEMEREM, UMR 7339, CNRS, Aix-Marseille University, Marseille, France)

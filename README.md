# model_seg_ms_mp2rage

Model repository for MS lesion segmentation on MP2RAGE data (UNIT1 contrast)

## Model overview 

![uniseg](https://github.com/ivadomed/model_seg_ms_mp2rage/assets/77469192/d7fd985b-5c32-43bb-931f-e9c114a98b4c)

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

## Acknowledgments

Charidimos Tsagkas and Daniel Reich from Translational Neuroradiology Section, National Institutes of Health (NIH), Bethesda, USA, Cristina Granziera from Neurologic Clinic and Policlinic, University Hospital Basel and University of Basel, Basel, Switzerland and Virginie Callot from Center for Magnetic Resonance in Biology and Medicine (CRMBM-CEMEREM, UMR 7339, CNRS, Aix-Marseille University, Marseille, France).

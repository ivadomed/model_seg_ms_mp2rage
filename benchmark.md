# Benchmarking

This file documents benchmarking done on models for (i) SC segmentation and (ii) lesion segmentation on MP2RAGE data.
This will help with presenting experiment results, tracking the performance
of the deployed models, and act as a reference for future projects.

The test subjects used in benchmarking are `sub-P007`, `sub-P010`, `sub-P013`, `sub-P017`, `sub-P024`, and `sub-P025`. 

## SC segmentation

### Currently deployed model
As previously shown in [#19](https://github.com/ivadomed/model_seg_ms_mp2rage/pull/19), the currently
deployed SC segmentation model achieves a test Dice score of 0.9511.

### Subject-by-subject comparison vs. `sct_deepseg_sc`

```console
SC Segmentation Benchmarking
-------------------------------------------------
        Subject:  sub-P013
        SC Model Dice Score:  -0.9512
        SCT (sct_deepseg_sc) Dice Score:  -0.9847
        -------------------------------
        Subject:  sub-P024
        SC Model Dice Score:  -0.9511
        SCT (sct_deepseg_sc) Dice Score:  -0.9764
        -------------------------------
        Subject:  sub-P007
        SC Model Dice Score:  -0.9551
        SCT (sct_deepseg_sc) Dice Score:  -0.9699
        -------------------------------
        Subject:  sub-P017
        SC Model Dice Score:  -0.9492
        SCT (sct_deepseg_sc) Dice Score:  -0.9917
        -------------------------------
```

More detail on this analysis can be found in [#40](https://github.com/ivadomed/model_seg_ms_mp2rage/pull/40).

## Lesion segmentation

### Currently deployed model
The currently deployed lesion segmentation model achieves a test Dice score of 
0.5549 on the first rater annotations and 0.6115 on the second rater annotations.
This is different from the results reported in [#11](https://github.com/ivadomed/model_seg_ms_mp2rage/pull/11)
due to a derivative loading bug recently discovered in `ivadomed` as detailed in [#41](https://github.com/ivadomed/model_seg_ms_mp2rage/issues/41).

### Subject-by-subject comparison vs. `sct_deepseg_lesion`

```console
Lesion Segmentation Benchmarking
-------------------------------------------------
        Subject:  sub-P013
        Lesion Model Dice Score (Rater 1):  -0.4929
        Lesion Model Dice Score (Rater 2):  -0.5588
        SCT (sct_deepseg_lesion) Dice Score (Rater 1):  -0.0017
        SCT (sct_deepseg_lesion) Dice Score (Rater 2):  -0.0215
        -------------------------------
        Subject:  sub-P024
        Lesion Model Dice Score (Rater 1):  -0.4551
        Lesion Model Dice Score (Rater 2):  -0.5891
        SCT (sct_deepseg_lesion) Dice Score (Rater 1):  -0.0023
        SCT (sct_deepseg_lesion) Dice Score (Rater 2):  -0.0014
        -------------------------------
        Subject:  sub-P007
        Lesion Model Dice Score (Rater 1):  -0.4649
        Lesion Model Dice Score (Rater 2):  -0.5302
        SCT (sct_deepseg_lesion) Dice Score (Rater 1):  -0.006
        SCT (sct_deepseg_lesion) Dice Score (Rater 2):  -0.0038
        -------------------------------
        Subject:  sub-P025
        Lesion Model Dice Score (Rater 1):  -0.6126
        Lesion Model Dice Score (Rater 2):  -0.7069
        SCT (sct_deepseg_lesion) Dice Score (Rater 1):  -0.0055
        SCT (sct_deepseg_lesion) Dice Score (Rater 2):  -0.0059
        -------------------------------
        Subject:  sub-P017
        Lesion Model Dice Score (Rater 1):  -1.0
        Lesion Model Dice Score (Rater 2):  -1.0
        SCT (sct_deepseg_lesion) Dice Score (Rater 1):  -1.0
        SCT (sct_deepseg_lesion) Dice Score (Rater 2):  -1.0
        -------------------------------
        Subject:  sub-P010
        Lesion Model Dice Score (Rater 1):  -0.749
        Lesion Model Dice Score (Rater 2):  -0.6726
        SCT (sct_deepseg_lesion) Dice Score (Rater 1):  -0.0017
        SCT (sct_deepseg_lesion) Dice Score (Rater 2):  -0.0039
        -------------------------------
```
More detail on this analysis can be found in [#40](https://github.com/ivadomed/model_seg_ms_mp2rage/pull/40).

### Experiments

All of the models mentioned below were trained and tested for `4` independent trials. The mean +/-
standard deviation test performance is shown in the table.

| Config      | Labels used | Label utilization | Test Dice (Rater 1) | Test Dice (Rater 2) |
| ----------- | ----------- | ----------------- | ------------------- | ------------------- |
| `softseg`   | soft average | n/a | -0.5306 +/- 0.1069 | -0.5968 +/- 0.0771 |
| `multiclass` | both raters | each rater a separate class | -0.5355 +/- 0.1340 | -0.6051 +/- 0.0764 |
| `multiclass` + `softseg` | both raters | each rater a separate class | -0.5301 +/- 0.1385 | -0.6215 +/- 0.0737 |
| `randomrater` | both raters | randomly pick rater in each iter | -0.5734 +/- 0.1132 | -0.5897 +/- 0.1115 |
| `randomrater` + `softseg` | both raters | randomly pick rater in each iter | -0.5507 +/- 0.1230 | -0.6015 +/- 0.1074 |
| `randomrater` + `mix-up (alpha=1.0)` | both raters | randomly pick rater in each iter | -0.4720 +/- 0.1239 | -0.5342 +/- 0.1064 |
| `randomrater++` | both raters, soft average, majority-vote | randomly pick label in each iter | -0.5784 +/- 0.0797 | -0.5543 +/- 0.1110 |
| `randomrater++` + `softseg` | both raters, soft average, majority-vote | randomly pick label in each iter | -0.5625 +/- 0.1278 | -0.6091 +/- 0.0905
| `firstrater` | first rater | n/a | -0.5409 +/- 0.1272 | -0.5491 +/- 0.1214 |
| `secondrater` | first rater | n/a | -0.5011 +/- 0.1646 | -0.6011 +/- 0.0943 |


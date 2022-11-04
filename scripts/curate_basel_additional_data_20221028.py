#!/usr/bin/env python3
# This script is used to convert a dataset to the BIDS convention. 
# Dataset: duke:mri/basel/INsIDER_SCT_Segmentations_COR
# Author: Kiri Stern
# How to use: 
# -> download `INsIDER_SCT_Segmentations_COR` and `basel-mp2rage` datasets to a common location;
# ## `INsIDER_SCT_Segmentations_COR` folder contains: `INsIDER_CXXX` or `INsIDER_PXXX` folders
# ## _CXXX for controls; _PXXX for patients.
# ## nifti files for each patient are found in their respective folders with the form: `MP2_RAGE_UNI_Images.nii.gz` `MP2RAGE_UNI_Images_seg.nii.gz` or `MP2RAGE_UNI_Images_lesion_Cor_CT.nii.gz`
# ### _CXXX folders did not contain `MP2RAGE_UNI_Images_lesion_Cor_CT.nii.gz`
# ## `basel-mp2rage` is in BIDS format
# -> create a folder (scripts) to store this script
# # to run script in command line:
# -> cd to location of this script
# -> run: python -i ../INsIDER_SCT_Segmentations_COR -o ../bidsify

import os
import shutil
import json
import argparse


### make sure not to duplicate same patients from basel_mp2rage 
other = '../basel-mp2rage'

dup_patients = []
for root, dirs, files in os.walk(other, topdown=False):
    for i in dirs:
        if "sub" in i:
            dup_patients.append(i.split(sep='-')[1])

def get_parameters():
    parser = argparse.ArgumentParser(description='Convert dataset to BIDS format.')
    parser.add_argument("-i", "--path-input",
                        help="Path to folder containing the dataset to convert to BIDS",
                        required=True)
    parser.add_argument("-o", "--path-output",
                        help="Path to the output BIDS folder",
                        required=True,
                        )
    arguments = parser.parse_args()
    return arguments


def main(path_input, path_output):    
    if os.path.isdir(path_output):
        shutil.rmtree(path_output)
    os.makedirs(path_output, exist_ok=True)
    
    images = {
    "MP2RAGE_UNI_Images.nii.gz": "_UNIT1.nii.gz"
    }

    der1 = {
        "MP2RAGE_UNI_Images_seg.nii.gz": "_UNIT1_seg-manual.nii.gz"
    }
    der2 = {
        "MP2RAGE_UNI_Images_lesion_Cor_CT.nii.gz": "_UNIT1_lesion-manual.nii.gz"
    }

    for dirs, subdirs, files in os.walk(path_input):
        for file in files:
            if file.endswith('.nii.gz') and file in images or file in der1 or file in der2:
                path_file_in = os.path.join(dirs, file)
                path = os.path.normpath(path_file_in)
                print(path)
                subid_bids = 'sub-' + (path.split(os.sep))[2].split(sep='_')[1]
                # print(subid_bids)
                if subid_bids.split(sep="-")[1] not in dup_patients:
                    if file.endswith('seg.nii.gz'):
                        # print(file)
                        path_subid_bids_dir_out = os.path.join(path_output, 'derivatives', 'labels', subid_bids, 'anat')
                        # print(path_subid_bids_dir_out)
                        path_file_out = os.path.join(path_subid_bids_dir_out, subid_bids + der1[file])
                        # print(path_file_out)
                    elif file.endswith('lesion_Cor_CT.nii.gz'):
                        path_subid_bids_dir_out = os.path.join(path_output, 'derivatives', 'labels', subid_bids, 'anat')
                        # print(path_subid_bids_dir_out)
                        path_file_out = os.path.join(path_subid_bids_dir_out, subid_bids + der2[file])
                        # print(path_file_out)
                    elif file.endswith("Images.nii.gz"):
                        path_subid_bids_dir_out = os.path.join(path_output, subid_bids, 'anat')
                        path_file_out = os.path.join(path_subid_bids_dir_out, subid_bids + images[file])
                    if not os.path.isdir(path_subid_bids_dir_out):
                        os.makedirs(path_subid_bids_dir_out)
                    shutil.copy(path_file_in, path_file_out)
                    print(path_file_out)

    for dirName, subdirList, fileList in os.walk(path_output):
        for file in fileList:
            if file.endswith('.nii.gz'):
                originalFilePath = os.path.join(dirName, file)
                jsonSidecarPath = os.path.join(dirName, file.split(sep='.')[0] + '.json')
                if not os.path.exists(jsonSidecarPath):
                    print("Missing: " + jsonSidecarPath)
                    if file.endswith('lesion-manual.nii.gz'):
                        data_json_label = {}
                        data_json_label[u'Author'] = "Tsagkas Charidimos"
                        data_json_label[u'Label'] = "lesion-manual"
                        with open(jsonSidecarPath, 'w') as outfile:
                            outfile.write(json.dumps(data_json_label, indent=2, sort_keys=True))
                        outfile.close()
                    elif file.endswith("seg-manual.nii.gz"):
                        data_json_label = {}
                        data_json_label[u'Author'] = "Tsagkas Charidimos"
                        data_json_label[u'Label'] = "seg-manual"
                        with open(jsonSidecarPath, 'w') as outfile:
                            outfile.write(json.dumps(data_json_label, indent=2, sort_keys=True))
                        outfile.close()
                    else:
                        os.system('touch ' + jsonSidecarPath)

    sub_list = os.listdir(path_output)
    sub_list.remove('derivatives')

    sub_list.sort()

    import csv

    participants = []
    for subject in sub_list:
        row_sub = []
        row_sub.append(subject)
        row_sub.append('n/a')
        row_sub.append('n/a')
        participants.append(row_sub)

    print(participants)
    with open(path_output + '/participants.tsv', 'w') as tsv_file:
        tsv_writer = csv.writer(tsv_file, delimiter='\t', lineterminator='\n')
        tsv_writer.writerow(["participant_id", "sex", "age"])
        for item in participants:
            tsv_writer.writerow(item)

    # Create participants.json
    data_json = {"participant_id": {
        "Description": "Unique Participant ID",
        "LongName": "Participant ID"
        },
        "sex": {
            "Description": "M or F",
            "LongName": "Participant sex"
        },
        "age": {
            "Description": "yy",
            "LongName": "Participant age"}
    }

    with open(path_output + '/participants.json', 'w') as json_file:
        json.dump(data_json, json_file, indent=4)

    # append to  dataset_description.json
    dataset_description = {"BIDSVersion": "BIDS 1.6.0",
                           "Name": "BIDSify INsIDER_SCT_Segmentations_COR"
                           }

    with open(path_output + '/dataset_description.json', 'w') as json_file:
        json.dump(dataset_description, json_file, indent=4)

    # append to original README
    shutil.copy('../basel-mp2rage/README', path_output)
    
    with open(path_output+'/README', 'a') as readme_file:
        readme_file.write('\n\n2022-10-30: Added new data from INsIDER_SCT_Segmentations_COR\nSee repository https://github.com/ivadomed/model_seg_ms_mp2rage')


if __name__ == "__main__":
    args = get_parameters()
    main(args.path_input, args.path_output)

#!/bin/bash

########## DEFINE VARIABLES

###### DO NOT CHANGE THESE
CSV_HEADINGS="SUBJECT_ID,IMAGE,R_CORTICAL_SA,L_CORTICAL_SA,R_MEAN_GYRI,L_MEAN_GYRI,R_MEAN_SULCI,L_MEAN_SULCI,R_K2_VARIANCE,L_K2_VARIANCE" # headings of csv file
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the csv file so multiple can be run keeping data seperate
LOG_OUTPUT=${HOME}/Scripts/MyScripts/logs/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

###### CAN BE CHANGED BY USER ONLY CHANGE THE PARTS THAT ARE NOT IN {} UNLESS YOU KNOW WHAT YOU ARE DOING
DATASET=/N/project/aMSM_AD/ADNI/HCP/MSM # Folder containing subject data
OUTPUT=${OUTPUT_DIR}/AD_cortical_thinning_${CURRENT_DATETIME}.csv # name and location of csv output file

########## BEGIN LOGGING
#exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## CREATE CSV FILE
echo "***************************************************************************"
echo "CREATING OUTPUT FILE"
echo "***************************************************************************"
mkdir -p ${OUTPUT_DIR}
if [ ! -e "${OUTPUT}" ]; then
    echo ${CSV_HEADINGS} > ${OUTPUT}
fi
echo "OUTPUT CREATED AT ${OUTPUT}"

########## FIND SUBJECTS
echo "***************************************************************************"
echo "FINDING DATA"
echo "***************************************************************************"
DIRECTORIES=($(ls ${DATASET}))
echo "DATA FOUND: "

for DIR in ${DIRECTORIES[@]}; do
    echo ${DIR}
done
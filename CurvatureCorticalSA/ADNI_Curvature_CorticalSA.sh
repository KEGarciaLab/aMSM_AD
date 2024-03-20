#!/bin/bash

########## DEFINE VARIABLES

###### DO NOT CHANGE THESE
CSV_HEADINGS="SUBJECT_ID,TIME_POINT,R_CORTICAL_SA,L_CORTICAL_SA,R_MEAN_GYRI,L_MEAN_GYRI,R_MEAN_SULCI,L_MEAN_SULCI,R_K2_VARIANCE,L_K2_VARIANCE" # headings of csv file
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the csv file so multiple can be run keeping data seperate
LOG_OUTPUT=${HOME}/Scripts/MyScripts/logs/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

###### CAN BE CHANGED BY USER ONLY CHANGE THE PARTS THAT ARE NOT IN {} UNLESS YOU KNOW WHAT YOU ARE DOING
DATASET=/N/project/aMSM_AD/ADNI/HCP/MSM # Folder containing subject data
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # output location for script
CP_OUTPUT=${OUTPUT_DIR}/ADNI_datasheet.csv # name and location of csv output file at MaxCP
ANAT_OUTPUT=${OUTPUT_DIR}/ADNI_datasheet.csv # name and location of csv output file at MaxANAT
########## BEGIN LOGGING
#exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## CREATE CSV FILE
echo "***************************************************************************"
echo "CREATING OUTPUT FILE"
echo "***************************************************************************"
mkdir -p ${OUTPUT_DIR}
if [ ! -e "${OUTPUT}" ]; then
    echo ${CSV_HEADINGS} > ${CP_OUTPUT}
    echo ${CSV_HEADINGS} > ${ANAT_OUTPUT}
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

########## EXTRACT SUBJECT NUMBER AND TIME POINTS

########## LOCATE FILES

########## CALCULATE SA
######## SURFACE VERTEX AREA
######## METRIC STATS SUM

########## MEAN GYRI AND SULCI K2 VARIANCE
######## K1 and K2
###### GUASS
###### MEAN
###### KMAX
###### KMIN
###### K1
###### REMOVE NaN
###### K2
###### REMOVE NaN
######## SPLIT SULCI AND GYRI
######## MEAN GYRI
######## MEAN SULCI
######## K2 VARIANCE

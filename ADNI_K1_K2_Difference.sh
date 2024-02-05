#!/bin/bash

########## DEFINE VARIABLES

###### DO NOT CHANGE THESE
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the csv file so multiple can be run keeping data seperate
LOG_OUTPUT=${HOME}/Scripts/MyScripts/logs/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

###### CAN BE CHANGED BY USER ONLY CHANGE THE PARTS THAT ARE NOT IN {} UNLESS YOU KNOW WHAT YOU ARE DOING
DATASET=/N/project/aMSM/ADNI/Data/3T_Analysis/MSM/ADNI_Subjects # Folder containing subject data
PREFIX="Subject" # Prefix to prepend to each subject ID
SUBJECTS="" # list of subject ID to run through (leave blank to generate the list automatically). Subject numbers should be entered with a space between seperate numbers "#### ####"
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # output location for script

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## GET ALL DIR NAMES
SUBJECTS=$(find ${DATASET} -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

for SUBJECT in ${SUBJECTS}; do
    echo ${SUBJECT}
done

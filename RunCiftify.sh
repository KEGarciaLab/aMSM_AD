########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data seperate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

######### CHANGE AS NEEDED
DATASET=/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION # Folder containing subject data
SCRIPT_OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # ouptut location for generated scripts
CIFTIFY_OUTPUT_DIR=/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION/Ciftify # Output location for the generated scripts

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

########## GET DIRS
######### READ LINES FROM subjects.txt
SUBJECTS_DIRS=()
while read -r SUBJECT_DIR; do
    SUBJECT_DIRS+=("${SUBJECT_DIR}")
done < "subjects.txt"

########## GENERATE SCRIPTS
for DIR in SUBJECT_DIRS; do
    
########## SUBMIT SCRIPTS

ciftify_recon_all --fs-subjects-dir Data/ADNI_Data/FS --ciftify-work-dir Data/ADNI_Data/HCP/ 941_S_6068_m36_20210817_r1481645_T1
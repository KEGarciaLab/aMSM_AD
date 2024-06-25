######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data seperate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs # Dir for log file
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

########## CHANGE AS NEEDED
DATASET_NAME="ADNI" # Name of dataset being used, must be ADNI or IADRC
DATASET=/N/slate/sarigdon # Folder containing subject data
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the text file so multiple runs keep data separate
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0") # Output location
OUTPUT_FILE=${OUTPUT_DIR}/subject_numbers_${CURRENT_DATETIME}.txt # Output file name
SUBJECTS="1326 1385 1387" # Subjects to get full folder name for

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## ITERATE OVER EACH SUBJECT AND TIMEPOINT COMBO
if [ "${DATASET_NAME}" == "ADNI" ]; then
    for SUBJECT in ${SUBJECTS}; do
        echo "SEARCHING FOR FILES FOR SUBJECT ${SUBJECT}"
        find ${DATASET} -maxdepth 1 -type d -name "*_S_${SUBJECT}_*" -exec basename {} \; >> ${OUTPUT_FILE}
    done
elif [ "${DATASET_NAME}" == "IADRC" ]; then
    for SUBJECT in ${SUBJECTS}; do
        echo "SEARCHING FOR FILES FOR SUBJECT ${SUBJECT}"
        find ${DATASET} -maxdepth 1 -type d -name "${SUBJECT}_*" -exec basename {} \; >> ${OUTPUT_FILE}
    done
fi

echo "SEARCHING COMPLETE SAVED AT ${OUTPUT_FILE}"
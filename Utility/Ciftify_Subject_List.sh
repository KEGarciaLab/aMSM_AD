######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data seperate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs # Dir for log file
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

########## CHANGE AS NEEDED
DATASET_NAME="ADNI" # Name of dataset being used, must be ADNI or IADRC
DATASET=/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION # Folder containing subject data
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the text file so multiple runs keep data separate
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0") # Output location
OUTPUT_FILE=${OUTPUT_DIR}/subject_numbers_${CURRENT_DATETIME}.txt # Output file name
SUBJECTS="0125 4389 4114 0341 4802 4280 6668 4367 6310 0547 6264 7046 6580 4803 0340 4281 1408 1242 6038 4649 6197 6669 0793 6535 4115 6892 0689 4366 4388 0546 0800 0686 6037 4369 1407 0611 4970 4552 1357 4004 0549 7049 4905 5120 6802 4646 4387 6803 4438 4232 0874 4971 4553 1406 0225 6173 5095 4904 2357 4386 4005 6199 0548 4791 5121 7048 6465 0610 5154 4907 6170 6035 4792 2220 0684 5096 2116 0802 6466 4385 0613 0129 0899 6800 5157 6268 4644 6467 6665 1152 5123 0227 4645 0876 6269 4230 4007 4708 6801 5097" # Subjects to get full folder name for

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
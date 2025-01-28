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
SUBJECTS="4613 4929 7050 2376 0042 0424 4121 0712 7051 6056 6409 6647 4883 4371 4928 1192 6632 0551 6250 6953 0999 0924 4421 4245 0425 0043 4120 4612 0249 6500 5178 6851 6121 4053 2402 6433 5058 0844 7117 6929 6046 6352 1281 4277 0417 4501 0273 1326 0769 0938 6850 6047 5059 2403 0272 4500 2270 0416 1114 4694 0038 0768 0621 5248 0845 4276 2142 1161 6120 6432 5165 1280 6044 6350 0622 0657 4275 4503 1188 4051 7115 1283 5166 4936 4419 4349 6853 1117 6852 4609 4050 1398 6629 5167 4274 7068 6045 0656 7114 1116" # Subjects to get full folder name for

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
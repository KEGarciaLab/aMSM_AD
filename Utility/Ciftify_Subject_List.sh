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
SUBJECTS="4899 6488 1254 6831 2210 1255 4982 6830 5228 0708 4898 0601 6593 2052 4560 4762 2027 0919 4876 6885 6948 5079 0887 0058 0142 4255 6653 1414 6411 5142 4220 0138 6024 2363 5227 4394 4897 4879 4071 6947 0888 0916 4718 0057 4912 0862 0981 4672 0441 0863 4896 6487 6025 0434 4719 0056 4878 6946 0889 0139 4254 1028 4395 0917 6748 6652 6413 6329 4396 4073 4671 6888 0442 1346 0914 5140 4257 0055 0860 4222 6651 4910 6328 0982 0915 0443 0436 6027 2360 5075 0054 6485 1417 4072 6412 5141 4894 6650 4256 6889" # Subjects to get full folder name for

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
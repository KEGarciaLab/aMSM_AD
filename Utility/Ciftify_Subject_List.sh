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
SUBJECTS="4614 2304 0045 4661 4885 4427 6641 5235 0922 4243 0557 0328 6256 1197 4125 0158 0921 2307 4424 6956 7120 0554 6505 7054 5236 0420 6255 6053 6254 6052 0717 0638 2373 0047 5040 6957 4375 7121 0555 0920 6643 4241 7055 5237 0159 6504 4887 4616 6631 6828 4372 6253 0426 4422 5047 6349 0040 7052 1191 2301 4578 0552 6950 6055 1335 6503 2208 4611 6644 2374 5230 6054 4423 5231 6348 0711 4610 6159 6951 4122 1190 0926 6630 6502 4579 1334 0041 6252 0553 4373 4420 6501 6408 6646 1337 0925 6251 6057 4244 6952" # Subjects to get full folder name for

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
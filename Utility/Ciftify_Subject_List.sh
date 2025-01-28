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
SUBJECTS="4348 0568 4502 6351 4696 1282 0414 6042 0299 1322 0840 1164 5029 4057 6518 5160 4138 6125 4505 1285 6855 6356 0277 2381 0413 6854 4139 0841 6519 6043 6436 6357 5028 2407 0298 2146 2380 1284 0948 0625 0276 1165 7112 2274 4272 6857 4507 1113 1269 6354 4271 5162 1038 0626 4868 0842 0653 6041 2405 0410 1286 4506 0652 4692 4054 0627 0843 4869 1321 5163 4270 1268 6514 6921 6622 4343 6244 6129 0930 1267 0761 4134 1182 1168 4509 0945 1393 5241 1289 0031 0563 0295 6128 0629 4603 2278 1183 0760 4508 1169 1037 0294 0030 7062 2296 1288 6757 5240 6920 6515 4867 0931 6754 0947 5243 6439 1034 4059 7061 1265 1391 6620 0033 6516 6358 0932 5027 4136 6438 6755 2148 6359 6621 1181 7060 6517 0296 4340 5026 4410 5242 4601 4058 1035 6240 4862 6510 4417 1032 0035 " # Subjects to get full folder name for

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
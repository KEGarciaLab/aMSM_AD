########## DEFINE VARIABLES
DATASET=/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION # Folder containing subject data
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the text file so multiple runs keep data separate
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0") # Output location
OUTPUT_FILE=${OUTPUT_DIR}/subject_numbers_${CURRENT_DATETIME}.txt # Output file name
SUBJECTS="0072 0074 0382 0679 0680 0751 0767 0934 1052" # Subjects to extract folder name for, this should be the first number after _S_


########## ENSURE THAT OUTPUT EXISTS
mkdir -p ${OUTPUT_DIR}

########## ITERATE OVER EACH SUBJECT AND TIMEPOINT COMBO
for SUBJECT in ${SUBJECTS}; do
    find ${DATASET} -maxdepth 1 -type d -name "*_S_${SUBJECT}_*" -exec basename {} \; >> ${OUTPUT_FILE}
done
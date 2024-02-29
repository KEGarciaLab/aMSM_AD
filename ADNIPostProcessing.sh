########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data separate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file
SUBJECTS=() # Array of subject numbers to be processed
LEVELS=6 # Levels for MSM

######### CHANGE AS NEEDED
DATASET=/N/project/aMSM_AD/ADNI/HCP/MSM # Folder containing subject data
ACCOUNT="r00540" # Slurm allocation to use

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
#mkdir -p ${LOG_OUTPUT_DIR}

########## BEGIN LOGGING
#exec > >(tee -a "${LOG_OUTPUT}") 2>&1

DIRECTORIES=(${DATASET}/*/)

for DIR in ${DIRECTORIES[@]}; do
    echo ${DIR}
done


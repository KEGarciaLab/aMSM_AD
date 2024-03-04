########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data separate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

######### CHANGE AS NEEDED
DATASET=/N/project/aMSM_AD/ADNI/HCP/MSM # Folder containing subject data
BASE_SCENE=${DATASET}/base.scene # Master scene file location
ACCOUNT="r00540" # Slurm allocation to use

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

DIRECTORIES=($(ls ${DATASET}))

for DIR in ${DIRECTORIES[@]}; do
    echo "***************************************************************************"
    echo "FIND ALL SUBJECT DIRECTORIES"
    echo "***************************************************************************"
    SUBJECT_DIR=${DATASET}/${DIR}
    SUBJECT=$(echo ${DIR} | cut -d "_" -f 1)
    TIME1=$(echo ${DIR} | cut -d "_" -f 2)
    TIME2=$(echo ${DIR} | cut -d "_" -f 4)
    echo "DIRECTORIES LOCATED. RELEVANT DIRECTORES:"

    if [ ${TIME1} == "BL" ]; then
        echo ${SUBJECT_DIR}
    fi
done


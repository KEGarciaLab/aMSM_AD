########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data separate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs #Directory for log file
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

######### CHANGE AS NEEDED
DATASET=/N/project/aMSM_AD/ADNI/HCP/MSM # Folder containing subject data
BASE_SCENE=${DATASET}/base.scene # Master scene file location
ACCOUNT="r00540" # Slurm allocation to use

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## FIND SUBJECTS
DIRECTORIES=($(ls ${DATASET}))
FORWARD_DIRS=()

echo "***************************************************************************"
echo "FIND ALL SUBJECT DIRECTORIES"
echo "***************************************************************************"
echo "DIRECTORIES LOCATED. RELEVANT DIRECTORES:"
for DIR in ${DIRECTORIES[@]}; do
    SUBJECT_DIR=${DATASET}/${DIR}

    if [ ${TIME1} == "BL" ]; then
        echo ${SUBJECT_DIR}
        FORWARD_DIRS+=(${SUBJECT_DIR})
    fi
done

########## BEGIN POST PROCESSING
for DIR in ${FORWARD_DIRS[@]}; do
    ########## SLICE OUT INFO
    DIR_NAME=$(basename "/N/project/aMSM_AD/ADNI/HCP/MSM/0072_BL_to_m06")
    SUBJECT=$(echo ${DIR_NAME} | cut -d "_" -f 1)
    TIME1=$(echo ${DIR_NAME} | cut -d "_" -f 2)
    TIME2=$(echo ${DIR_NAME} | cut -d "_" -f 4)

    ########## GET ALL FILES
    L_YOUNGER_SURFACE=
    R_YOUNGER_SURFACE
    ########## ADD TO SPEC FILE

    ########## EDIT SCENE FILE

    ########## GENERATE IMAGE
done

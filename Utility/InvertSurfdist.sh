########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data separate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file
SUBJECTS=() # Array of subject numbers to be processed

######### CHANGE AS NEEDED
DATASET=/N/project/aMSM_AD/ADNI/HCP/TO_BE_PROCESSED # Folder containing subject data
MSM_OUT=/N/project/aMSM_AD/ADNI/HCP/MSM


########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## GET SUBJECTS
echo "***************************************************************************"
echo "LOCATING SUBJECTS"
echo "***************************************************************************"
for DIR in "${DATASET}"/*;do
    if [ -d ${DIR} ]; then
        SUBJECT=$(echo "${DIR}" | grep -oP '(?<=Subject_)\d+(?=_BL)')
        SUBJECTS+=(${SUBJECT})
    fi
done
echo "THE FOLLOWING SUBJECTS WILL BE PROCESSED: ${SUBJECTS[@]}"

for SUBJECT in ${SUBJECTS[@]}; do
    if [ -z ${SUBJECT} ]; then
        continue
    fi
    echo "***************************************************************************"
    echo "BEGIN PROCESSING FOR SUBJECT ${SUBJECT}"
    echo "***************************************************************************"
    TIME_POINT=$(echo "${SUBJECT}" | awk -F_ '{print $3}')
    echo ${TIME_POINT}
    PREFIX=${MSM_OUT}/${SUBJECT}_${TIME_POINT}_to_BL/${SUBJECT}_${HEMISPHERE}_${TIME_POINT}-BL.
    echo ${PREFIX}

    for HEMISPHERE in L R; do
        ########## LOCATE FILES
        echo "***************************************************************************"
        echo "LOCATING NECESSARY FILES"
        echo "***************************************************************************"

        #OLDER_CP_SURF=
        #OLDER_ANAT_SURFT=
        #YOUNGER_CP_SURF=
        #YOUNGER_ANAT_SURF=

        ########## CREATE INVERSE MAP
    fi
done
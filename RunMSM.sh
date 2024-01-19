########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data seperate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file
SUBJECTS=() #array of subject numbers to be processed

######### CHANGE AS NEEDED
DATASET=/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION/HCP # Folder containing subject data
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # ouptut location for generated scripts
ACCOUNT="r00540" # Slurm allocation to use
MAXCP=${DATASET}/ico5sphere.LR.reg.surf.gii
MAXANAT=${DATASET}/ico6sphere.LR.reg.surf.gii

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

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
    echo "***************************************************************************"
    echo "BEGIN PROCESSING FOR SUBJECT ${SUBJECT}"
    echo "***************************************************************************"

    ########## EXTRACT TIME POINTS
    echo "FINDING TIMEPOINTS"
    TIME_POINTS=()
    for DIR in "${DATASET}"/*;do
        if [ -d ${DIR} ]; then
            TIME_POINT=$(echo "${DIR}" | grep -oP "(?<=Subject_${SUBJECT}_)m\d+")
            TIME_POINTS+=("${TIME_POINT}")
        fi
    done
    echo "SUBJECT ${SUBJECT} HAS THE FOLLOWING TIME POINTS: ${TIME_POINTS[@]}"

    ########## DEFINE BASLINE FILES AS YOUNGER
    ######## GET NAME OF DATA FOLDER 
    DIRECTORIES=("${DATASET}/Subject_${SUBJECT}_BL"/*)
    DIRECTORIES=${DIRECTORIES[0]//*zz_templates/}
    BL_DIR=${DATASET}/Subject_${SUBJECT}_BL/${DIRECTORIES[0]##*/}
    BL_FULL_DATA=$(basename "${BL_DIR}")
    echo "YOUNGER DATA LOACTED AT ${BL_DIR}"
    echo "FULL YOUNGER DATA NAME: ${BL_FULL_DATA}"
    # LYAS=${BL_DIR}
    # RYAS
    # LYSS
    # RYSS


    ########## BEGIN ITERATING OVER TIME POINTS
    for OLDER_TIME in ${TIME_POINTS[@]}; do
        echo "BEGIN REGISTRATION BETWEEN BL AND ${OLDER_TIME}"
        DIRECTORIES=("${DATASET}/Subject_${SUBJECT}_${OLDER_TIME}"/*)
        DIRECTORIES=${DIRECTORIES[0]//*zz_templates/}
        OLDER_DIR=${DATASET}/Subject_${SUBJECT}_${OLDER_TIME}/${DIRECTORIES[0]##*/}
        OLDER_FULL_DATA=$(basename "${OLDER_DIR}")
        echo "OLDER DATA LOACTED AT ${OLDER_DIR}"
        echo "FULL YOUNGER DATA NAME: ${OLDER_FULL_DATA}"

    done

done

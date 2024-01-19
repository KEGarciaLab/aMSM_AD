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
MAXCP=${DATASET}/ico5sphere.LR.reg.surf.gii # path to ico5sphere
MAXANAT=${DATASET}/ico6sphere.LR.reg.surf.gii # path to ico6sphere
RESOLUTION="32k" # resolution of mesh to use either '32k' or '164k'
RESOLUTION_LOCATION="MNINonLinear/fsaverage_LR32k" # location of meshes 32k should be 'MNINonLinear/fsaverage_LR32k' 164k should be 'MNINonLinear'

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
    BL_DIR=${DATASET}/Subject_${SUBJECT}_BL/${DIRECTORIES[0]##*/} #Base directory withg baseline data
    BL_FULL_DATA=$(basename "${BL_DIR}") # Full subject name for files
    BL_DIR=${BL_DIR}/${RESOLUTION_LOCATION} # Directory with meshes
    echo "YOUNGER DATA LOACTED AT ${BL_DIR}"
    echo "FULL YOUNGER DATA NAME: ${BL_FULL_DATA}"
    LYAS=${BL_DIR}/${BL_FULL_DATA}.L.midthickness.${RESOLUTION}_fs_LR.surf.gii # Left younger anatomical surface
    RYAS=${BL_DIR}/${BL_FULL_DATA}.R.midthickness.${RESOLUTION}_fs_LR.surf.gii # Right younger anatomical surface
    LYSS=${BL_DIR}/${BL_FULL_DATA}.L.sphere.${RESOLUTION}_fs_LR.surf.gii # Left younger spherical surface
    RYSS=${BL_DIR}/${BL_FULL_DATA}.R.sphere.${RESOLUTION}_fs_LR.surf.gii # Right younger spherical surface
    echo "LEFT YOUNGER ANATOMICAL SURFACE: ${LYAS}"
    echo "RIGHT YOUNGER ANATOMICAL SURFACE: ${RYAS}"
    echo "LEFT YOUNGER SPHERICAL SURFACE: ${LYSS}"
    echo "RIGHT YOUNGER SPHERICAL SURFACE: ${RYSS}"

    ########## BEGIN ITERATING OVER TIME POINTS
    for OLDER_TIME in ${TIME_POINTS[@]}; do
        echo "BEGIN REGISTRATION BETWEEN BL AND ${OLDER_TIME}"
        DIRECTORIES=("${DATASET}/Subject_${SUBJECT}_${OLDER_TIME}"/*)
        DIRECTORIES=${DIRECTORIES[0]//*zz_templates/}
        OLDER_DIR=${DATASET}/Subject_${SUBJECT}_${OLDER_TIME}/${DIRECTORIES[0]##*/}
        OLDER_FULL_DATA=$(basename "${OLDER_DIR}")
        OLDER_DIR=${OLDER_DIR}/${RESOLUTION_LOCATION}
        echo "OLDER DATA LOACTED AT ${OLDER_DIR}"
        echo "FULL OLDER DATA NAME: ${OLDER_FULL_DATA}"
        LOAS=${OLDER_DIR}/${OLDER_FULL_DATA}.L.midthickness.${RESOLUTION}_fs_LR.surf.gii # Left older anatomical surface
        ROAS=${OLDER_DIR}/${OLDER_FULL_DATA}.R.midthickness.${RESOLUTION}_fs_LR.surf.gii # Right older anatomical surface
        LOSS=${OLDER_DIR}/${OLDER_FULL_DATA}.L.sphere.${RESOLUTION}_fs_LR.surf.gii # Left older spherical surface
        ROSS=${OLDER_DIR}/${OLDER_FULL_DATA}.R.sphere.${RESOLUTION}_fs_LR.surf.gii # Right older spherical surface
        echo "LEFT OLDER ANATOMICAL SURFACE: ${LOAS}"
        echo "RIGHT OLDER ANATOMICAL SURFACE: ${ROAS}"
        echo "LEFT OLDER SPHERICAL SURFACE: ${LOSS}"
        echo "RIGHT OLDER SPHERICAL SURFACE: ${ROSS}"

    done

done

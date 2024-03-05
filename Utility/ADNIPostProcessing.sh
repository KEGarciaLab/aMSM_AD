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
    DIR_NAME=$(basename ${DIR})
    SUBJECT=$(echo ${DIR_NAME} | cut -d "_" -f 1)
    TIME1=$(echo ${DIR_NAME} | cut -d "_" -f 2)
    TIME2=$(echo ${DIR_NAME} | cut -d "_" -f 4)

    ########## GET ALL FILES
    echo "***************************************************************************"
    echo "FIND ALL SUBJECT DIRECTORIES"
    echo "***************************************************************************"
    L_YOUNGER_SURFACE=${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.LYAS.CPgrid.surf.gii
    R_YOUNGER_SURFACE=${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.RYAS.CPgrid.surf.gii
    L_OLDER_SURFACE=${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.anat.CPGrid.reg.surf.gii
    R_OLDER_SURFACE=${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.anat.CPGrid.reg.surf.gii
    L_SURFACE_MAP=${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.surfdist.CPgrid.func.gii
    R_SURFACE_MAP=${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.surfdist.CPgrid.func.gii
    SPEC_FILE=${DIR}/${SUBJECT}_${TIME1}-${TIME2}.spec
    echo "FILES RETRIEVED:"
    echo ${L_YOUNGER_SURFACE}
    echo ${L_OLDER_SURFACE}
    echo ${L_SURFACE_MAP}
    echo ${R_YOUNGER_SURFACE}
    echo ${R_OLDER_SURFACE}
    echo ${R_SURFACE_MAP}

    ########## ADD TO SPEC FILE
    echo "***************************************************************************"
    echo "ADD TO SPEC FILE"
    echo "***************************************************************************"
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${L_YOUNGER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${L_OLDER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${L_SURFACE_MAP}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${R_YOUNGER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${R_OLDER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${R_SURFACE_MAP}

    ########## EDIT SCENE FILE
    echo "***************************************************************************"
    echo "EDIT BASE SCENE"
    echo "***************************************************************************"
    sed "s!SURFACE_PATH!${DIR}!g;s!L_YOUNGER_SURFACE!${L_YOUNGER_SURFACE}!g;s!L_OLDER_SURFACE!${L_OLDER_SURFACE}!g;s!L_SURFACE_MAP!${L_SURFACE_MAP}!g;s!R_YOUNGER_SURFACE!${R_YOUNGER_SURFACE}!g;s!R_OLDER_SURFACE!${R_OLDER_SURFACE}!g;s!R_SURFACE_MAP!${R_SURFACE_MAP}!g;" ${DATASET}/base.scene > ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene"

    ########## GENERATE IMAGE
    echo "***************************************************************************"
    echo "GENERATE IMAGE"
    echo "***************************************************************************"
    wb_command -show-scene ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene 1 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png 1024 512
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png"
    
done

########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data separate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs #Directory for log file
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

######### CHANGE AS NEEDED
DATASET=/N/project/aMSM_AD/ADNI/HCP/MSM # Folder containing subject data
IMAGE_DIR=/N/project/aMSM_AD/ADNI/HCP/POST_PROCESSING # Location to copy all images to
ACCOUNT="r00540" # Slurm allocation to use

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}
mkdir -p ${IMAGE_DIR}

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## FIND SUBJECTS
DIRECTORIES=($(ls ${DATASET}))
FORWARD_DIRS=()
REVERSE_DIRS=()

echo
echo "***************************************************************************"
echo "FIND ALL SUBJECT DIRECTORIES"
echo "***************************************************************************"
echo "DIRECTORIES LOCATED. RELEVANT DIRECTORES:"
for DIR in ${DIRECTORIES[@]}; do
    SUBJECT_DIR=${DATASET}/${DIR}
    TIME1=$(echo ${DIR} | cut -d "_" -f 2)

    if [ ${TIME1} == "BL" ]; then
        echo "FORWARD REGISTRATION: ${SUBJECT_DIR}"
        FORWARD_DIRS+=(${SUBJECT_DIR})
    else
        echo "REVERSE REGISTRATION: ${SUBJECT_DIR}"
        REVERSE_DIRS+=(${SUBJECT_DIR})
    fi
done

########## BEGIN POST PROCESSING
for DIR in ${FORWARD_DIRS[@]}; do
    echo
    echo "***************************************************************************"
    echo "BEGIN FORWARD POST PROCESSING"
    echo "***************************************************************************"
    ########## SLICE OUT INFO
    DIR_NAME=$(basename ${DIR})
    SUBJECT=$(echo ${DIR_NAME} | cut -d "_" -f 1)
    TIME1=$(echo ${DIR_NAME} | cut -d "_" -f 2)
    TIME2=$(echo ${DIR_NAME} | cut -d "_" -f 4)

    ########## GET ALL FILES
    echo "***************************************************************************"
    echo "FIND ALL SUBJECT DIRECTORIES"
    echo "***************************************************************************"
    L_YOUNGER_SURFACE=${SUBJECT}_L_${TIME1}-${TIME2}.LYAS.CPgrid.surf.gii
    R_YOUNGER_SURFACE=${SUBJECT}_R_${TIME1}-${TIME2}.RYAS.CPgrid.surf.gii
    L_OLDER_SURFACE=${SUBJECT}_L_${TIME1}-${TIME2}.anat.CPgrid.reg.surf.gii
    R_OLDER_SURFACE=${SUBJECT}_R_${TIME1}-${TIME2}.anat.CPgrid.reg.surf.gii
    L_SURFACE_MAP=${SUBJECT}_L_${TIME1}-${TIME2}.surfdist.CPgrid.func.gii
    R_SURFACE_MAP=${SUBJECT}_R_${TIME1}-${TIME2}.surfdist.CPgrid.func.gii
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
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${DIR}/${L_YOUNGER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${DIR}/${L_OLDER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${DIR}/${L_SURFACE_MAP}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${DIR}/${R_YOUNGER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${DIR}/${R_OLDER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${DIR}/${R_SURFACE_MAP}
    echo "COMPLETE. SAVED AT: ${SPEC_FILE}"

    ########## EDIT SCENE FILE
    echo "***************************************************************************"
    echo "EDIT BASE SCENES"
    echo "***************************************************************************"
    sed "s!SURFACE_PATH!${DIR}!g;s!L_YOUNGER_SURFACE!${L_YOUNGER_SURFACE}!g;s!L_OLDER_SURFACE!${L_OLDER_SURFACE}!g;s!L_SURFACE_MAP!${L_SURFACE_MAP}!g;s!R_YOUNGER_SURFACE!${R_YOUNGER_SURFACE}!g;s!R_OLDER_SURFACE!${R_OLDER_SURFACE}!g;s!R_SURFACE_MAP!${R_SURFACE_MAP}!g;" ${IMAGE_DIR}/base.scene > ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene
    sed "s!SURFACE_PATH!${DIR}!g;s!L_YOUNGER_SURFACE!${L_YOUNGER_SURFACE}!g;s!L_OLDER_SURFACE!${L_OLDER_SURFACE}!g;s!L_SURFACE_MAP!${L_SURFACE_MAP}!g;s!R_YOUNGER_SURFACE!${R_YOUNGER_SURFACE}!g;s!R_OLDER_SURFACE!${R_OLDER_SURFACE}!g;s!R_SURFACE_MAP!${R_SURFACE_MAP}!g;" ${IMAGE_DIR}/base_no-scale.scene > ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.scene
    sed "s!SURFACE_PATH!${DIR}!g;s!L_YOUNGER_SURFACE!${L_YOUNGER_SURFACE}!g;s!L_OLDER_SURFACE!${L_OLDER_SURFACE}!g;s!L_SURFACE_MAP!${L_SURFACE_MAP}!g;s!R_YOUNGER_SURFACE!${R_YOUNGER_SURFACE}!g;s!R_OLDER_SURFACE!${R_OLDER_SURFACE}!g;s!R_SURFACE_MAP!${R_SURFACE_MAP}!g;" ${IMAGE_DIR}/base_inverted.scene > ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_INVERTED.scene
    sed "s!SURFACE_PATH!${DIR}!g;s!L_YOUNGER_SURFACE!${L_YOUNGER_SURFACE}!g;s!L_OLDER_SURFACE!${L_OLDER_SURFACE}!g;s!L_SURFACE_MAP!${L_SURFACE_MAP}!g;s!R_YOUNGER_SURFACE!${R_YOUNGER_SURFACE}!g;s!R_OLDER_SURFACE!${R_OLDER_SURFACE}!g;s!R_SURFACE_MAP!${R_SURFACE_MAP}!g;" ${IMAGE_DIR}/base_-nverted_no-scale.scene > ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_INVERTED_NO-SCALE.scene
    echo "SCENE WITH SCALE COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene"
    echo "SCENE WITHOUT SCALE COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.scene"
    echo "INVERTED SCENE WITH SCALE COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_INVERTED.scene"
    echo "INVERTED SCENE WITHOUT SCALE COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_INVERTED_NO-SCALE.scene"

    ########## GENERATE IMAGE
    echo "***************************************************************************"
    echo "GENERATE IMAGE"
    echo "***************************************************************************"
    wb_command -show-scene ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene 1 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png 1024 512
    wb_command -show-scene ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.scene 1 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png 1024 512
    wb_command -show-scene ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene 1 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png 1024 1024
    chmod 777 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png
    chmod 777 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png
    chmod 777 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png"
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png"
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png"
    
    ########## COPY IMAGE TO POSTPROCESSING FOLDER
    echo "***************************************************************************"
    echo "COPY IMAGE"
    echo "***************************************************************************"
    cp ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png ${IMAGE_DIR}
    cp ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png ${IMAGE_DIR}
    cp ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png ${IMAGE_DIR}
    echo "COMPLETE. SAVED AT: ${IMAGE_DIR}/${SUBJECT}_${TIME1}-${TIME2}.png"
    echo "COMPLETE. SAVED AT: ${IMAGE_DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png"
    echo "COMPLETE. SAVED AT: ${IMAGE_DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png"
done

for DIR in ${REVERSE_DIRS[@]}; do
    echo
    echo "***************************************************************************"
    echo "BEGIN REVERSE POST PROCESSING"
    echo "***************************************************************************"
    ########## SLICE OUT INFO
    DIR_NAME=$(basename ${DIR})
    SUBJECT=$(echo ${DIR_NAME} | cut -d "_" -f 1)
    TIME1=$(echo ${DIR_NAME} | cut -d "_" -f 2)
    TIME2=$(echo ${DIR_NAME} | cut -d "_" -f 4)

    ########## GET ALL FILES
    echo "***************************************************************************"
    echo "FIND ALL SUBJECT DIRECTORIES"
    echo "***************************************************************************"
    L_YOUNGER_SURFACE=${SUBJECT}_L_${TIME1}-${TIME2}.anat.CPgrid.reg.surf.gii
    R_YOUNGER_SURFACE=${SUBJECT}_R_${TIME1}-${TIME2}.anat.CPgrid.reg.surf.gii
    L_OLDER_SURFACE=${SUBJECT}_L_${TIME1}-${TIME2}.LOAS.CPgrid.surf.gii
    R_OLDER_SURFACE=${SUBJECT}_R_${TIME1}-${TIME2}.ROAS.CPgrid.surf.gii
    L_SURFACE_MAP=${SUBJECT}_L_${TIME1}-${TIME2}.surfdist.CPgrid.func.gii
    R_SURFACE_MAP=${SUBJECT}_R_${TIME1}-${TIME2}.surfdist.CPgrid.func.gii
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
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${DIR}/${L_YOUNGER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${DIR}/${L_OLDER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_LEFT ${DIR}/${L_SURFACE_MAP}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${DIR}/${R_YOUNGER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${DIR}/${R_OLDER_SURFACE}
    wb_command -add-to-spec-file ${SPEC_FILE} CORTEX_RIGHT ${DIR}/${R_SURFACE_MAP}
    echo "COMPLETE. SAVED AT: ${SPEC_FILE}"

    ########## EDIT SCENE FILE
    echo "***************************************************************************"
    echo "EDIT BASE SCENES"
    echo "***************************************************************************"
    sed "s!SURFACE_PATH!${DIR}!g;s!L_YOUNGER_SURFACE!${L_YOUNGER_SURFACE}!g;s!L_OLDER_SURFACE!${L_OLDER_SURFACE}!g;s!L_SURFACE_MAP!${L_SURFACE_MAP}!g;s!R_YOUNGER_SURFACE!${R_YOUNGER_SURFACE}!g;s!R_OLDER_SURFACE!${R_OLDER_SURFACE}!g;s!R_SURFACE_MAP!${R_SURFACE_MAP}!g;" ${IMAGE_DIR}/base-reverse.scene > ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene
    sed "s!SURFACE_PATH!${DIR}!g;s!L_YOUNGER_SURFACE!${L_YOUNGER_SURFACE}!g;s!L_OLDER_SURFACE!${L_OLDER_SURFACE}!g;s!L_SURFACE_MAP!${L_SURFACE_MAP}!g;s!R_YOUNGER_SURFACE!${R_YOUNGER_SURFACE}!g;s!R_OLDER_SURFACE!${R_OLDER_SURFACE}!g;s!R_SURFACE_MAP!${R_SURFACE_MAP}!g;" ${IMAGE_DIR}/base-reverse_no-scale.scene > ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.scene
    echo "SCENE WITH SCALE COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene"
    echo "SCENE WITHOUT SCALE COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.scene"

    ########## GENERATE IMAGE
    echo "***************************************************************************"
    echo "GENERATE IMAGE"
    echo "***************************************************************************"
    wb_command -show-scene ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene 1 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png 1024 512
    wb_command -show-scene ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.scene 1 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png 1024 512
    wb_command -show-scene ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.scene 1 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png 1024 1024
    chmod 777 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png
    chmod 777 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png
    chmod 777 ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png"
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png"
    echo "COMPLETE. SAVED AT: ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png"
    
    ########## COPY IMAGE TO POSTPROCESSING FOLDER
    echo "***************************************************************************"
    echo "COPY IMAGE"
    echo "***************************************************************************"
    cp ${DIR}/${SUBJECT}_${TIME1}-${TIME2}.png ${IMAGE_DIR}
    cp ${DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png ${IMAGE_DIR}
    cp ${DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png ${IMAGE_DIR}
    echo "COMPLETE. SAVED AT: ${IMAGE_DIR}/${SUBJECT}_${TIME1}-${TIME2}.png"
    echo "COMPLETE. SAVED AT: ${IMAGE_DIR}/${SUBJECT}_${TIME1}-${TIME2}_NO-SCALE.png"
    echo "COMPLETE. SAVED AT: ${IMAGE_DIR}/${SUBJECT}_${TIME1}-${TIME2}-tall.png"
done

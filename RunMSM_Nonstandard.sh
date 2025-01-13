########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data separate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file
SUBJECTS=() # Array of subject numbers to be processed, Leave empty
LEVELS=6 # Levels for MSM

######### CHANGE AS NEEDED
STARTING_TIME="" # Name of dataset must be eithe ADNI or IADRC
DATASET=/N/slate/sarigdon/Rerun/ciftify # Folder containing subject data
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # ouptut location for generated scripts
ACCOUNT="r00540" # Slurm allocation to use
MAXCP=${DATASET}/ico5sphere.LR.reg.surf.gii # path to ico5sphere
MAXANAT=${DATASET}/ico6sphere.LR.reg.surf.gii # path to ico6sphere
MSMCONFIG=/N/project/aMSM/ADNI/SetupFiles/Config/configAnatGrid6 # location of config file
MSM_OUT=/N/slate/sarigdon/Rerun/MSM # output for msm

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

LOWEST_IMAGE_NUMBERS="35039 40392 32777 45126 82509 40378 52129 125029 32755 120403 86345 83521 65874 86318 74496 40657 31500 82571 65268 51934 90989 87493 64862 89124 65561 34195 34371 124115 40404 59214 35653 40191 34190 39197 32817 75459 63508 35014 39200 79784 65374 47757 66018 90925 40828 47186 47177 90026 33046 64116 90916 40352 34168 39203 40172 59955 53802 37190 90942 40269 40840 59677 31446 40254 40692 33114 59986 52107 31107 66824 118916 31392 86327 58054 74600 52138 53836 59174 35029 53845 38887 32785 34866 81434 31468 38878 39288 30968 31540"
for IMAGE_NUMBER in ${LOWEST_IMAGE_NUMBERS}; do
    STARTING_TIME = ${IMAGE_NUMBER}
    ########## GET SUBJECTS
    echo "***************************************************************************"
    echo "LOCATING SUBJECTS"
    echo "***************************************************************************"
    for DIR in "${DATASET}"/*;do
        echo "DIRECTORY LOCATED: ${DIR}"
        if [ -d ${DIR} ]; then
            echo "CHECKING DIRECTORY: ${DIR}"
            SUBJECT=$(echo "${DIR}" | grep -oP "(?<=Subject_)[a-zA-Z0-9]+(?=_Image_${STARTING_TIME})")
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

        ########## EXTRACT TIME POINTS
        echo "FINDING TIMEPOINTS"
        TIME_POINTS=()
        for DIR in "${DATASET}"/*;do
            if [ -d ${DIR} ]; then
                TIME_POINT=$(echo "${DIR}" | grep -oP "(?<=Subject_${SUBJECT}_Image_)(?!${STARTING_TIME})[^/]+")
                TIME_POINTS+=("${TIME_POINT}")
            fi
        done
        echo "SUBJECT ${SUBJECT} HAS THE FOLLOWING TIME POINTS: ${TIME_POINTS[@]}"

        ########## DEFINE BASLINE FILES AS YOUNGER
        ######## GET DATA LOCATION 
        BL_DIR=${DATASET}/Subject_${SUBJECT}_Image_${STARTING_TIME}
        echo "YOUNGER DATA LOACTED AT ${BL_DIR}"
        
        ######## DEFINE MESHES
        LYAS=${BL_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}.L.midthickness.32k_fs_LR.surf.gii # Left younger anatomical surface
        RYAS=${BL_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}.R.midthickness.32k_fs_LR.surf.gii # Right younger anatomical surface
        LYSS=${BL_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}.L.sphere.32k_fs_LR.surf.gii # Left younger spherical surface
        RYSS=${BL_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}.R.sphere.32k_fs_LR.surf.gii # Right younger spherical surface
        echo "LEFT YOUNGER ANATOMICAL SURFACE: ${LYAS}"
        echo "RIGHT YOUNGER ANATOMICAL SURFACE: ${RYAS}"
        echo "LEFT YOUNGER SPHERICAL SURFACE: ${LYSS}"
        echo "RIGHT YOUNGER SPHERICAL SURFACE: ${RYSS}"

        ########## PRE MSM-JOBS
        echo "***************************************************************************"
        echo "BEGIN BL PRE-MSM JOBS FOR SUBJECT ${SUBJECT}"
        echo "***************************************************************************"

        ######## THICKNESS
        wb_command -cifti-separate ${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}.thickness.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT ${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}_Thickness.L.func.gii -metric CORTEX_RIGHT ${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}_Thickness.R.func.gii

        ######## CURVATURE
        wb_command -cifti-separate ${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}.curvature.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT ${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}_Curvature.L.func.gii -metric CORTEX_RIGHT ${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}_Curvature.R.func.gii
        LYC=${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}_Curvature.L.func.gii
        RYC=${BL_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${STARTING_TIME}_Curvature.R.func.gii

        ########## BEGIN ITERATING OVER TIME POINTS
        for TIME_POINT in ${TIME_POINTS[@]}; do
            if [ -z ${TIME_POINT} ]; then
                continue
            fi
            ########## DEFINE TIMEPOINT AS OLDER
            echo "BEGIN REGISTRATION BETWEEN BL AND ${TIME_POINT}"

            ######## CREATE MSM OUTPUT DIRS
            MSM_F_DIR=${MSM_OUT}/${SUBJECT}_${STARTING_TIME}_to_${TIME_POINT}
            mkdir -p ${MSM_F_DIR}
            MSM_R_DIR=${MSM_OUT}/${SUBJECT}_${TIME_POINT}_to_${STARTING_TIME}
            mkdir -p ${MSM_R_DIR}
            
            ######## GET DATA LOCATION
            OLDER_DIR=${DATASET}/Subject_${SUBJECT}_${TIME_POINT}
            echo "OLDER DATA LOACTED AT ${OLDER_DIR}"
            
            ######## DEFINE MESHES
            LOAS=${OLDER_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}.L.midthickness.32k_fs_LR.surf.gii # Left older anatomical surface
            ROAS=${OLDER_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}.R.midthickness.32k_fs_LR.surf.gii # Right older anatomical surface
            LOSS=${OLDER_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}.L.sphere.32k_fs_LR.surf.gii # Left older spherical surface
            ROSS=${OLDER_DIR}/T1w/fsaverave_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}.R.sphere.32k_fs_LR.surf.gii # Right older spherical surface
            echo "LEFT OLDER ANATOMICAL SURFACE: ${LOAS}"
            echo "RIGHT OLDER ANATOMICAL SURFACE: ${ROAS}"
            echo "LEFT OLDER SPHERICAL SURFACE: ${LOSS}"
            echo "RIGHT OLDER SPHERICAL SURFACE: ${ROSS}"

            ########## PRE MSM-JOBS
            echo "***************************************************************************"
            echo "BEGIN ${TIME_POINT} PRE-MSM JOBS FOR SUBJECT ${SUBJECT}"
            echo "***************************************************************************"

            ######## THICKNESS
            wb_command -cifti-separate ${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}.thickness.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT ${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}_Thickness.L.func.gii -metric CORTEX_RIGHT ${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}_Thickness.R.func.gii
            
            ######## CURVATURE
            wb_command -cifti-separate ${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}.curvature.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT ${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}_Curvature.L.func.gii -metric CORTEX_RIGHT ${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}_Curvature.R.func.gii
            LOC=${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}_Curvature.L.func.gii
            ROC=${OLDER_DIR}/MNINonLinear/faaverage_LR32k/Subject_${SUBJECT}_Image_${TIME_POINT}_Curvature.R.func.gii

            ########## GENERATE FORWARD AND REVERSE SCRIPTS
            for HEMISPHERE in L R; do
                ######## CREATE FILE ASSOCIATIONS AND SET STRUCTURE
                if [ ${HEMISPHERE} = L ]; then
                    STRUCTURE="CORTEX_LEFT"
                    YAS=${LYAS}
                    YSS=${LYSS}
                    OAS=${LOAS}
                    OSS=${LOSS}
                    YC=${LYC}
                    OC=${ROC}
                fi

                if [ ${HEMISPHERE} = R ]; then
                    STRUCTURE="CORTEX_RIGHT"
                    YAS=${RYAS}
                    YSS=${RYSS}
                    OAS=${ROAS}
                    OSS=${ROSS}
                    YC=${RYC}
                    OC=${ROC}
                fi

                ######## CREATE OUTPUT NAMES
                F_OUT=${MSM_F_DIR}/${SUBJECT}_${HEMISPHERE}_${STARTING_TIME}-${TIME_POINT}.
                R_OUT=${MSM_R_DIR}/${SUBJECT}_${HEMISPHERE}_${TIME_POINT}-${STARTING_TIME}.

                echo "***************************************************************************"
                echo "BEGIN GENERATING MSM SCRIPTS"
                echo "***************************************************************************"
                ######## FORWARD
cat > ${OUTPUT_DIR}/Run_${SUBJECT}_${HEMISPHERE}_${STARTING_TIME}-${TIME_POINT}.sh << EOF
#!/bin/bash

#SBATCH -J MSM.${SUBJECT}.${HEMISPHERE}.${STARTING_TIME}-${TIME_POINT}
#SBATCH -p general
#SBATCH -o ${HOME}/Scripts/MyScripts/logs/Slurm/%j_MSM_${SUBJECT}_${STARTING_TIME}-${TIME_POINT}.txt
#SBATCH -e ${HOME}/Scripts/MyScripts/logs/Slurm/%j_MSM_${SUBJECT}_${STARTING_TIME}-${TIME_POINT}_error.txt
#SBATCH --mail-type=fail
#SBATCH --mail-user=sarigdon@iu.edu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=49:00:00
#SBATCH --mem=16G
#SBATCH -A ${ACCOUNT}

########## RUN MSM
msm --levels=${LEVELS} --conf=${MSMCONFIG} --inmesh=${YSS} --refmesh=${OSS} --indata=${YC} --refdata=$OC --inanat=${YAS} --refanat=${OAS} --out=${F_OUT} --verbose

########## SURFACE DISTORTION
wb_command -surface-resample ${YAS} ${YSS} ${MAXANAT} "BARYCENTRIC" ${F_OUT}${HEMISPHERE}YAS.ANATgrid.surf.gii
wb_command -set-structure ${F_OUT}${HEMISPHERE}YAS.ANATgrid.surf.gii ${STRUCTURE}
wb_command -surface-resample ${YAS} ${YSS} ${MAXCP} "BARYCENTRIC" ${F_OUT}${HEMISPHERE}YAS.CPgrid.surf.gii
wb_command -set-structure ${F_OUT}${HEMISPHERE}YAS.CPgrid.surf.gii ${STRUCTURE}

########## OUTPUT CALCULATIONS
wb_command -surface-resample ${OAS} ${OSS} ${F_OUT}sphere.reg.surf.gii "BARYCENTRIC" ${F_OUT}anat.true.reg.surf.gii
wb_command -surface-distortion ${YAS} ${F_OUT}anat.true.reg.surf.gii ${F_OUT}surfdist.func.gii

######## MAXANAT
wb_command -surface-sphere-project-unproject ${MAXANAT} ${YSS} ${F_OUT}sphere.reg.surf.gii ${F_OUT}sphere.ANATgrid.reg.surf.gii
wb_command -surface-resample ${OAS} ${OSS} ${F_OUT}sphere.ANATgrid.reg.surf.gii "BARYCENTRIC" ${F_OUT}anat.ANATgrid.reg.surf.gii
wb_command -surface-distortion ${F_OUT}${HEMISPHERE}YAS.ANATgrid.surf.gii ${F_OUT}anat.ANATgrid.reg.surf.gii ${F_OUT}surfdist.ANATgrid.func.gii

######## MAXCP
wb_command -surface-sphere-project-unproject ${MAXCP} ${YSS} ${F_OUT}sphere.reg.surf.gii ${F_OUT}sphere.CPgrid.reg.surf.gii
wb_command -surface-resample ${OAS} ${OSS} ${F_OUT}sphere.CPgrid.reg.surf.gii "BARYCENTRIC" ${F_OUT}anat.CPgrid.reg.surf.gii
wb_command -surface-distortion ${F_OUT}${HEMISPHERE}YAS.CPgrid.surf.gii ${F_OUT}anat.CPgrid.reg.surf.gii ${F_OUT}surfdist.CPgrid.func.gii
EOF

                echo "COMPLETED Run_${SUBJECT}_${HEMISPHERE}_${STARTING_TIME}-${TIME_POINT}.sh"

                ######## REVERSE
cat > ${OUTPUT_DIR}/Run_${SUBJECT}_${HEMISPHERE}_${TIME_POINT}-${STARTING_TIME}.sh << EOF
#!/bin/bash

#SBATCH -J MSM.${SUBJECT}.${HEMISPHERE}.${TIME_POINT}-${STARTING_TIME}
#SBATCH -p general
#SBATCH -o ${HOME}/Scripts/MyScripts/logs/Slurm/%j_MSM_${SUBJECT}_${TIME_POINT}-${STARTING_TIME}.txt
#SBATCH -e ${HOME}/Scripts/MyScripts/logs/Slurm/%j_MSM_${SUBJECT}_${TIME_POINT}-${STARTING_TIME}_error.txt
#SBATCH --mail-type=fail
#SBATCH --mail-user=sarigdon@iu.edu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=49:00:00
#SBATCH --mem=16G
#SBATCH -A ${ACCOUNT}

########## RUN MSM
msm --levels=${LEVELS} --conf=${MSMCONFIG} --inmesh=${OSS} --refmesh=${YSS} --indata=${OC} --refdata=$YC --inanat=${OAS} --refanat=${YAS} --out=${R_OUT} --verbose

########## SURFACE DISTORTION
wb_command -surface-resample ${OAS} ${OSS} ${MAXANAT} "BARYCENTRIC" ${R_OUT}${HEMISPHERE}OAS.ANATgrid.surf.gii
wb_command -set-structure ${R_OUT}${HEMISPHERE}OAS.ANATgrid.surf.gii ${STRUCTURE}
wb_command -surface-resample ${OAS} ${OSS} ${MAXCP} "BARYCENTRIC" ${R_OUT}${HEMISPHERE}OAS.CPgrid.surf.gii
wb_command -set-structure ${R_OUT}${HEMISPHERE}OAS.CPgrid.surf.gii ${STRUCTURE}

########## OUTPUT CALCULATIONS
wb_command -surface-resample ${YAS} ${YSS} ${R_OUT}sphere.reg.surf.gii "BARYCENTRIC" ${R_OUT}anat.true.reg.surf.gii
wb_command -surface-distortion ${OAS} ${R_OUT}anat.true.reg.surf.gii ${R_OUT}surfdist.func.gii

######## MAXANAT
wb_command -surface-sphere-project-unproject ${MAXANAT} ${OSS} ${R_OUT}sphere.reg.surf.gii ${R_OUT}sphere.ANATgrid.reg.surf.gii
wb_command -surface-resample ${YAS} ${YSS} ${R_OUT}sphere.ANATgrid.reg.surf.gii "BARYCENTRIC" ${R_OUT}anat.ANATgrid.reg.surf.gii
wb_command -surface-distortion ${R_OUT}${HEMISPHERE}OAS.ANATgrid.surf.gii ${R_OUT}anat.ANATgrid.reg.surf.gii ${R_OUT}surfdist.ANATgrid.func.gii

######## MAXCP
wb_command -surface-sphere-project-unproject ${MAXCP} ${OSS} ${R_OUT}sphere.reg.surf.gii ${R_OUT}sphere.CPgrid.reg.surf.gii
wb_command -surface-resample ${YAS} ${YSS} ${R_OUT}sphere.CPgrid.reg.surf.gii "BARYCENTRIC" ${R_OUT}anat.CPgrid.reg.surf.gii
wb_command -surface-distortion ${R_OUT}${HEMISPHERE}OAS.CPgrid.surf.gii ${R_OUT}anat.CPgrid.reg.surf.gii ${R_OUT}surfdist.CPgrid.func.gii
EOF

                echo "COMPLETED Run_${SUBJECT}_${HEMISPHERE}_${TIME_POINT}-${STARTING_TIME}.sh"
                echo "***************************************************************************"
                echo "SUBMITING SCRIPTS"
                echo "***************************************************************************"
                sbatch ${OUTPUT_DIR}/Run_${SUBJECT}_${HEMISPHERE}_${STARTING_TIME}-${TIME_POINT}.sh
                sbatch ${OUTPUT_DIR}/Run_${SUBJECT}_${HEMISPHERE}_${TIME_POINT}-${STARTING_TIME}.sh
                echo
            done
        done
    done
done

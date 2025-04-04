########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data seperate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

######### CHANGE AS NEEDED
DELIMITER="_" # Delimiter used in name of files to seperate name
SUBJECT_PLACEMENT="3" # which place the subject id is based on delimiter 1 indicates the space to the left of first delimiter
TIME_POINT_PLACEMENT="4" # which place holds the time point designation based on delimiter
DATASET_NAME="ADNI" # Name of dataset being used
DATASET=/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION # Folder containing subject data
CIFTIFY_OUTPUT_DIR=/N/project/aMSM_AD/ADNI/HCP/TO_BE_PROCESSED # ouptut location for script results
SCRIPT_OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # Output location for the generated scripts
SUBJECT_TXT=${HOME}/Scripts/MyScripts/Output/Ciftify_Subject_List.sh/subject_numbers_2025-04-04_11-45-39.txt #List of subjects to run, ensure you have ran Ciftify_Subject_List.sh and are pointng to the correct file
ACCOUNT="r00540" # Slurm allocation to use

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}
mkdir -p ${SCRIPT_OUTPUT_DIR}

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## GET DIRS
######### READ LINES FROM subjects.txt
echo "***************************************************************************"
echo "GETTING SUBJECTS FROM ${SUBJECT_TXT}"
echo "***************************************************************************"
SUBJECTS_DIRS=()
while read -r SUBJECT_DIR; do
    echo ${SUBJECT_DIR}
    SUBJECT_DIRS+=("${SUBJECT_DIR}")
done < ${SUBJECT_TXT}

########## GENERATE SCRIPTS
for DIR in ${SUBJECT_DIRS[@]}; do
    ########## EXTRACT TIME POINTS
    echo "***************************************************************************"
    echo "GENERATING SCRIPTS"
    echo "***************************************************************************"
    SUBJECT=$(echo "$DIR" | awk -F"${DELIMITER}" -v pos="${SUBJECT_PLACEMENT}" '{print $pos}')
    TIME_POINT=$(echo "$DIR" | awk -F"${DELIMITER}" -v pos="${TIME_POINT_PLACEMENT}" '{print $pos}')
    echo "BEGIN GENERATION OF SCRIPT FOR ${SUBJECT} FOR TIME POINT ${TIME_POINT}"

    ########## CREATE SUBJECT FOLDERS
    echo "CREATING OUTPUT DIRS"
    SUBJECT_CIFTIFY_OUTPUT_DIR=${CIFTIFY_OUTPUT_DIR}/Subject_${SUBJECT}_${TIME_POINT}
    mkdir ${SUBJECT_CIFTIFY_OUTPUT_DIR}

    ######### GENERATE SCRIPT
    echo "WRITING SCRIPT"
    echo "SCRIPT COMMAND: ciftify_recon_all --fs-subjects-dir ${DATASET} --ciftify-work-dir ${SUBJECT_CIFTIFY_OUTPUT_DIR} --resample-to-T1w32k ${DIR}"
    cat > ${SCRIPT_OUTPUT_DIR}/recon_all_Subject_${SUBJECT}_${TIME_POINT}.sh <<EOF
#!/bin/bash

#SBATCH -J ${DATASET_NAME}_recon_all_Subject_${SUBJECT}_${TIME_POINT}
#SBATCH -p general
#SBATCH -o ${HOME}/Scripts/MyScripts/logs/Slurm/%j_Subject_${SUBJECT}_${TIME_POINT}.txt
#SBATCH -e ${HOME}/Scripts/MyScripts/logs/Slurm/%j_Subject_${SUBJECT}_${TIME_POINT}_error.txt
#SBATCH --mail-type=fail
#SBATCH --mail-user=sarigdon@iu.edu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=49:00:00
#SBATCH --mem=16G
#SBATCH -A ${ACCOUNT}

ciftify_recon_all --fs-subjects-dir ${DATASET} --ciftify-work-dir ${SUBJECT_CIFTIFY_OUTPUT_DIR} --resample-to-T1w32k ${DIR}
EOF
    ########## SUBMIT SCRIPT TO SLURM
    echo "SUBMITTING SCRIPT FOR ${SUBJECT} FOR TIME POINT ${TIME_POINT}"
    sbatch ${SCRIPT_OUTPUT_DIR}/recon_all_Subject_${SUBJECT}_${TIME_POINT}.sh
done
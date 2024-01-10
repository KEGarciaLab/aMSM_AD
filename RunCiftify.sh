########## DEFINE VARIABLES

######### DO NOT CHANGE UNLESS YOU KNOW WHAT YOU ARE DOING
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the log file so multiple can be run keeping data seperate
LOG_OUTPUT_DIR=${HOME}/Scripts/MyScripts/logs
LOG_OUTPUT=${LOG_OUTPUT_DIR}/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

######### CHANGE AS NEEDED
DATASET=/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION # Folder containing subject data
CIFTIFY_OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # ouptut location for script results
SCRIPT_OUTPUT_DIR=${CIFTIFY_OUTPUT_DIR}/Scripts # Output location for the generated scripts
SUBJECT_TXT=${HOME}/Scripts/MyScripts/Output/Ciftify_Subject_List.sh/subject_numbers_2024-01-10_07-29-07.txt #List of subjects to run, ensure you have ran Ciftify_Subject_List.sh and are pointng to the correct file
ACCOUNT="r00540" # Slurm allocation to use

########## ENSURE THAT OUTPUT AND LOG DIRS EXISTS
mkdir -p ${LOG_OUTPUT_DIR}
mkdir -p ${SCRIPT_OUTPUT_DIR}
mkdir -p ${CIFTIFY_OUTPUT_DIR}

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
for DIR in SUBJECT_DIRS; do
    ########## EXTRACT TIME POINTS
    echo "***************************************************************************"
    echo "GENERATING SCRIPTS"
    echo "***************************************************************************"
    SUBJECT=$(IFS=_; fields=${DIR}; echo "${fields[2]}")
    TIME_POINT=$(IFS=_; fields=${DIR}; echo "${fields[3]}")
    echo "BEGIN GENERATION OF SCRIPT FOR ${SUBJECT} FOR TIME POINT ${TIME_POINT}"

    ########## CREATE SUBJECT FOLDERS
    echo "CREATING OUTPUT DIRS"
    SUBJECT_SCRIPT_OURPUT_DIR=${SCRIPT_OUTPUT_DIR}/Subject_${SUBJECT}_${TIME_POINT}
    SUBJECT_CIFTIFY_OUTPUT_DIR=${CIFTIFY_OUTPUT_DIR}/Subject_${SUBJECT}_${TIME_POINT}
    mkdir ${SUBJECT_SCRIPT_OUTPUT_DIR}
    mkdir ${SUBJECT_CIFTIFY_OUTPUT_DIR}

    ######### GENERATE SCRIPT
    echo "WRITING SCRIPT"
    cat > ${SCRIPT_OUTPUT_DIR}/recon_all_Subject_${SUBJECT}_${TIME_POINT}.sh <<EOF
#!/bin/bash

#SBATCH -J recon_all_Subject_${SUBJECT}_${TIME_POINT}
#SBATCH -p general
#SBATCH -o ${HOME}/Scripts/MyScripts/logs/Slurm/Subject_${SUBJECT}_${TIME_POINT}_%j.txt
#SBATCH -e ${HOME}/Scripts/MyScripts/logs/Slurm/Subject_${SUBJECT}_${TIME_POINT}_%j_error.txt
#SBATCH --mail-type=fail
#SBATCH --mail-user=sarigdon@iu.edu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=49:00:00
#SBATCH --mem=16G
#SBATCH -A ${ACCOUNT}

ciftify_recon_all --fs-subjects-dir ${DATASET} --ciftify-work-dir ${SUBJECT_CIFTIFY_OUTPUT_DIR} ${SUBJECT}
EOF
    ########## SUBMIT SCRIPT TO SLURM
    echo "SUBMITTING SCRIPT FOR ${SUBJECT} FOR TIME POINT ${TIME_POINT}"
    sbatch ${SCRIPT_OUTPUT_DIR}/recon_all_Subject_${SUBJECT}_${TIME_POINT}.sh

done
    
########## SUBMIT SCRIPTS

ciftify_recon_all --fs-subjects-dir Data/ADNI_Data/FS --ciftify-work-dir Data/ADNI_Data/HCP 941_S_6068_m36_20210817_r1481645_T1
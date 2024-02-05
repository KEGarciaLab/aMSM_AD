#!/bin/bash

########## DEFINE VARIABLES

###### DO NOT CHANGE THESE
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the csv file so multiple can be run keeping data seperate
LOG_OUTPUT=${HOME}/Scripts/MyScripts/logs/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

###### CAN BE CHANGED BY USER ONLY CHANGE THE PARTS THAT ARE NOT IN {} UNLESS YOU KNOW WHAT YOU ARE DOING
DATASET=/N/project/aMSM/ADNI/Data/3T_Analysis/MSM/ADNI_Subjects # Folder containing subject data
PREFIX="Subject" # Prefix to prepend to each subject ID
SUBJECTS="" # list of subject ID to run through (leave blank to generate the list automatically). Subject numbers should be entered with a space between seperate numbers "#### ####"

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## GET ALL DIR NAMES
echo "***************************************************************************"
echo "FIND ALL SUBJECT NAMES"
echo "***************************************************************************"
SUBJECTS=$(find ${DATASET} -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
echo "THE FOLLOWING SUBJECTS WILL BE PROCESSED: ${SUBJECTS[@]}"

for SUBJECT in ${SUBJECTS}; do
    ########## GET FILE LOCATIONS
    echo "***************************************************************************"
    echo "LOCATING RELEVANT FILES"
    echo "***************************************************************************"
    SUBJECT_DIR=${DATASET}/${SUBJECT}
    SUBJECT_LF_DIR=${SUBJECT_DIR}/${SUBJECT}_LF
    SUBJECT_RF_DIR=${SUBJECT_DIR}/${SUBJECT}_RF
    SUBJECT_LF_LR_YAS=${SUBJECT_LF_DIR}/${SUBJECT}_LF.LYAS.LR.surf.gii
    SUBJECT_LF_LLR_YAS=${SUBJECT_LF_DIR}/${SUBJECT}_LF.LYAS.LLR.surf.gii
    SUBJECT_RF_LR_YAS=${SUBJECT_RF_DIR}/${SUBJECT}_RF.RYAS.LR.surf.gii
    SUBJECT_RF_LLR_YAS=${SUBJECT_RF_DIR}/${SUBJECT}_RF.RYAS.LLR.surf.gii
    SUBJECT_LF_LR_ANAT=${SUBJECT_LF_DIR}/${SUBJECT}_LF.forward.anat.LR.reg.surf.gii
    SUBJECT_LF_LLR_ANAT=${SUBJECT_LF_DIR}/${SUBJECT}_LF.forward.anat.LLR.reg.surf.gii
    SUBJECT_RF_LR_ANAT=${SUBJECT_LF_DIR}/${SUBJECT}_RF.forward.anat.LR.reg.surf.gii
    SUBJECT_RF_LLR_ANAT=${SUBJECT_LF_DIR}/${SUBJECT}_RF.forward.anat.LLR.reg.surf.gii
    LF_LR_OUT=${SUBJECT_LF_DIR}/${SUBJECT}_LF.LR.
    LF_LLR_OUT=${SUBJECT_LF_DIR}/${SUBJECT}_LF.LLR.
    RF_LR_OUT=${SUBJECT_RF_DIR}/${SUBJECT}_RF.LR.
    RF_LLR_OUT=${SUBJECT_RF_DIR}/${SUBJECT}_RF.LLR.

    
    echo "LOCATED THE FOLLOWING FILES"
    echo ${SUBJECT_LF_LR_YAS}
    echo ${SUBJECT_LF_LLR_YAS}
    echo ${SUBJECT_RF_LR_YAS}
    echo ${SUBJECT_RF_LLR_YAS}
    echo ${SUBJECT_LF_LR_ANAT}
    echo ${SUBJECT_LF_LLR_ANAT}
    echo ${SUBJECT_RF_LR_ANAT}
    echo ${SUBJECT_RF_LLR_ANAT}
    
    ########## GUASS CURVE
    echo "***************************************************************************"
    echo "CALCULATING GUASS CURVE"
    echo "***************************************************************************"
    wb_command -surface-curvature ${SUBJECT_LF_LR_YAS} -gauss ${LF_LR_OUT}LYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}LYAS.gauss_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_LF_LLR_YAS} -gauss ${LF_LLR_OUT}LYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}LYAS.gauss_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LR_YAS} -gauss ${RF_LR_OUT}RYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}RYAS.gauss_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LLR_YAS} -gauss ${RF_LLR_OUT}RYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}RYAS.gauss_curve.func.gii"

    wb_command -surface-curvature ${SUBJECT_LF_LR_ANAT} -gauss ${LF_LR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}ANAT.gauss_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_LF_LLR_ANAT} -gauss ${LF_LLR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}ANAT.gauss_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LR_ANAT} -gauss ${RF_LR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}ANAT.gauss_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LLR_ANAT} -gauss ${RF_LLR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}ANAT.gauss_curve.func.gii"

    ########## MEAN CURVE
    echo "***************************************************************************"
    echo "CALCULATING MEAN CURVE"
    echo "***************************************************************************"
    wb_command -surface-curvature ${SUBJECT_LF_LR_YAS} -mean ${LF_LR_OUT}LYAS.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}LYAS.mean_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_LF_LLR_YAS} -mean ${LF_LLR_OUT}LYAS.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}LYAS.mean_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LR_YAS} -mean ${RF_LR_OUT}RYAS.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}RYAS.mean_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LLR_YAS} -mean ${RF_LLR_OUT}RYAS.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}RYAS.mean_curve.func.gii"

    wb_command -surface-curvature ${SUBJECT_LF_LR_ANAT} -mean ${LF_LR_OUT}ANAT.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}ANAT.mean_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_LF_LLR_ANAT} -mean ${LF_LLR_OUT}ANAT.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}ANAT.mean_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LR_ANAT} -mean ${RF_LR_OUT}ANAT.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}ANAT.mean_curve.func.gii"
    wb_command -surface-curvature ${SUBJECT_RF_LLR_ANAT} -mean ${RF_LLR_OUT}ANAT.mean_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}ANAT.mean_curve.func.gii"

    ########## KMAX
    echo "***************************************************************************"
    echo "CALCULATING KMAX"
    echo "***************************************************************************"
    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${LF_LR_OUT}LYAS.kmax.func.gii -var KH ${LF_LR_OUT}LYAS.mean_curve.func.gii -var KG ${LF_LR_OUT}LYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}LYAS.kmax.func.gii"
    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${LF_LLR_OUT}LYAS.kmax.func.gii -var KH ${LF_LLR_OUT}LYAS.mean_curve.func.gii -var KG ${LF_LLR_OUT}LYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}LYAS.kmax.func.gii"
    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${RF_LR_OUT}RYAS.kmax.func.gii -var KH ${RF_LR_OUT}RYAS.mean_curve.func.gii -var KG ${RF_LR_OUT}RYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}RYAS.kmax.func.gii"
    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${RF_LLR_OUT}RYAS.kmax.func.gii -var KH ${RF_LLR_OUT}RYAS.mean_curve.func.gii -var KG ${RF_LLR_OUT}RYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}RYAS.kmax.func.gii"

    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${LF_LR_OUT}ANAT.kmax.func.gii -var KH ${LF_LR_OUT}ANAT.mean_curve.func.gii -var KG ${LF_LR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}ANAT.kmax.func.gii"
    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${LF_LLR_OUT}ANAT.kmax.func.gii -var KH ${LF_LLR_OUT}ANAT.mean_curve.func.gii -var KG ${LF_LLR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}ANAT.kmax.func.gii"
    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${RF_LR_OUT}ANAT.kmax.func.gii -var KH ${RF_LR_OUT}ANAT.mean_curve.func.gii -var KG ${RF_LR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}ANAT.kmax.func.gii"
    wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${RF_LLR_OUT}ANAT.kmax.func.gii -var KH ${RF_LLR_OUT}ANAT.mean_curve.func.gii -var KG ${RF_LLR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}ANAT.kmax.func.gii"

    ########## KMIN
    echo "***************************************************************************"
    echo "CALCULATING KMIN"
    echo "***************************************************************************"
    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${LF_LR_OUT}LYAS.kmin.func.gii -var KH ${LF_LR_OUT}LYAS.mean_curve.func.gii -var KG ${LF_LR_OUT}LYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}LYAS.kmin.func.gii"
    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${LF_LLR_OUT}LYAS.kmin.func.gii -var KH ${LF_LLR_OUT}LYAS.mean_curve.func.gii -var KG ${LF_LLR_OUT}LYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}LYAS.kmin.func.gii"
    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${RF_LR_OUT}RYAS.kmin.func.gii -var KH ${RF_LR_OUT}RYAS.mean_curve.func.gii -var KG ${RF_LR_OUT}RYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}RYAS.kmin.func.gii"
    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${RF_LLR_OUT}RYAS.kmin.func.gii -var KH ${RF_LLR_OUT}RYAS.mean_curve.func.gii -var KG ${RF_LLR_OUT}RYAS.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}RYAS.kmin.func.gii"

    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${LF_LR_OUT}ANAT.kmin.func.gii -var KH ${LF_LR_OUT}ANAT.mean_curve.func.gii -var KG ${LF_LR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}ANAT.kmin.func.gii"
    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${LF_LLR_OUT}ANAT.kmin.func.gii -var KH ${LF_LLR_OUT}ANAT.mean_curve.func.gii -var KG ${LF_LLR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}ANAT.kmin.func.gii"
    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${RF_LR_OUT}ANAT.kmin.func.gii -var KH ${RF_LR_OUT}ANAT.mean_curve.func.gii -var KG ${RF_LR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}ANAT.kmin.func.gii"
    wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${RF_LLR_OUT}ANAT.kmin.func.gii -var KH ${RF_LLR_OUT}ANAT.mean_curve.func.gii -var KG ${RF_LLR_OUT}ANAT.gauss_curve.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}ANAT.kmin.func.gii"

    ########## K1
    echo "***************************************************************************"
    echo "CALCULATING K1"
    echo "***************************************************************************"
    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${LF_LR_OUT}LYAS.K1.func.gii -var Kmax ${LF_LR_OUT}LYAS.kmax.func.gii -var Kmin ${LF_LR_OUT}LYAS.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}LYAS.K1.func.gii"
    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${LF_LLR_OUT}LYAS.K1.func.gii -var Kmax ${LF_LLR_OUT}LYAS.kmax.func.gii -var Kmin ${LF_LLR_OUT}LYAS.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}LYAS.K1.func.gii"
    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${RF_LR_OUT}RYAS.K1.func.gii -var Kmax ${RF_LR_OUT}RYAS.kmax.func.gii -var Kmin ${RF_LR_OUT}RYAS.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}RYAS.K1.func.gii"
    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${RF_LLR_OUT}RYAS.K1.func.gii -var Kmax ${RF_LLR_OUT}RYAS.kmax.func.gii -var Kmin ${RF_LLR_OUT}RYAS.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}RYAS.K1.func.gii"

    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${LF_LR_OUT}ANAT.K1.func.gii -var Kmax ${LF_LR_OUT}ANAT.kmax.func.gii -var Kmin ${LF_LR_OUT}ANAT.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}ANAT.K1.func.gii"
    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${LF_LLR_OUT}ANAT.K1.func.gii -var Kmax ${LF_LLR_OUT}ANAT.kmax.func.gii -var Kmin ${LF_LLR_OUT}ANAT.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}ANAT.K1.func.gii"
    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${RF_LR_OUT}ANAT.K1.func.gii -var Kmax ${RF_LR_OUT}ANAT.kmax.func.gii -var Kmin ${RF_LR_OUT}ANAT.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}ANAT.K1.func.gii"
    wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${RF_LLR_OUT}ANAT.K1.func.gii -var Kmax ${RF_LLR_OUT}ANAT.kmax.func.gii -var Kmin ${RF_LLR_OUT}ANAT.kmin.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}ANAT.K1.func.gii"

    ########## REMOVE NAN FROM K1
    echo "***************************************************************************"
    echo "REMOVING NAN FROM K1"
    echo "***************************************************************************"
    wb_command -gifti-convert ASCII ${LF_LR_OUT}LYAS.K1.func.gii ${LF_LR_OUT}LYAS.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${LF_LR_OUT}LYAS.K1.ASCII.func.gii > ${LF_LR_OUT}LYAS.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}LYAS.K1.CORRECTED.func.gii"
    wb_command -gifti-convert ASCII ${LF_LLR_OUT}LYAS.K1.func.gii ${LF_LLR_OUT}LYAS.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${LF_LLR_OUT}LYAS.K1.ASCII.func.gii > ${LF_LLR_OUT}LYAS.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}LYAS.K1.CORRECTED.func.gii"
    wb_command -gifti-convert ASCII ${RF_LR_OUT}RYAS.K1.func.gii ${RF_LR_OUT}RYAS.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${RF_LR_OUT}RYAS.K1.ASCII.func.gii > ${RF_LR_OUT}RYAS.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}RYAS.K1.CORRECTED.func.gii"
    wb_command -gifti-convert ASCII ${RF_LLR_OUT}RYAS.K1.func.gii ${RF_LLR_OUT}RYAS.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${RF_LLR_OUT}RYAS.K1.ASCII.func.gii > ${RF_LLR_OUT}RYAS.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}RYAS.K1.CORRECTED.func.gii"

    wb_command -gifti-convert ASCII ${LF_LR_OUT}ANAT.K1.func.gii ${LF_LR_OUT}ANAT.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${LF_LR_OUT}ANAT.K1.ASCII.func.gii > ${LF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LR_OUT}ANAT.K1.CORRECTED.func.gii"
    wb_command -gifti-convert ASCII ${LF_LLR_OUT}ANAT.K1.func.gii ${LF_LLR_OUT}ANAT.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${LF_LLR_OUT}ANAT.K1.ASCII.func.gii > ${LF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${LF_LLR_OUT}ANAT.K1.CORRECTED.func.gii"
    wb_command -gifti-convert ASCII ${RF_LR_OUT}ANAT.K1.func.gii ${RF_LR_OUT}ANAT.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${RF_LR_OUT}ANAT.K1.ASCII.func.gii > ${RF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LR_OUT}ANAT.K1.CORRECTED.func.gii"
    wb_command -gifti-convert ASCII ${RF_LLR_OUT}ANAT.K1.func.gii ${RF_LLR_OUT}ANAT.K1.ASCII.func.gii
    sed 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${RF_LLR_OUT}ANAT.K1.ASCII.func.gii > ${RF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETE, SAVED AT: ${RF_LLR_OUT}ANAT.K1.CORRECTED.func.gii"

    ########## SPLIT SULCI AND GYRI
    echo "***************************************************************************"
    echo "SEPERATING SULCI"
    echo "***************************************************************************"
    wb_command -metric-math '(K1*(K1<0))' ${LF_LR_OUT}LYAS.K1.sulci.func.gii -var K1 ${LF_LR_OUT}LYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LR_OUT}LYAS.K1.sulci.func.gii"
    wb_command -metric-math '(K1*(K1<0))' ${LF_LLR_OUT}LYAS.K1.sulci.func.gii -var K1 ${LF_LLR_OUT}LYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LLR_OUT}LYAS.K1.sulci.func.gii"
    wb_command -metric-math '(K1*(K1<0))' ${RF_LR_OUT}RYAS.K1.sulci.func.gii -var K1 ${RF_LR_OUT}RYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LR_OUT}RYAS.K1.sulci.func.gii"
    wb_command -metric-math '(K1*(K1<0))' ${RF_LLR_OUT}RYAS.K1.sulci.func.gii -var K1 ${RF_LLR_OUT}RYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LLR_OUT}RYAS.K1.sulci.func.gii"

    wb_command -metric-math '(K1*(K1<0))' ${LF_LR_OUT}ANAT.K1.sulci.func.gii -var K1 ${LF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LR_OUT}ANAT.K1.sulci.func.gii"
    wb_command -metric-math '(K1*(K1<0))' ${LF_LLR_OUT}ANAT.K1.sulci.func.gii -var K1 ${LF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LLR_OUT}ANAT.K1.sulci.func.gii"
    wb_command -metric-math '(K1*(K1<0))' ${RF_LR_OUT}ANAT.K1.sulci.func.gii -var K1 ${RF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LR_OUT}ANAT.K1.sulci.func.gii"
    wb_command -metric-math '(K1*(K1<0))' ${RF_LLR_OUT}ANAT.K1.sulci.func.gii -var K1 ${RF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LLR_OUT}ANAT.K1.sulci.func.gii"

    echo "***************************************************************************"
    echo "SEPERATING GYRI"
    echo "***************************************************************************"
    wb_command -metric-math '(K1*(K1>0))' ${LF_LR_OUT}LYAS.K1.gyri.func.gii -var K1 ${LF_LR_OUT}LYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LR_OUT}LYAS.K1.gyri.func.gii"
    wb_command -metric-math '(K1*(K1>0))' ${LF_LLR_OUT}LYAS.K1.gyri.func.gii -var K1 ${LF_LLR_OUT}LYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LLR_OUT}LYAS.K1.gyri.func.gii"
    wb_command -metric-math '(K1*(K1>0))' ${RF_LR_OUT}RYAS.K1.gyri.func.gii -var K1 ${RF_LR_OUT}RYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LR_OUT}RYAS.K1.gyri.func.gii"
    wb_command -metric-math '(K1*(K1>0))' ${RF_LLR_OUT}RYAS.K1.gyri.func.gii -var K1 ${RF_LLR_OUT}RYAS.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LLR_OUT}RYAS.K1.gyri.func.gii"

    wb_command -metric-math '(K1*(K1>0))' ${LF_LR_OUT}ANAT.K1.gyri.func.gii -var K1 ${LF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LR_OUT}ANAT.K1.gyri.func.gii"
    wb_command -metric-math '(K1*(K1>0))' ${LF_LLR_OUT}ANAT.K1.gyri.func.gii -var K1 ${LF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LLR_OUT}ANAT.K1.gyri.func.gii"
    wb_command -metric-math '(K1*(K1>0))' ${RF_LR_OUT}ANAT.K1.gyri.func.gii -var K1 ${RF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LR_OUT}ANAT.K1.gyri.func.gii"
    wb_command -metric-math '(K1*(K1>0))' ${RF_LLR_OUT}ANAT.K1.gyri.func.gii -var K1 ${RF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LLR_OUT}ANAT.K1.gyri.func.gii"

    ########## DIFFERENCE MAP
    wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${LF_LR_OUT}diff.sulci.func.gii -var K1_1 ${LF_LR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 {LF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LR_OUT}diff.sulci.func.gii"
    wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${LF_LR_OUT}diff.gyri.func.gii -var K1_1 ${LF_LR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 {LF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LR_OUT}diff.gyri.func.gii"
    wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${LF_LLR_OUT}diff.sulci.func.gii -var K1_1 ${LF_LLR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 {LF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LLR_OUT}diff.sulci.func.gii"
    wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${LF_LLR_OUT}diff.gyri.func.gii -var K1_1 ${LF_LLR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 {LF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${LF_LLR_OUT}diff.gyri.func.gii"
    wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${RF_LR_OUT}diff.sulci.func.gii -var K1_1 ${RF_LR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 ${RF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LR_OUT}diff.sulci.func.gii"
    wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${RF_LR_OUT}diff.gyri.func.gii -var K1_1 ${RF_LR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 ${RF_LR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LR_OUT}diff.gyri.func.gii"
    wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${RF_LLR_OUT}diff.sulci.func.gii -var K1_1 ${RF_LLR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 ${RF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LLR_OUT}diff.sulci.func.gii"
    wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${RF_LLR_OUT}diff.gyri.func.gii -var K1_1 ${RF_LLR_OUT}LYAS.K1.CORRECTED.func.gii -var K1_2 ${RF_LLR_OUT}ANAT.K1.CORRECTED.func.gii
    echo "COMPLETED, SAVED AT: ${RF_LLR_OUT}diff.gyri.func.gii"
done

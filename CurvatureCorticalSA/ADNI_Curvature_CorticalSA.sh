#!/bin/bash

########## DEFINE VARIABLES

###### DO NOT CHANGE THESE
CSV_HEADINGS="SUBJECT_ID,TIME_POINT,R_CORTICAL_SA,L_CORTICAL_SA,R_MEAN_GYRI,L_MEAN_GYRI,R_MEAN_SULCI,L_MEAN_SULCI,R_K2_VARIANCE,L_K2_VARIANCE" # headings of csv file
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the csv file so multiple can be run keeping data seperate
LOG_OUTPUT=${HOME}/Scripts/MyScripts/logs/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

###### CAN BE CHANGED BY USER ONLY CHANGE THE PARTS THAT ARE NOT IN {} UNLESS YOU KNOW WHAT YOU ARE DOING
DATASET=/N/project/aMSM_AD/ADNI/HCP/MSM # Folder containing subject data
OUTPUT_DIR=/N/project/aMSM_AD/ADNI/HCP/POST_PROCESSING # output location for script
CP_OUTPUT=${OUTPUT_DIR}/ADNI_datasheet-CP.csv # name and location of initial csv output file at MaxCP
ANAT_OUTPUT=${OUTPUT_DIR}/ADNI_datasheet-ANAT.csv # name and location of initial csv output file at MaxANAT
CP_CORRECTED_OUTPUT=${OUTPUT_DIR}/ADNI_datasheet-CP-no_dups.csv # name and location of final csv output at MaxCP
ANAT_CORRECTED_OUTPUT=${OUTPUT_DIR}/ADNI_datasheet-ANAT-no_dups.csv # name and location of final csv output at MaxANAT
DUPLICATE_CSV=${OUTPUT_DIR}/dups.csv #duplicate file to be generated then deleted

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## CREATE CSV FILE
echo "***************************************************************************"
echo "CREATING OUTPUT FILE"
echo "***************************************************************************"
mkdir -p ${OUTPUT_DIR}
if [ ! -e "${OUTPUT}" ]; then
    echo ${CSV_HEADINGS} > ${CP_OUTPUT}
    echo ${CSV_HEADINGS} > ${ANAT_OUTPUT}
fi
echo "OUTPUTS CREATED AT ${CP_OUTPUT} and ${ANAT_OUTPUT}"

########## FIND SUBJECTS
echo
echo "***************************************************************************"
echo "FINDING DATA"
echo "***************************************************************************"
DIRECTORIES=($(ls ${DATASET}))
echo "DATA FOUND: "

for DIR in ${DIRECTORIES[@]}; do
    echo ${DIR}
done

for DIR in ${DIRECTORIES[@]}; do
    ########## EXTRACT SUBJECT NUMBER AND TIME POINTS
    SUBJECT=$(echo ${DIR} | cut -d "_" -f 1)
    TIME1=$(echo ${DIR} | cut -d "_" -f 2)
    TIME2=$(echo ${DIR} | cut -d "_" -f 4)

    if [ ${TIME1} == "BL" ]; then
        ########## LOCATE FILES
        echo
        echo "***************************************************************************"
        echo "BEGIN PROCESSING FOR ${SUBJECT} ${TIME1} TO ${TIME2}"
        echo "***************************************************************************"
        SUBJECT_LYS_CP=${DATASET}/${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.LYAS.CPgrid.surf.gii
        SUBJECT_RYS_CP=${DATASET}/${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.RYAS.CPgrid.surf.gii
        SUBJECT_LOS_CP=${DATASET}/${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.anat.CPgrid.reg.surf.gii
        SUBJECT_ROS_CP=${DATASET}/${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.anat.CPgrid.reg.surf.gii

        SUBJECT_LYS_ANAT=${DATASET}/${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.LYAS.ANATgrid.surf.gii
        SUBJECT_RYS_ANAT=${DATASET}/${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.RYAS.ANATgrid.surf.gii
        SUBJECT_LOS_ANAT=${DATASET}/${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.anat.ANATgrid.reg.surf.gii
        SUBJECT_ROS_ANAT=${DATASET}/${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.anat.ANATgrid.reg.surf.gii

        L_CP_OUT=${DATASET}/${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.CPgrid.
        L_ANAT_OUT=${DATASET}/${DIR}/${SUBJECT}_L_${TIME1}-${TIME2}.ANATgrid.
        R_CP_OUT=${DATASET}/${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.CPgrid.
        R_ANAT_OUT=${DATASET}/${DIR}/${SUBJECT}_R_${TIME1}-${TIME2}.ANATgrid.
        echo "LOCATED FOLLOWING FILES"
        echo ${SUBJECT_LYS_CP}
        echo ${SUBJECT_RYS_CP}
        echo ${SUBJECT_LOS_CP}
        echo ${SUBJECT_ROS_CP}
        echo ${SUBJECT_LYS_ANAT}
        echo ${SUBJECT_RYS_ANAT}
        echo ${SUBJECT_LOS_ANAT}
        echo ${SUBJECT_ROS_ANAT}

        ########## CALCULATE CORTICAL SA
        echo
        echo "***************************************************************************"
        echo "BEGIN CALCULATING CORTICAL SA"
        echo "***************************************************************************"
        ######## CALCULATE VERTEX SURFACE AREA
        echo
        echo "CALCULATING VERTEX SURFACE AREA"
        ###### CPGRID YOUNGER
        wb_command -surface-vertex-areas ${SUBJECT_LYS_CP} ${L_CP_OUT}${TIME1}.surface-vertex-area.func.gii # LEFT HEMISPHERE YOUNGER SURFACE VERTEX AREA CPGRID
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.surface-vertex-area.func.gii"
        wb_command -surface-vertex-areas ${SUBJECT_RYS_CP} ${R_CP_OUT}${TIME1}.surface-vertex-area.func.gii # RIGHT HEMISPHERE YOUNGER SURFACE VERTEX AREA CPGRID
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.surface-vertex-area.func.gii"

        ###### CPGRID OLDER
        wb_command -surface-vertex-areas ${SUBJECT_LOS_CP} ${L_CP_OUT}${TIME2}.surface-vertex-area.func.gii # LEFT HEMISPHERE OLDER SURFACE VERTEX AREA CPGRID
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.surface-vertex-area.func.gii"
        wb_command -surface-vertex-areas ${SUBJECT_ROS_CP} ${R_CP_OUT}${TIME2}.surface-vertex-area.func.gii # RIGHT HEMISPHERE OLDER SURFACE VERTEX AREA CPGRID
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.surface-vertex-area.func.gii"

        ###### ANATGRID YOUNGER
        wb_command -surface-vertex-areas ${SUBJECT_LYS_ANAT} ${L_ANAT_OUT}${TIME1}.surface-vertex-area.func.gii # LEFT HEMISPHERE YOUNGER SURFACE VERTEX AREA ANATGRID
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.surface-vertex-area.func.gii"
        wb_command -surface-vertex-areas ${SUBJECT_RYS_ANAT} ${R_ANAT_OUT}${TIME1}.surface-vertex-area.func.gii # RIGHT HEMISPHERE YOUNGER SURFACE VERTEX AREA ANATGRID
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.surface-vertex-area.func.gii"

        ###### ANATGRID OLDER
        wb_command -surface-vertex-areas ${SUBJECT_LOS_ANAT} ${L_ANAT_OUT}${TIME2}.surface-vertex-area.func.gii # LEFT HEMISPHERE OLDER SURFACE VERTEX AREA ANATGRID
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.surface-vertex-area.func.gii"
        wb_command -surface-vertex-areas ${SUBJECT_ROS_ANAT} ${R_ANAT_OUT}${TIME2}.surface-vertex-area.func.gii # RIGHT HEMISPHERE OLDER SURFACE VERTEX AREA ANATGRID
        echo "ANATGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.surface-vertex-area.func.gii"

        ######## USE METRIC STATS SUM TO CALCULATE TOTAL CORTICAL SA
        echo
        echo "CALCULATING TOTAL CORTICAL SA"
        ###### CPGRID YOUNGER
        CP_LY_CORTICAL_SA=$(wb_command -metric-stats ${L_CP_OUT}${TIME1}.surface-vertex-area.func.gii -reduce SUM)
        CP_RY_CORTICAL_SA=$(wb_command -metric-stats ${R_CP_OUT}${TIME1}.surface-vertex-area.func.gii -reduce SUM)
        echo "CP LEFT YOUNGER CORTICAL SA=${CP_LY_CORTICAL_SA}"
        echo "CP RIGHT YOUNGER CORTICAL SA=${CP_RY_CORTICAL_SA}"

        ###### CPGRID OLDER
        CP_LO_CORTICAL_SA=$(wb_command -metric-stats ${L_CP_OUT}${TIME2}.surface-vertex-area.func.gii -reduce SUM)
        CP_RO_CORTICAL_SA=$(wb_command -metric-stats ${R_CP_OUT}${TIME2}.surface-vertex-area.func.gii -reduce SUM)
        echo "CP LEFT OLDER CORTICAL SA=${CP_LY_CORTICAL_SA}"
        echo "CP RIGHT OLDER CORTICAL SA=${CP_RY_CORTICAL_SA}"

        ###### ANATGRID YOUNGER
        ANAT_LY_CORTICAL_SA=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME1}.surface-vertex-area.func.gii -reduce SUM)
        ANAT_RY_CORTICAL_SA=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME1}.surface-vertex-area.func.gii -reduce SUM)
        echo "ANAT LEFT YOUNGER CORTICAL SA=${ANAT_LY_CORTICAL_SA}"
        echo "ANAT RIGHT YOUNGER CORTICAL SA=${ANAT_RY_CORTICAL_SA}"

        ###### ANATGRID OLDER
        ANAT_LO_CORTICAL_SA=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME2}.surface-vertex-area.func.gii -reduce SUM)
        ANAT_RO_CORTICAL_SA=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME2}.surface-vertex-area.func.gii -reduce SUM)
        echo "ANAT LEFT YOUNGER CORTICAL SA=${ANAT_LO_CORTICAL_SA}"
        echo "ANAT RIGHT YOUNGER CORTICAL SA=${ANAT_RO_CORTICAL_SA}"

        ########## CALCULATE MEAN GYRI, MEAN SULCI AND K2 VARRIANCE
        echo
        echo "***************************************************************************"
        echo "BEGIN CALCULATING K1 and K2"
        echo "***************************************************************************"
        ######## CALCULATE GAUSS CURVE
        echo
        echo "CALCULATING GAUSS CURVE"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        wb_command -surface-curvature ${SUBJECT_LYS_CP} -gauss ${L_CP_OUT}${TIME1}.gauss_curve.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.gauss_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_RYS_CP} -gauss ${R_CP_OUT}${TIME1}.gauss_curve.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.gauss_curve.func.gii"

        ###### CPGRID OLDER
        wb_command -surface-curvature ${SUBJECT_LOS_CP} -gauss ${L_CP_OUT}${TIME2}.gauss_curve.func.gii
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME2}.gauss_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_ROS_CP} -gauss ${R_CP_OUT}${TIME2}.gauss_curve.func.gii
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME2}.gauss_curve.func.gii"

        ###### ANAT GRID YOUNGER
        wb_command -surface-curvature ${SUBJECT_LYS_ANAT} -gauss ${L_ANAT_OUT}${TIME1}.gauss_curve.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.gauss_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_RYS_ANAT} -gauss ${R_ANAT_OUT}${TIME1}.gauss_curve.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.gauss_curve.func.gii"

        ###### ANAT GRID OLDER
        wb_command -surface-curvature ${SUBJECT_LOS_ANAT} -gauss ${L_ANAT_OUT}${TIME2}.gauss_curve.func.gii
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.gauss_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_ROS_ANAT} -gauss ${R_ANAT_OUT}${TIME2}.gauss_curve.func.gii
        echo "ANATGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.gauss_curve.func.gii"

        ######## CALCULATE MEAN CURVE
        echo
        echo "CALCULATING MEAN CURVE"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        wb_command -surface-curvature ${SUBJECT_LYS_CP} -mean ${L_CP_OUT}${TIME1}.mean_curve.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.mean_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_RYS_CP} -mean ${R_CP_OUT}${TIME1}.mean_curve.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.mean_curve.func.gii"

        ###### CPGRID OLDER
        wb_command -surface-curvature ${SUBJECT_LOS_CP} -mean ${L_CP_OUT}${TIME2}.mean_curve.func.gii
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME2}.mean_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_ROS_CP} -mean ${R_CP_OUT}${TIME2}.mean_curve.func.gii
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME2}.mean_curve.func.gii"

        ###### ANAT GRID YOUNGER
        wb_command -surface-curvature ${SUBJECT_LYS_ANAT} -mean ${L_ANAT_OUT}${TIME1}.mean_curve.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.mean_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_RYS_ANAT} -mean ${R_ANAT_OUT}${TIME1}.mean_curve.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.mean_curve.func.gii"

        ###### ANAT GRID OLDER
        wb_command -surface-curvature ${SUBJECT_LOS_ANAT} -mean ${L_ANAT_OUT}${TIME2}.mean_curve.func.gii
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.mean_curve.func.gii"
        wb_command -surface-curvature ${SUBJECT_ROS_ANAT} -mean ${R_ANAT_OUT}${TIME2}.mean_curve.func.gii
        echo "ANATGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.mean_curve.func.gii"

        ######## KMAX
        echo
        echo "CALCULATING KMAX"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${L_CP_OUT}${TIME1}.kmax.func.gii -fixnan 0 -var KH ${L_CP_OUT}${TIME1}.mean_curve.func.gii -var KG ${L_CP_OUT}${TIME1}.gauss_curve.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.kmax.func.gii"
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${R_CP_OUT}${TIME1}.kmax.func.gii -fixnan 0 -var KH ${R_CP_OUT}${TIME1}.mean_curve.func.gii -var KG ${R_CP_OUT}${TIME1}.gauss_curve.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.kmax.func.gii"

        ###### CPGRID OLDER
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${L_CP_OUT}${TIME2}.kmax.func.gii -fixnan 0 -var KH ${L_CP_OUT}${TIME2}.mean_curve.func.gii -var KG ${L_CP_OUT}${TIME2}.gauss_curve.func.gii
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME2}.kmax.func.gii"
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${R_CP_OUT}${TIME2}.kmax.func.gii -fixnan 0 -var KH ${R_CP_OUT}${TIME2}.mean_curve.func.gii -var KG ${R_CP_OUT}${TIME2}.gauss_curve.func.gii
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME2}.kmax.func.gii"

        ###### ANATGRID YOUNGER
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${L_ANAT_OUT}${TIME1}.kmax.func.gii -fixnan 0 -var KH ${L_ANAT_OUT}${TIME1}.mean_curve.func.gii -var KG ${L_ANAT_OUT}${TIME1}.gauss_curve.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.kmax.func.gii"
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${R_ANAT_OUT}${TIME1}.kmax.func.gii -fixnan 0 -var KH ${R_ANAT_OUT}${TIME1}.mean_curve.func.gii -var KG ${R_ANAT_OUT}${TIME1}.gauss_curve.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.kmax.func.gii"

        ###### ANATGRID OLDER
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${L_ANAT_OUT}${TIME2}.kmax.func.gii -fixnan 0 -var KH ${L_ANAT_OUT}${TIME2}.mean_curve.func.gii -var KG ${L_ANAT_OUT}${TIME2}.gauss_curve.func.gii
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.kmax.func.gii"
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${R_ANAT_OUT}${TIME2}.kmax.func.gii -fixnan 0 -var KH ${R_ANAT_OUT}${TIME2}.mean_curve.func.gii -var KG ${R_ANAT_OUT}${TIME2}.gauss_curve.func.gii
        echo "ANATGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.kmax.func.gii"
        
        ######## KMIN
        echo
        echo "CALCULATING KMIN"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${L_CP_OUT}${TIME1}.kmin.func.gii -fixnan 0 -var KH ${L_CP_OUT}${TIME1}.mean_curve.func.gii -var KG ${L_CP_OUT}${TIME1}.gauss_curve.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.kmin.func.gii"
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${R_CP_OUT}${TIME1}.kmin.func.gii -fixnan 0 -var KH ${R_CP_OUT}${TIME1}.mean_curve.func.gii -var KG ${R_CP_OUT}${TIME1}.gauss_curve.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.kmin.func.gii"

        ###### CPGRID OLDER
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${L_CP_OUT}${TIME2}.kmin.func.gii -fixnan 0 -var KH ${L_CP_OUT}${TIME2}.mean_curve.func.gii -var KG ${L_CP_OUT}${TIME2}.gauss_curve.func.gii
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME2}.kmin.func.gii"
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${R_CP_OUT}${TIME2}.kmin.func.gii -fixnan 0 -var KH ${R_CP_OUT}${TIME2}.mean_curve.func.gii -var KG ${R_CP_OUT}${TIME2}.gauss_curve.func.gii
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME2}.kmin.func.gii"

        ###### ANATGRID YOUNGER
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${L_ANAT_OUT}${TIME1}.kmin.func.gii -fixnan 0 -var KH ${L_ANAT_OUT}${TIME1}.mean_curve.func.gii -var KG ${L_ANAT_OUT}${TIME1}.gauss_curve.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.kmin.func.gii"
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${R_ANAT_OUT}${TIME1}.kmin.func.gii -fixnan 0 -var KH ${R_ANAT_OUT}${TIME1}.mean_curve.func.gii -var KG ${R_ANAT_OUT}${TIME1}.gauss_curve.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.kmin.func.gii"

        ###### ANATGRID OLDER
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${L_ANAT_OUT}${TIME2}.kmin.func.gii -fixnan 0 -var KH ${L_ANAT_OUT}${TIME2}.mean_curve.func.gii -var KG ${L_ANAT_OUT}${TIME2}.gauss_curve.func.gii
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.kmin.func.gii"
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${R_ANAT_OUT}${TIME2}.kmin.func.gii -fixnan 0 -var KH ${R_ANAT_OUT}${TIME2}.mean_curve.func.gii -var KG ${R_ANAT_OUT}${TIME2}.gauss_curve.func.gii
        echo "ANATGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.kmin.func.gii"
        
        ######## K1
        echo
        echo "CALCULATING K1"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${L_CP_OUT}${TIME1}.K1.func.gii -fixnan 0 -var Kmax ${L_CP_OUT}${TIME1}.kmax.func.gii -var Kmin ${L_CP_OUT}${TIME1}.kmin.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.K1.func.gii"
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${R_CP_OUT}${TIME1}.K1.func.gii -fixnan 0 -var Kmax ${R_CP_OUT}${TIME1}.kmax.func.gii -var Kmin ${R_CP_OUT}${TIME1}.kmin.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.K1.func.gii"

        ###### CPGRID OLDER
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${L_CP_OUT}${TIME2}.K1.func.gii -fixnan 0 -var Kmax ${L_CP_OUT}${TIME2}.kmax.func.gii -var Kmin ${L_CP_OUT}${TIME2}.kmin.func.gii
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME2}.K1.func.gii"
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${R_CP_OUT}${TIME2}.K1.func.gii -fixnan 0 -var Kmax ${R_CP_OUT}${TIME2}.kmax.func.gii -var Kmin ${R_CP_OUT}${TIME2}.kmin.func.gii
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME2}.K1.func.gii"

        ###### ANATGRID YOUNGER
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${L_ANAT_OUT}${TIME1}.K1.func.gii -fixnan 0 -var Kmax ${L_ANAT_OUT}${TIME1}.kmax.func.gii -var Kmin ${L_ANAT_OUT}${TIME1}.kmin.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.K1.func.gii"
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${R_ANAT_OUT}${TIME1}.K1.func.gii -fixnan 0 -var Kmax ${R_ANAT_OUT}${TIME1}.kmax.func.gii -var Kmin ${R_ANAT_OUT}${TIME1}.kmin.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.K1.func.gii"

        ###### ANATGRID OLDER
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${L_ANAT_OUT}${TIME2}.K1.func.gii -fixnan 0 -var Kmax ${L_ANAT_OUT}${TIME2}.kmax.func.gii -var Kmin ${L_ANAT_OUT}${TIME2}.kmin.func.gii
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.K1.func.gii"
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${R_ANAT_OUT}${TIME2}.K1.func.gii -fixnan 0 -var Kmax ${R_ANAT_OUT}${TIME2}.kmax.func.gii -var Kmin ${R_ANAT_OUT}${TIME2}.kmin.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.K1.func.gii"
        
        ######## K2
        echo
        echo "CALCULATING K2"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        wb_command -metric-math 'KG/K1' ${L_CP_OUT}${TIME1}.K2.func.gii -fixnan 0 -var KG ${L_CP_OUT}${TIME1}.gauss_curve.func.gii -var K1 ${L_CP_OUT}${TIME1}.K1.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.K2.func.gii"
        wb_command -metric-math 'KG/K1' ${R_CP_OUT}${TIME1}.K2.func.gii -fixnan 0 -var KG ${R_CP_OUT}${TIME1}.gauss_curve.func.gii -var K1 ${R_CP_OUT}${TIME1}.K1.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.K2.func.gii"

        ###### CPGRID OLDER
        wb_command -metric-math 'KG/K1' ${L_CP_OUT}${TIME2}.K2.func.gii -fixnan 0 -var KG ${L_CP_OUT}${TIME2}.gauss_curve.func.gii -var K1 ${L_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID OLDER LEFT HEMISPERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME2}.K2.func.gii"
        wb_command -metric-math 'KG/K1' ${R_CP_OUT}${TIME2}.K2.func.gii -fixnan 0 -var KG ${R_CP_OUT}${TIME2}.gauss_curve.func.gii -var K1 ${R_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID OLDER RIGHT HEMISPERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME2}.K2.func.gii"
        
        ###### ANATGRID YOUNGER
        wb_command -metric-math 'KG/K1' ${L_ANAT_OUT}${TIME1}.K2.func.gii -fixnan 0 -var KG ${L_ANAT_OUT}${TIME1}.gauss_curve.func.gii -var K1 ${L_ANAT_OUT}${TIME1}.K1.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.K2.func.gii"
        wb_command -metric-math 'KG/K1' ${R_ANAT_OUT}${TIME1}.K2.func.gii -fixnan 0 -var KG ${R_ANAT_OUT}${TIME1}.gauss_curve.func.gii -var K1 ${R_ANAT_OUT}${TIME1}.K1.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.K2.func.gii"
        
        ###### ANATGRID OLDER
        wb_command -metric-math 'KG/K1' ${L_ANAT_OUT}${TIME2}.K2.func.gii -fixnan 0 -var KG ${L_ANAT_OUT}${TIME2}.gauss_curve.func.gii -var K1 ${L_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID OLDER LEFT HEMISPERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.K2.func.gii"
        wb_command -metric-math 'KG/K1' ${R_ANAT_OUT}${TIME2}.K2.func.gii -fixnan 0 -var KG ${R_ANAT_OUT}${TIME2}.gauss_curve.func.gii -var K1 ${R_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID OLDER RIGHT HEMISPERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.K2.func.gii"
        
        ########## SPLIT SULCI AND GYRI
        ###### SULCI
        echo
        echo "SEPERATING SULCI"
        echo "***************************************************************************"
        #### CPGRID YOUNGER
        wb_command -metric-math '(K1*(K1<0))' ${L_CP_OUT}${TIME1}.K1.sulci.func.gii -fixnan 0 -var K1 ${L_CP_OUT}${TIME1}.K1.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.K1.sulci.func.gii"
        wb_command -metric-math '(K1*(K1<0))' ${R_CP_OUT}${TIME1}.K1.sulci.func.gii -fixnan 0 -var K1 ${R_CP_OUT}${TIME1}.K1.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.K1.sulci.func.gii"

        #### CPGRID OLDER
        wb_command -metric-math '(K1*(K1<0))' ${L_CP_OUT}${TIME2}.K1.sulci.func.gii -fixnan 0 -var K1 ${L_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.K1.sulci.func.gii"
        wb_command -metric-math '(K1*(K1<0))' ${R_CP_OUT}${TIME2}.K1.sulci.func.gii -fixnan 0 -var K1 ${R_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.K1.sulci.func.gii"

        #### ANATGRID YOUNGER
        wb_command -metric-math '(K1*(K1<0))' ${L_ANAT_OUT}${TIME1}.K1.sulci.func.gii -fixnan 0 -var K1 ${L_ANAT_OUT}${TIME1}.K1.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.K1.sulci.func.gii"
        wb_command -metric-math '(K1*(K1<0))' ${R_ANAT_OUT}${TIME1}.K1.sulci.func.gii -fixnan 0 -var K1 ${R_ANAT_OUT}${TIME1}.K1.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.K1.sulci.func.gii"

        #### ANATGRID OLDER
        wb_command -metric-math '(K1*(K1<0))' ${L_ANAT_OUT}${TIME2}.K1.sulci.func.gii -fixnan 0 -var K1 ${L_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.K1.sulci.func.gii"
        wb_command -metric-math '(K1*(K1<0))' ${R_ANAT_OUT}${TIME2}.K1.sulci.func.gii -fixnan 0 -var K1 ${R_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.K1.sulci.func.gii"

        ###### GYRI
        echo
        echo "SEPERATING GYRI"
        echo "***************************************************************************"
        #### CPGRID YOUNGER
        wb_command -metric-math '(K1*(K1>0))' ${L_CP_OUT}${TIME1}.K1.gyri.func.gii -fixnan 0 -var K1 ${L_CP_OUT}${TIME1}.K1.func.gii
        echo "CPGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_CP_OUT}${TIME1}.K1.gyri.func.gii"
        wb_command -metric-math '(K1*(K1>0))' ${R_CP_OUT}${TIME1}.K1.gyri.func.gii -fixnan 0 -var K1 ${R_CP_OUT}${TIME1}.K1.func.gii
        echo "CPGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_CP_OUT}${TIME1}.K1.gyri.func.gii"

        #### CPGRID OLDER
        wb_command -metric-math '(K1*(K1>0))' ${L_CP_OUT}${TIME2}.K1.gyri.func.gii -fixnan 0 -var K1 ${L_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.K1.gyri.func.gii"
        wb_command -metric-math '(K1*(K1>0))' ${R_CP_OUT}${TIME2}.K1.gyri.func.gii -fixnan 0 -var K1 ${R_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.K1.gyri.func.gii"

        #### ANATGRID YOUNGER
        wb_command -metric-math '(K1*(K1>0))' ${L_ANAT_OUT}${TIME1}.K1.gyri.func.gii -fixnan 0 -var K1 ${L_ANAT_OUT}${TIME1}.K1.func.gii
        echo "ANATGRID YOUNGER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME1}.K1.gyri.func.gii"
        wb_command -metric-math '(K1*(K1>0))' ${R_ANAT_OUT}${TIME1}.K1.gyri.func.gii -fixnan 0 -var K1 ${R_ANAT_OUT}${TIME1}.K1.func.gii
        echo "ANATGRID YOUNGER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME1}.K1.gyri.func.gii"

        #### ANATGRID OLDER
        wb_command -metric-math '(K1*(K1>0))' ${L_ANAT_OUT}${TIME2}.K1.gyri.func.gii -fixnan 0 -var K1 ${L_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID OLDER LEFT HEMISPHERE COMPLETE. SAVED AT ${L_ANAT_OUT}${TIME2}.K1.gyri.func.gii"
        wb_command -metric-math '(K1*(K1>0))' ${R_ANAT_OUT}${TIME2}.K1.gyri.func.gii -fixnan 0 -var K1 ${R_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID OLDER RIGHT HEMISPHERE COMPLETE. SAVED AT ${R_ANAT_OUT}${TIME2}.K1.gyri.func.gii"

        ########## MEAN GYRI
        echo
        echo "***************************************************************************"
        echo "BEGIN CALCULATING MEAN GYRI"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        CP_LY_SUM_GYRI=$(wb_command -metric-stats ${L_CP_OUT}${TIME1}.K1.gyri.func.gii -reduce SUM)
        CP_LY_COUNT_GYRI=$(wb_command -metric-stats ${L_CP_OUT}${TIME1}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        CP_LY_MEAN_GYRI=$(echo "scale=9; ${CP_LY_SUM_GYRI}/${CP_LY_COUNT_GYRI}" | bc)
        CP_LY_MEAN_GYRI=$(printf "%011.9f" ${CP_LY_MEAN_GYRI})
        echo "CPGRID LEFT YOUNGER MEAN GYRI=${CP_LY_MEAN_GYRI}"
        CP_RY_SUM_GYRI=$(wb_command -metric-stats ${R_CP_OUT}${TIME1}.K1.gyri.func.gii -reduce SUM)
        CP_RY_COUNT_GYRI=$(wb_command -metric-stats ${R_CP_OUT}${TIME1}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        CP_RY_MEAN_GYRI=$(echo "scale=9; ${CP_RY_SUM_GYRI}/${CP_RY_COUNT_GYRI}" | bc)
        CP_RY_MEAN_GYRI=$(printf "%011.9f" ${CP_RY_MEAN_GYRI})
        echo "CPGRID RIGHT YOUNGER MEAN GYRI=${CP_RY_MEAN_GYRI}"

        ###### CPGRID OLDER
        CP_LO_SUM_GYRI=$(wb_command -metric-stats ${L_CP_OUT}${TIME2}.K1.gyri.func.gii -reduce SUM)
        CP_LO_COUNT_GYRI=$(wb_command -metric-stats ${L_CP_OUT}${TIME2}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        CP_LO_MEAN_GYRI=$(echo "scale=9; ${CP_LO_SUM_GYRI}/${CP_LO_COUNT_GYRI}" | bc)
        CP_LO_MEAN_GYRI=$(printf "%011.9f" ${CP_LO_MEAN_GYRI})
        echo "CPGRID LEFT OLDER MEAN GYRI=${CP_LO_MEAN_GYRI}"
        CP_RO_SUM_GYRI=$(wb_command -metric-stats ${R_CP_OUT}${TIME2}.K1.gyri.func.gii -reduce SUM)
        CP_RO_COUNT_GYRI=$(wb_command -metric-stats ${R_CP_OUT}${TIME2}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        CP_RO_MEAN_GYRI=$(echo "scale=9; ${CP_RO_SUM_GYRI}/${CP_RO_COUNT_GYRI}" | bc)
        CP_RO_MEAN_GYRI=$(printf "%011.9f" ${CP_RO_MEAN_GYRI})
        echo "CPGRID RIGHT OLDER MEAN GYRI=${CP_RO_MEAN_GYRI}"
        
        ###### ANATGRID YOUNGER
        ANAT_LY_SUM_GYRI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME1}.K1.gyri.func.gii -reduce SUM)
        ANAT_LY_COUNT_GYRI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME1}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        ANAT_LY_MEAN_GYRI=$(echo "scale=9; ${ANAT_LY_SUM_GYRI}/${ANAT_LY_COUNT_GYRI}" | bc)
        ANAT_LY_MEAN_GYRI=$(printf "%011.9f" ${ANAT_LY_MEAN_GYRI})
        echo "ANATGRID LEFT YOUNGER MEAN GYRI=${ANAT_LY_MEAN_GYRI}"
        ANAT_RY_SUM_GYRI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME1}.K1.gyri.func.gii -reduce SUM)
        ANAT_RY_COUNT_GYRI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME1}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        ANAT_RY_MEAN_GYRI=$(echo "scale=9; ${ANAT_RY_SUM_GYRI}/${ANAT_RY_COUNT_GYRI}" | bc)
        ANAT_RY_MEAN_GYRI=$(printf "%011.9f" ${ANAT_RY_MEAN_GYRI})
        echo "ANATGRID RIGHT YOUNGER MEAN GYRI=${ANAT_RY_MEAN_GYRI}"
        
        ###### ANATGRID OLDER
        ANAT_LO_SUM_GYRI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME2}.K1.gyri.func.gii -reduce SUM)
        ANAT_LO_COUNT_GYRI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME2}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        ANAT_LO_MEAN_GYRI=$(echo "scale=9; ${ANAT_LO_SUM_GYRI}/${ANAT_LO_COUNT_GYRI}" | bc)
        ANAT_LO_MEAN_GYRI=$(printf "%011.9f" ${ANAT_LO_MEAN_GYRI})
        echo "ANATGRID LEFT OLDER MEAN GYRI=${ANAT_LO_MEAN_GYRI}"
        ANAT_RO_SUM_GYRI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME2}.K1.gyri.func.gii -reduce SUM)
        ANAT_RO_COUNT_GYRI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME2}.K1.gyri.func.gii -reduce COUNT_NONZERO)
        ANAT_RO_MEAN_GYRI=$(echo "scale=9; ${ANAT_RO_SUM_GYRI}/${ANAT_RO_COUNT_GYRI}" | bc)
        ANAT_RO_MEAN_GYRI=$(printf "%011.9f" ${ANAT_RO_MEAN_GYRI})
        echo "ANATGRID RIGHT OLDER MEAN GYRI=${ANAT_RO_MEAN_GYRI}"
        
        ########## MEAN SULCI
        echo
        echo "***************************************************************************"
        echo "BEGIN CALCULATING MEAN SULCI"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        CP_LY_SUM_SULCI=$(wb_command -metric-stats ${L_CP_OUT}${TIME1}.K1.sulci.func.gii -reduce SUM)
        CP_LY_COUNT_SULCI=$(wb_command -metric-stats ${L_CP_OUT}${TIME1}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        CP_LY_MEAN_SULCI=$(echo "scale=9; ${CP_LY_SUM_SULCI}/${CP_LY_COUNT_SULCI}" | bc)
        CP_LY_MEAN_SULCI=$(printf "%011.9f" ${CP_LY_MEAN_SULCI})
        echo "CPGRID LEFT YOUNGER MEAN SULCI=${CP_LY_MEAN_SULCI}"
        CP_RY_SUM_SULCI=$(wb_command -metric-stats ${R_CP_OUT}${TIME1}.K1.sulci.func.gii -reduce SUM)
        CP_RY_COUNT_SULCI=$(wb_command -metric-stats ${R_CP_OUT}${TIME1}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        CP_RY_MEAN_SULCI=$(echo "scale=9; ${CP_RY_SUM_SULCI}/${CP_RY_COUNT_SULCI}" | bc)
        CP_RY_MEAN_SULCI=$(printf "%011.9f" ${CP_RY_MEAN_SULCI})
        echo "CPGRID RIGHT YOUNGER MEAN SULCI=${CP_RY_MEAN_SULCI}"

        ###### CPGRID OLDER
        CP_LO_SUM_SULCI=$(wb_command -metric-stats ${L_CP_OUT}${TIME2}.K1.sulci.func.gii -reduce SUM)
        CP_LO_COUNT_SULCI=$(wb_command -metric-stats ${L_CP_OUT}${TIME2}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        CP_LO_MEAN_SULCI=$(echo "scale=9; ${CP_LO_SUM_SULCI}/${CP_LO_COUNT_SULCI}" | bc)
        CP_LO_MEAN_SULCI=$(printf "%011.9f" ${CP_LO_MEAN_SULCI})
        echo "CPGRID LEFT OLDER MEAN SULCI=${CP_LO_MEAN_SULCI}"
        CP_RO_SUM_SULCI=$(wb_command -metric-stats ${R_CP_OUT}${TIME2}.K1.sulci.func.gii -reduce SUM)
        CP_RO_COUNT_SULCI=$(wb_command -metric-stats ${R_CP_OUT}${TIME2}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        CP_RO_MEAN_SULCI=$(echo "scale=9; ${CP_RO_SUM_SULCI}/${CP_RO_COUNT_SULCI}" | bc)
        CP_RO_MEAN_SULCI=$(printf "%011.9f" ${CP_RO_MEAN_SULCI})
        echo "CPGRID RIGHT OLDER MEAN SULCI=${CP_RO_MEAN_SULCI}"
        
        ###### ANATGRID YOUNGER
        ANAT_LY_SUM_SULCI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME1}.K1.sulci.func.gii -reduce SUM)
        ANAT_LY_COUNT_SULCI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME1}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        ANAT_LY_MEAN_SULCI=$(echo "scale=9; ${ANAT_LY_SUM_SULCI}/${ANAT_LY_COUNT_SULCI}" | bc)
        ANAT_LY_MEAN_SULCI=$(printf "%011.9f" ${ANAT_LY_MEAN_SULCI})
        echo "ANATGRID LEFT YOUNGER MEAN SULCI=${ANAT_LY_MEAN_SULCI}"
        ANAT_RY_SUM_SULCI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME1}.K1.sulci.func.gii -reduce SUM)
        ANAT_RY_COUNT_SULCI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME1}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        ANAT_RY_MEAN_SULCI=$(echo "scale=9; ${ANAT_RY_SUM_SULCI}/${ANAT_RY_COUNT_SULCI}" | bc)
        ANAT_RY_MEAN_SULCI=$(printf "%011.9f" ${ANAT_RY_MEAN_SULCI})
        echo "ANATGRID RIGHT YOUNGER MEAN SULCI=${ANAT_RY_MEAN_SULCI}"
        
        ###### ANATGRID OLDER
        ANAT_LO_SUM_SULCI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME2}.K1.sulci.func.gii -reduce SUM)
        ANAT_LO_COUNT_SULCI=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME2}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        ANAT_LO_MEAN_SULCI=$(echo "scale=9; ${ANAT_LO_SUM_SULCI}/${ANAT_LO_COUNT_SULCI}" | bc)
        ANAT_LO_MEAN_SULCI=$(printf "%011.9f" ${ANAT_LO_MEAN_SULCI})
        echo "ANATGRID LEFT OLDER MEAN SULCI=${ANAT_LO_MEAN_SULCI}"
        ANAT_RO_SUM_SULCI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME2}.K1.sulci.func.gii -reduce SUM)
        ANAT_RO_COUNT_SULCI=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME2}.K1.sulci.func.gii -reduce COUNT_NONZERO)
        ANAT_RO_MEAN_SULCI=$(echo "scale=9; ${ANAT_RO_SUM_SULCI}/${ANAT_RO_COUNT_SULCI}" | bc)
        ANAT_RO_MEAN_SULCI=$(printf "%011.9f" ${ANAT_RO_MEAN_SULCI})
        echo "ANATGRID RIGHT OLDER MEAN SULCI=${ANAT_RO_MEAN_SULCI}"

        ########## K2 VARIANCE
        echo
        echo "***************************************************************************"
        echo "BEGIN CALCULATING K2 VARIANCE"
        echo "***************************************************************************"
        ###### CPGRID YOUNGER
        CP_LY_K2_VARIANCE=$(wb_command -metric-stats ${L_CP_OUT}${TIME1}.K2.func.gii -reduce VARIANCE)
        CP_RY_K2_VARIANCE=$(wb_command -metric-stats ${R_CP_OUT}${TIME1}.K2.func.gii -reduce VARIANCE)
        echo "CPGRID LEFT YOUNGER K2 VARIANCE=${CP_LY_K2_VARIANCE}"
        echo "CPGRID RIGHT YOUNGER K2 VARIANCE=${CP_RY_K2_VARIANCE}"

        ###### CPGRID OLDER
        CP_LO_K2_VARIANCE=$(wb_command -metric-stats ${L_CP_OUT}${TIME2}.K2.func.gii -reduce VARIANCE)
        CP_RO_K2_VARIANCE=$(wb_command -metric-stats ${R_CP_OUT}${TIME2}.K2.func.gii -reduce VARIANCE)
        echo "CPGRID LEFT OLDER K2 VARIANCE=${CP_LO_K2_VARIANCE}"
        echo "CPGRID RIGHT OLDER K2 VARIANCE=${CP_RO_K2_VARIANCE}"

        ###### ANATGRID YOUNGER
        ANAT_LY_K2_VARIANCE=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME1}.K2.func.gii -reduce VARIANCE)
        ANAT_RY_K2_VARIANCE=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME1}.K2.func.gii -reduce VARIANCE)
        echo "ANATGRID LEFT YOUNGER K2 VARIANCE=${ANAT_LY_K2_VARIANCE}"
        echo "ANATGRID RIGHT YOUNGER K2 VARIANCE=${ANAT_RY_K2_VARIANCE}"

        ###### ANATGRID OLDER
        ANAT_LO_K2_VARIANCE=$(wb_command -metric-stats ${L_ANAT_OUT}${TIME2}.K2.func.gii -reduce VARIANCE)
        ANAT_RO_K2_VARIANCE=$(wb_command -metric-stats ${R_ANAT_OUT}${TIME2}.K2.func.gii -reduce VARIANCE)
        echo "ANATGRID LEFT OLDER K2 VARIANCE=${ANAT_LO_K2_VARIANCE}"
        echo "ANATGRID RIGHT OLDER K2 VARIANCE=${ANAT_RO_K2_VARIANCE}"

        ########## GENERATE DIFFERENCE MAPS
        echo
        echo "***************************************************************************"
        echo "BEGIN GENERATING DIFFERENCE MAPS"
        echo "***************************************************************************"
        ######## CPGRID SULCI
        wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${L_CP_OUT}diff.sulci.func.gii -var K1_1 ${L_CP_OUT}${TIME1}.K1.func.gii -var K1_2 ${L_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID LEFT SULCI COMPLETED, SAVED AT ${L_CP_OUT}diff.sulci.func.gii"
        wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${R_CP_OUT}diff.sulci.func.gii -var K1_1 ${R_CP_OUT}${TIME1}.K1.func.gii -var K1_2 ${R_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID RIGHT SULCI COMPLETED, SAVED AT ${R_CP_OUT}diff.sulci.func.gii"

        ######## CPGRID GYRI
        wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${L_CP_OUT}diff.gyri.func.gii -var K1_1 ${L_CP_OUT}${TIME1}.K1.func.gii -var K1_2 ${L_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID LEFT GYRI COMPLETED, SAVED AT ${L_CP_OUT}diff.gyri.func.gii"
        wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${R_CP_OUT}diff.gyri.func.gii -var K1_1 ${R_CP_OUT}${TIME1}.K1.func.gii -var K1_2 ${R_CP_OUT}${TIME2}.K1.func.gii
        echo "CPGRID RIGHT GYRI COMPLETED, SAVED AT ${R_CP_OUT}diff.gyri.func.gii"

        ######## ANATGRID SULCI
        wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${L_ANAT_OUT}diff.sulci.func.gii -var K1_1 ${L_ANAT_OUT}${TIME1}.K1.func.gii -var K1_2 ${L_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID LEFT SULCI COMPLETED, SAVED AT ${L_ANAT_OUT}diff.sulci.func.gii"
        wb_command -metric-math '((K1_2-K1_1)*(K1_1<0))' ${R_ANAT_OUT}diff.sulci.func.gii -var K1_1 ${R_ANAT_OUT}${TIME1}.K1.func.gii -var K1_2 ${R_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID RIGHT SULCI COMPLETED, SAVED AT ${R_ANAT_OUT}diff.sulci.func.gii"

        ######## ANATGRID GYRI
        wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${L_ANAT_OUT}diff.gyri.func.gii -var K1_1 ${L_ANAT_OUT}${TIME1}.K1.func.gii -var K1_2 ${L_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID LEFT GYRI COMPLETED, SAVED AT ${L_ANAT_OUT}diff.gyri.func.gii"
        wb_command -metric-math '((K1_2-K1_1)*(K1_1>0))' ${R_ANAT_OUT}diff.gyri.func.gii -var K1_1 ${R_ANAT_OUT}${TIME1}.K1.func.gii -var K1_2 ${R_ANAT_OUT}${TIME2}.K1.func.gii
        echo "ANATGRID RIGHT GYRI COMPLETED, SAVED AT ${R_ANAT_OUT}diff.gyri.func.gii"

        ########## ADD DATA TO CSV
        echo
        echo "***************************************************************************"
        echo "ADDING DATA TO CSV FILES"
        echo "***************************************************************************"
        CP_YOUNGER_DATA="${SUBJECT},${TIME1},${CP_RY_CORTICAL_SA},${CP_LY_CORTICAL_SA},${CP_RY_MEAN_GYRI},${CP_LY_MEAN_GYRI},${CP_RY_MEAN_SULCI},${CP_LY_MEAN_SULCI},${CP_RY_K2_VARIANCE},${CP_LY_K2_VARIANCE}"
        CP_OLDER_DATA="${SUBJECT},${TIME2},${CP_RO_CORTICAL_SA},${CP_LO_CORTICAL_SA},${CP_RO_MEAN_GYRI},${CP_LO_MEAN_GYRI},${CP_RO_MEAN_SULCI},${CP_LO_MEAN_SULCI},${CP_RO_K2_VARIANCE},${CP_LO_K2_VARIANCE}"
        ANAT_YOUNGER_DATA="${SUBJECT},${TIME1},${ANAT_RY_CORTICAL_SA},${ANAT_LY_CORTICAL_SA},${ANAT_RY_MEAN_GYRI},${ANAT_LY_MEAN_GYRI},${ANAT_RY_MEAN_SULCI},${ANAT_LY_MEAN_SULCI},${ANAT_RY_K2_VARIANCE},${ANAT_LY_K2_VARIANCE}"
        ANAT_OLDER_DATA="${SUBJECT},${TIME2},${ANAT_RO_CORTICAL_SA},${ANAT_LO_CORTICAL_SA},${ANAT_RO_MEAN_GYRI},${ANAT_LO_MEAN_GYRI},${ANAT_RO_MEAN_SULCI},${ANAT_LO_MEAN_SULCI},${ANAT_RO_K2_VARIANCE},${ANAT_LO_K2_VARIANCE}"

        echo "${CP_YOUNGER_DATA}">>"${CP_OUTPUT}"
        echo "YOUNGER DATA AT CPGRID ADDED TO CSV ${CP_OUTPUT}"
        echo "${CP_OLDER_DATA}">>"${CP_OUTPUT}"
        echo "OLDER DATA AT CPGRID ADDED TO CSV ${CP_OUTPUT}"
        echo "${ANAT_YOUNGER_DATA}">>"${ANAT_OUTPUT}"
        echo "YOUNGER DATA AT ANATGRID ADDED TO CSV ${ANAT_OUTPUT}"
        echo "${ANAT_OLDER_DATA}">>"${ANAT_OUTPUT}"
        echo "OLDER DATA AT ANATGRID ADDED TO CSV ${ANAT_OUTPUT}"

        ########## ERASE DUPLICATE DATA (ALLOWS SCRIPT TO BE RAN MULTIPLE TIMES NO MATTER HOW MANY SUBJECTS WE HAVE AND RETAIN A SINGLE FILE)
        echo
        echo "***************************************************************************"
        echo "ERASING ALL DUPLICATE DATA"
        echo "***************************************************************************"
        ######## CPGRID
        awk 'seen[$0]++{print $0 > ${DUPLICATE_CSV}; next}{print $0 > ${CP_CORRECTED_OUTPUT}}' ${CP_OUTPUT}
        echo "CPGRID DATA COMPLETED, CORRECTED DATA SAVED AT ${CP_CORRECTED_OUTPUT}"

        ######## ANATGRID
        awk 'seen[$0]++{print $0 > ${DUPLICATE_CSV}; next}{print $0 > ${ANAT_CORRECTED_OUTPUT}}' ${ANAT_OUTPUT}
        echo "ANATGRID DATA COMPLETED, CORRECTED DATA SAVED AT ${ANAT_CORRECTED_OUTPUT}"

        rm ${DUPLICATE_CSV}
    fi
done
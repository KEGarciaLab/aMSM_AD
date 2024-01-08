#!/bin/bash

########## DEFINE VARIABLES

###### DO NOT CHANGE THESE
CSV_HEADINGS="SUBJECT_ID,IMAGE,R_CORTICAL_SA,L_CORTICAL_SA,R_MEAN_GYRI,L_MEAN_GYRI,R_MEAN_SULCI,L_MEAN_SULCI,R_K2_VARIANCE,L_K2_VARIANCE" # headings of csv file
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the csv file so multiple can be run keeping data seperate
LOG_OUTPUT=${HOME}/Scripts/MyScripts/logs/$(basename "$0")_${CURRENT_DATETIME}.log # name and location of log file

###### CAN BE CHANGED BY USER ONLY CHANGE THE PARTS THAT ARE NOT IN {} UNLESS YOU KNOW WHAT YOU ARE DOING
DATASET=/N/project/aMSM/ADNI/Data/3T_Analysis/ciftify # Folder containing subject data
PREFIX="Subject" # Prefix to prepend to each subject ID
SUBJECTS="" # list of subject ID to run through (leave blank to generate the list automatically). Subject numbers should be entered with a space between seperate numbers "#### ####"
SUB_GEN_SCRIPT=${HOME}/Scripts/MyScripts/Subject_List.sh # locatoion the Subject_List.sh file, this is needed to generate the subject automatically
SUB_GEN_DIR=${HOME}/Scripts/MyScripts/Output/Subject_List.sh # location when Subject_List.sh will output, match it to OUTPUT_DIR in Subject_List.sh
SUB_GEN_FILE="subject_numbers.txt" # name of subject list file, should match OUTPUT_FILE in Subject_List.sh
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0")/${CURRENT_DATETIME} # output location for script
OUTPUT=${OUTPUT_DIR}/AD_cortical_thinning_${CURRENT_DATETIME}.csv # name and location of csv output file

########## BEGIN LOGGING
exec > >(tee -a "${LOG_OUTPUT}") 2>&1

########## CREATE CSV FILE
echo "***************************************************************************"
echo "CREATING OUTPUT FILE"
echo "***************************************************************************"
mkdir -p ${OUTPUT_DIR}
if [ ! -e "${OUTPUT}" ]; then
    echo ${CSV_HEADINGS} > ${OUTPUT}
fi

########## FIND SUBJECTS
if [ -z "${SUBJECTS}" ]; then
    echo
    echo "***************************************************************************"
    echo "NO SUBJECTS SPECIFIED, GENERATING SUBJECTS"
    echo "***************************************************************************"
    bash "${SUB_GEN_SCRIPT}"
    SUBJECTS=$(<"${SUB_GEN_DIR}/${SUB_GEN_FILE}")
    echo "SUBJECTS FOUND: ${SUBJECTS}"
fi

########## EXTRACT DATA
for SUBJECT in ${SUBJECTS}; do
    # FIND ALL FOLDERS MATCHING THE SUBJECTS
    SUBJECT_DIRS=$(find ${DATASET} -maxdepth 1 -type d -name "${PREFIX}_${SUBJECT}*" ! -name "*.long.*")
    
    for DIR in  ${SUBJECT_DIRS}; do
        # get image number
        echo
        echo "***************************************************************************"
        echo "LOCATING NEXT DIR FOR ${SUBJECT}"
        echo "***************************************************************************"
        echo "Found: ${DIR}"
        IMAGE_NUMBER=${DIR#*Image_}
        echo "Dir Image number: ${IMAGE_NUMBER}"
        echo "Creating Output sub dir ${OUTPUT_DIR}/${PREFIX}_${SUBJECT}_Image_${IMAGE_NUMBER}"
        OUTPUT_SUB_DIR=${OUTPUT_DIR}/${PREFIX}_${SUBJECT}_Image_${IMAGE_NUMBER}
        mkdir ${OUTPUT_SUB_DIR}
        OUTPUT_R="${PREFIX}_${SUBJECT}_Image_${IMAGE_NUMBER}.R." # prepend to the putput of right hemisphere
        OUTPUT_L="${PREFIX}_${SUBJECT}_Image_${IMAGE_NUMBER}.L." # prepend to the putput of right hemisphere

        # midthickness files to be processed
        echo
        echo "***************************************************************************"
        echo "GENERATING SURFACE VERTEX AREAS FOR ${SUBJECT}_Image_${IMAGE_NUMBER}"
        echo "***************************************************************************"
        R_SUBJECT_FILE=${DIR}/T1w/Native/${OUTPUT_R}midthickness.native.surf.gii
        L_SUBJECT_FILE=${DIR}/T1w/Native/${OUTPUT_L}midthickness.native.surf.gii
        cp "${R_SUBJECT_FILE}" "${OUTPUT_SUB_DIR}"
        cp "${L_SUBJECT_FILE}" "${OUTPUT_SUB_DIR}"

        # generate surface are of each vertex for both hemispheres
        wb_command -surface-vertex-areas "${R_SUBJECT_FILE}" ${OUTPUT_SUB_DIR}/${OUTPUT_R}surface-vertex-area.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}surface-vertex-area.func.gii"
        wb_command -surface-vertex-areas "${L_SUBJECT_FILE}" ${OUTPUT_SUB_DIR}/${OUTPUT_L}surface-vertex-area.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}surface-vertex-area.func.gii"

        # Calculate SA using metric stats sum
        echo
        echo "***************************************************************************"
        echo "CALCULATING CORTICAL SA FOR ${SUBJECT}_Image_${IMAGE_NUMBER}"
        echo "***************************************************************************"
        R_CORTICAL_SA=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_R}surface-vertex-area.func.gii -reduce SUM)
        L_CORTICAL_SA=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_L}surface-vertex-area.func.gii -reduce SUM)
        echo "R_CORTICAL_SA=${R_CORTICAL_SA}"
        echo "L_CORTICAL_SA=${L_CORTICAL_SA}"

        ########## Find K1 and K2
        echo
        echo "***************************************************************************"
        echo "CALCULATING K1 and K2 FOR ${SUBJECT}_Image_${IMAGE_NUMBER}"
        echo "***************************************************************************"
        ## GUASS CURVE 
        echo "CALCULATING GAUSS CURVE"
        wb_command -surface-curvature ${R_SUBJECT_FILE} -gauss ${OUTPUT_SUB_DIR}/${OUTPUT_R}gauss_curve.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}gauss_curve.func.gii"
        wb_command -surface-curvature ${L_SUBJECT_FILE} -gauss ${OUTPUT_SUB_DIR}/${OUTPUT_L}gauss_curve.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}gauss_curve.func.gii"
        echo

        ## MEAN CURVE 
        echo "CALCULATING MEAN CURVE"
        wb_command -surface-curvature ${R_SUBJECT_FILE} -mean ${OUTPUT_SUB_DIR}/${OUTPUT_R}mean_curve.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}mean_curve.func.gii"
        wb_command -surface-curvature ${L_SUBJECT_FILE} -mean ${OUTPUT_SUB_DIR}/${OUTPUT_L}mean_curve.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}mean_curve.func.gii"
        echo

        ## KMAX
        echo "GETTING KMAX"
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${OUTPUT_SUB_DIR}/${OUTPUT_R}kmax.func.gii -var KH ${OUTPUT_SUB_DIR}/${OUTPUT_R}mean_curve.func.gii -var KG ${OUTPUT_SUB_DIR}/${OUTPUT_R}gauss_curve.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}kmax.func.gii"
        wb_command -metric-math '(KH+sqrt(KH^2-KG))' ${OUTPUT_SUB_DIR}/${OUTPUT_L}kmax.func.gii -var KH ${OUTPUT_SUB_DIR}/${OUTPUT_L}mean_curve.func.gii -var KG ${OUTPUT_SUB_DIR}/${OUTPUT_L}gauss_curve.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}kmax.func.gii"
        echo

        ## KMIN
        echo "GETTING KMIN"
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${OUTPUT_SUB_DIR}/${OUTPUT_R}kmin.func.gii -var KH ${OUTPUT_SUB_DIR}/${OUTPUT_R}mean_curve.func.gii -var KG ${OUTPUT_SUB_DIR}/${OUTPUT_R}gauss_curve.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}kmin.func.gii"
        wb_command -metric-math '(KH-sqrt(KH^2-KG))' ${OUTPUT_SUB_DIR}/${OUTPUT_L}kmin.func.gii -var KH ${OUTPUT_SUB_DIR}/${OUTPUT_L}mean_curve.func.gii -var KG ${OUTPUT_SUB_DIR}/${OUTPUT_L}gauss_curve.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}kmin.func.gii"
        echo

        ## FIND K1
        echo "CALCULATING K1"
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.func.gii -var Kmax ${OUTPUT_SUB_DIR}/${OUTPUT_R}kmax.func.gii -var Kmin ${OUTPUT_SUB_DIR}/${OUTPUT_R}kmin.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.func.gii"
        wb_command -metric-math '(max(abs(Kmax),abs(Kmin))*((Kmax+Kmin)/(abs(Kmax+Kmin))))' ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.func.gii -var Kmax ${OUTPUT_SUB_DIR}/${OUTPUT_L}kmax.func.gii -var Kmin ${OUTPUT_SUB_DIR}/${OUTPUT_L}kmin.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.func.gii"
        echo

        ## REMOVE NAN FROM K1
        echo "CONVERTING TO ASCII"
        wb_command -gifti-convert ASCII ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.func.gii ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.ASCII.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.ASCII.func.gii"
        wb_command -gifti-convert ASCII ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.func.gii ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.ASCII.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.ASCII.func.gii"
        echo "REPLACING NaN with 0"
        sed -i 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.ASCII.func.gii > ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.CORRECTED.func.gii # RegEx matches exactly nan which only appears in compromised data, preserves whitespace
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.CORRECTED.func.gii"
        sed -i 's/^\([[:space:]]*\)nan\([[:space:]]*\)$/\10\2/' ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.ASCII.func.gii > ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.CORRECTED.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.CORRECTED.func.gii"
        echo

        ## FIND K2
        echo "CALCULATING K2"
        wb_command -metric-math 'KG/K1' ${OUTPUT_SUB_DIR}/${OUTPUT_R}K2.func.gii -var KG ${OUTPUT_SUB_DIR}/${OUTPUT_R}gauss_curve.func.gii -var K1 ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.CORRECTED.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}K2.func.gii"        
        wb_command -metric-math 'KG/K1' ${OUTPUT_SUB_DIR}/${OUTPUT_L}K2.func.gii -var KG ${OUTPUT_SUB_DIR}/${OUTPUT_L}gauss_curve.func.gii -var K1 ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.CORRECTED.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}K2.func.gii" 

        ########## Split K1 sulci and gyri
        echo
        echo "***************************************************************************"
        echo "SPLITTING K1 SULCI AND GYRI FOR ${SUBJECT}_Image_${IMAGE_NUMBER}"
        echo "***************************************************************************"
        echo "SEPERATING SUCLI"
        wb_command -metric-math '(K1*(K1<0))' ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.sulci.func.gii -var K1 ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.sulci.func.gii"
        wb_command -metric-math '(K1*(K1<0))' ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.sulci.func.gii -var K1 ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.sulci.func.gii"
        echo

        echo "SEPERATING GYRI"
        wb_command -metric-math '(K1*(K1>0))' ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.gyri.func.gii -var K1 ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.func.gii
        echo "RIGHT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.gyri.func.gii"
        wb_command -metric-math '(K1*(K1>0))' ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.gyri.func.gii -var K1 ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.func.gii
        echo "LEFT HEMISPHERE COMPLETE, SAVED AT ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.gyri.func.gii"

        ########## Calculate Mean Gyri
        echo
        echo "***************************************************************************"
        echo "CALCULATING MEAN GYRI FOR ${SUBJECT}_Image_${IMAGE_NUMBER}"
        echo "***************************************************************************"
        R_SUM_GYRI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.gyri.func.gii -reduce SUM)
        echo ${R_SUM_GYRI}
        R_COUNT_GYRI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.gyri.func.gii -reduce COUNT_NONZERO)
        echo ${R_COUNT_GYRI}
        R_MEAN_GYRI=$(echo "scale=20; ${R_SUM_GYRI}/${R_COUNT_GYRI}" | bc)
        R_MEAN_GYRI=$(printf "%022.20f" ${R_MEAN_GYRI})
        echo "R_MEAN_GYRI=${R_MEAN_GYRI}"

        L_SUM_GYRI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.gyri.func.gii -reduce SUM)
        echo ${L_SUM_GYRI}
        L_COUNT_GYRI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.gyri.func.gii -reduce COUNT_NONZERO)
        echo ${L_COUNT_GYRI}
        L_MEAN_GYRI=$(echo "scale=20; ${L_SUM_GYRI}/${L_COUNT_GYRI}" | bc)
        L_MEAN_GYRI=$(printf "%022.20f" ${L_MEAN_GYRI})
        echo "L_MEAN_GYRI=${L_MEAN_GYRI}"

        ########## Calculate Mean Sulci
        echo
        echo "***************************************************************************"
        echo "CALCULATING MEAN SULCI FOR ${SUBJECT}_Image_${IMAGE_NUMBER}"
        echo "***************************************************************************"
        R_SUM_SULCI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.sulci.func.gii -reduce SUM)
        echo ${R_SUM_SULCI}
        R_COUNT_SULCI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_R}K1.sulci.func.gii -reduce COUNT_NONZERO)
        echo ${R_COUNT_SULCI}
        R_MEAN_SULCI=$(echo "scale=20; ${R_SUM_SULCI}/${R_COUNT_SULCI}" | bc)
        R_MEAN_SULCI=$(printf "%022.20f" ${R_MEAN_SULCI})
        echo "R_MEAN_SULCI=${R_MEAN_SULCI}"

        L_SUM_SULCI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.sulci.func.gii -reduce SUM)
        echo ${L_SUM_SULCI}
        L_COUNT_SULCI=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_L}K1.sulci.func.gii -reduce COUNT_NONZERO)
        echo ${L_COUNT_SULCI}
        L_MEAN_SULCI=$(echo "scale=20; ${L_SUM_SULCI}/${L_COUNT_SULCI}" | bc)
        L_MEAN_SULCI=$(printf "%022.20f" ${L_MEAN_SULCI})
        echo "L_MEAN_SULCI=${L_MEAN_SULCI}"

        ########## Calculate K2 Variance
        echo
        echo "***************************************************************************"
        echo "CALCULATING K2 VARIANCE FOR ${SUBJECT}_Image_${IMAGE_NUMBER}"
        echo "***************************************************************************"
        R_K2_VARIANCE=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_R}K2.func.gii -reduce VARIANCE)
        echo "R_K2_VARIANCE=${R_K2_VARIANCE}"
        L_K2_VARIANCE=$(wb_command -metric-stats ${OUTPUT_SUB_DIR}/${OUTPUT_L}K2.func.gii -reduce VARIANCE)
        echo "L_K2_VARIANCE=${L_K2_VARIANCE}"

        ########## Write to CSV
        echo
        echo "***************************************************************************"
        echo "WRITING DATA FOR ${SUBJECT}_Image_${IMAGE_NUMBER} TO ${OUTPUT}"
        echo "***************************************************************************"
        DATA="${SUBJECT},${IMAGE_NUMBER},${R_CORTICAL_SA},${L_CORTICAL_SA},${R_MEAN_GYRI},${L_MEAN_GYRI},${R_MEAN_SULCI},${L_MEAN_SULCI},${R_K2_VARIANCE},${L_K2_VARIANCE}"
        echo "${DATA}">>"${OUTPUT}"
    done
done

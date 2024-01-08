#!/bin/bash

# DEFINE VARIABLES
DATASET=/geode2/home/u080/sarigdon/BigRed200/Practice_Data/FerretPrelim_ico6 # Folder with the subject data
POSTPROCESSING_OUT=${DATASET}/Images
SUBJECTS="A1_control A2_control K1_BEP7 K2_BEP7 K4_control K5_BEP7" # All subjects to be run seperated by a space
TIMES="s1 s2 s3" # All time points to be run
MSMCONFIG=/N/project/aMSM/ADNI/SetupFiles/Config/configFINAL # location of config file
LEVELS="6"
MAXCP=/geode2/home/u080/sarigdon/BigRed200/Practice_Data/ico5sphere.ANATgrid.reg.surf.gii
MAXANAT=/geode2/home/u080/sarigdon/BigRed200/Practice_Data/ico6sphere.ANATgrid.reg.surf.gii

## SPHERICAL SURFACES DEFINED HERE AS THEY DON'T CHANGE FOR PRACTICE DATA
SS=/geode2/home/u080/sarigdon/BigRed200/Practice_Data/ico6sphere.ANATgrid.reg.surf.gii

# CREATE IMAGE OUTPUT DIR
mkdir ${POSTPROCESSING_OUT}

for SUBJECT in ${SUBJECTS}; do
    for HEMISPHERE in L R; do
        # SET STRUCTURE FOR POST PROCESSING
        if [ ${HEMISPHERE} = L ]; then
            STRUCTURE="CORTEX_LEFT"
        fi

        if [ ${HEMISPHERE} = R ]; then
            STRUCTURE="CORTEX_RIGHT"
        fi

        # FIND SUBJECT FOLDER
        OUT_SUB_DIR=${DATASET}/${SUBJECT}.${HEMISPHERE}
        
        for TIME1 in ${TIMES}; do
            for TIME2 in ${TIMES}; do
                if [ ${TIME2} != ${TIME1} ]; then
                    echo "######################## BEGIN ${SUBJECT} ${TIME1}-${TIME2} #######################"
                    # FIND OUTPUT FOLDER
                    echo "######################## FINDING OUTPUT FOLDER ####################################"
                    TIME_OUTPUT_DIR=${OUT_SUB_DIR}/${TIME1}.${TIME2}

                    #DEFINE VARIABLES
                    RUNNAME=${TIME_OUTPUT_DIR}/Reg.

                    # SET COLORSCALE
                    echo "######################## SETTING COLOR SCALE ######################################"
                    wb_command -metric-palette ${RUNNAME}${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.surfdist.CPgrid.func.gii MODE_AUTO_SCALE 
                    wb_command -metric-palette ${RUNNAME}${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.surfdist.ANATgrid.func.gii MODE_AUTO_SCALE 
                    wb_command -metric-palette ${RUNNAME}${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.surfdist.func.gii MODE_AUTO_SCALE 

                    # CREATE SPEC FILE
                    echo "######################## CREATING SPEC FILE #######################################"
                    wb_command -add-to-spec-file ${DATASET}/Ferret.${SUBJECT}.spec ${STRUCTURE} ${TIME_OUTPUT_DIR}/${SUBJECT}.${HEMISPHERE}.${TIME1}.AS.CPgrid.surf.gii
                    wb_command -add-to-spec-file ${DATASET}/Ferret.${SUBJECT}.spec ${STRUCTURE} ${RUNNAME}${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.anat.CPgrid.reg.surf.gii
                    wb_command -add-to-spec-file ${DATASET}/Ferret.${SUBJECT}.spec ${STRUCTURE} ${RUNNAME}${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.surfdist.CPgrid.func.gii

                    # CREATE SCENE FILE AND PRINT TO PNG
                    echo "######################## PRINTING TO IMAGE ########################################"
                    sed "s!SUBJECT!${SUBJECT}!g;s!HEMISPHERE!${HEMISPHERE}!g;s!TIME1!${TIME1}!g;s!TIME2!${TIME2}!g;s!DATASET!${TIME_OUTPUT_DIR}!g" ${DATASET}/test.scene > ${TIME_OUTPUT_DIR}/${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.scene
                    wb_command -show-scene ${TIME_OUTPUT_DIR}/${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.scene ${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2} ${POSTPROCESSING_OUT}/${SUBJECT}.${HEMISPHERE}.${TIME1}-${TIME2}.png 1024 512
                    echo "######################## COMPLETE #################################################"
                    echo
                fi
            done
        done
    done
done
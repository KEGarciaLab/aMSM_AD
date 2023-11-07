########## DEFINE VARIABLES
DATASET=/geode2/home/u080/sarigdon/Carbonate/Practice_Data/FerretPrelim_ico6 # Folder with subject data
SUBJECTS="A1_control A2_control K1_BEP7 K2_BEP7 K4_control K5_BEP7" # All subjects to be concatenated
SUBJECT_PREFIX="Ferret."
TIME_START="s1"
INTERMEDIATE_TIME="s2"
TIME_END="s3"
SPHERE_PROJECT_TO=/geode2/home/u080/sarigdon/Carbonate/Practice_Data/ico5sphere.ANATgrid.reg.surf.gii
SS=/geode2/home/u080/sarigdon/Carbonate/Practice_Data/ico6sphere.ANATgrid.reg.surf.gii


for SUBJECT in ${SUBJECTS}; do
    for HEMISPHERE in L R; do
        # Define folder for time point
        TIME_FOLDER1=${DATASET}/${SUBJECT}.${HEMISPHERE}/${TIME_START}.${INTERMEDIATE_TIME}
        TIME_FOLDER2=${DATASET}/${SUBJECT}.${HEMISPHERE}/${INTERMEDIATE_TIME}.${TIME_END}
        
        # Create output folder for concat
        OUT_SUB_DIR=${DATASET}/${SUBJECT}.${HEMISPHERE}/${TIME_START}.${TIME_END}/CONCAT
        mkdir ${OUT_SUB_DIR}

        # Define variables
        SPHERE_IN=${TIME_FOLDER1}/Reg.${SUBJECT}.${HEMISPHERE}.${TIME_START}-${INTERMEDIATE_TIME}.sphere.CPgrid.reg.surf.gii
        SPHERE_UNPROJECT_FROM=${TIME_FOLDER2}/Reg.${SUBJECT}.${HEMISPHERE}.${INTERMEDIATE_TIME}-${TIME_END}.sphere.CPgrid.reg.surf.gii
        CONCAT_OUTPUT=${OUT_SUB_DIR}/CONCAT.Reg.${SUBJECT}.${HEMISPHERE}.${TIME_START}-${TIME_END}.sphere.CPgrid.reg.surf.gii
        AS_TIME_END=${DATASET}/${SUBJECT_PREFIX}${SUBJECT}_${TIME_END}.${HEMISPHERE}.Fiducial.surf.gii
        ANAT_OUTPUT=${OUT_SUB_DIR}/CONCAT.Reg.${SUBJECT}.${HEMISPHERE}.${TIME_START}-${TIME_END}.anat.CPgrid.reg.surf.gii
        SURFACE_REFERENCE=${TIME_FOLDER1}/${SUBJECT}.${HEMISPHERE}.${TIME_START}.AS.CPgrid.surf.gii
        SURFDIST_OUTPUT=${OUT_SUB_DIR}/CONCAT.Reg.${SUBJECT}.${HEMISPHERE}.${TIME_START}-${TIME_END}.surfdist.CPgrid.func.gii

        ########## CONCAT
        wb_command -surface-sphere-project-unproject ${SPHERE_IN} ${SPHERE_PROJECT_TO} ${SPHERE_UNPROJECT_FROM} ${CONCAT_OUTPUT}

        ########## RESAMPLE TO GET ANAT FILE
        wb_command -surface-resample ${AS_TIME_END} ${SS} ${CONCAT_OUTPUT} "BARYCENTRIC" ${ANAT_OUTPUT}

        ########## DISTORTION FOR SURFDIST FILE
        wb_command -surface-distortion ${SURFACE_REFERENCE} ${ANAT_OUTPUT} ${SURFDIST_OUTPUT}

    done
done
# test comment for commit
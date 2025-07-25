# VARIABLE DECLARATION
PATH_TO_MSM="/N/project/aMSM/ADNI/ProgramFiles/MSM_HOCR-master"
PATH_TO_FSL="/N/project/aMSM/ADNI/ProgramFiles/FSL_Dev"

# COPY FILE
echo "************************************************************************"
echo "*                      BEGIN COPYING FILES                             *"
echo "************************************************************************"
cp -a -v -- ${PATH_TO_MSM} ${HOME}
cp -a -v -- ${PATH_TO_FSL} ${HOME}
chmod +x ${HOME}/FSL_Dev/fslconf/fsl.sh

# EDIT BASH PROFILE
echo "************************************************************************"
echo "*                      ADDING TO PATH                                  *"
echo "************************************************************************"
cat >> .bash_profile <<"EOF"

export FSLDEVDIR=$HOME/FSL_Dev

export FSLDIR=/N/soft/rhel7/fsl/5.0.10
${FSLDEVDIR}/fslconf/fsl.sh

export FSLCONFDIR=$FSLDIR/config
export FSLMATCHTYPE=linux_64-gcc4.8

export PATH=$HOME/MSM_HOCR-master/src/MSM:$PATH
EOF

echo "************************************************************************"
echo "*           PLEASE LOG OUT AND RECONNECT TO FINISH INSTALL             *"
echo "************************************************************************"
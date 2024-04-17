# VARIABLE DECLARATION
PATH_TO_FREESURFER=/geode2/soft/hps/rhel7/freesurfer/6.0.0/freesurfer
PATH_TO_FSL=/geode2/soft/hps/rhel7/fsl/6.0.5

# Downlad Ciftify
echo "************************************************************************"
echo "*                         CLONING CIFTIFY REPO                         *"
echo "************************************************************************"
git clone https://github.com/edickie/ciftify ciftify-master

# Copy MSM and make sure it's executable
echo "************************************************************************"
echo "*                   COPYING MSM FROM USER INSTALL                      *"
echo "************************************************************************"
cp -v -- ${HOME}/MSM_HOCR-master/src/MSM/msm ${HOME}/ciftify-master
chmod +x ${HOME}/ciftify-master/msm

# Copy Freesurfer
echo "************************************************************************"
echo "*                        COPYING FREESURFER                            *"
echo "************************************************************************"
cp -a -v -- ${PATH_TO_FREESURFER} ${HOME}

# Copy FSL
echo "************************************************************************"
echo "*                           COPYING FSL                                *"
echo "************************************************************************"
cp -a -r -v -- ${PATH_TO_FSL} ${HOME}/fsl

# Update .bash_profile
echo "************************************************************************"
echo "*                       UPDATING BASH PROFILE                          *"
echo "************************************************************************"
cat >> .bash_profile << "EOF"

export PATH=$PATH:$HOME/fsl/bin
export PATH=$PATH:$HOME/freesurfer/bin
export PATH=$HOME/.local/bin:$HOME/ciftify-master:$PATH
module load python
EOF

# Ensure Python is loaded and install ciftify
echo "************************************************************************"
echo "*                         INSTALLING CIFTIFY                           *"
echo "************************************************************************"
module load python
pip install ciftify

# change nibabel version
echo "************************************************************************"
echo "*                        DOWNGRADING NIBABEL                           *"
echo "************************************************************************"
pip install --upgrade nibabel==3.2.0

# tell user to logout and reconnect
echo "************************************************************************"
echo "*           PLEASE LOG OUT AND RECONNECT TO FINISH INSTALL             *"
echo "************************************************************************"
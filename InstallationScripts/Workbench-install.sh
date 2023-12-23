# Download workbench
echo "************************************************************************"
echo "*                       DOWNLOADING WORKBENCH                          *"
echo "************************************************************************"
wget https://www.humanconnectome.org/storage/app/media/workbench/workbench-rh_linux64-v1.5.0.zip

echo "************************************************************************"
echo "*                         UNPACKING ARCHIVE                            *"
echo "************************************************************************"
unzip workbench-rh_linux64-v1.5.0.zip
rm workbench-rh_linux64-v1.5.0.zip

# make the files executable
echo "************************************************************************"
echo "*                      MAKING FILES EXECUTABLE                         *"
echo "************************************************************************"
chmod +x ${HOME}/workbench/bin_rh_linux64/wb_command
chmod +x ${HOME}/workbench/bin_rh_linux64/wb_import
chmod +x ${HOME}/workbench/exe_rh_linux64/wb_command
chmod +x ${HOME}/workbench/exe_rh_linux64/wb_import

# edit bash_profile
echo "************************************************************************"
echo "*                       UPDATING BASH PROFILE                          *"
echo "************************************************************************"
cat >> .bash_profile << "EOF"

export PATH=$HOME/workbench/bin_rh_linux64:$PATH
EOF

# instruct user to log out and reconnect
echo "************************************************************************"
echo "*           PLEASE LOG OUT AND RECONNECT TO FINISH INSTALL             *"
echo "************************************************************************"
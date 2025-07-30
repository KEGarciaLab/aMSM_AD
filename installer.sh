#!/bin/bash

INSTALL_DIR="$HOME/bin"
mkdir -p "$INSTALL_DIR"

cp MSM_Pipeline.py "$INSTALL_DIR/MSM_Pipeline"
chmod +x "$INSTALL_DIR/MSM_Pipeline"

cp -r Templates "$INSTALL_DIR/"
cp -r NeededFiles "$INSTALL_DIR/"

echo "Installed to $INSTALL_DIR"

if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "WARNING: $HOME/bin is not in your PATH. Add the following to your ~/.bashrc or ~/.zshrc:"
    echo 'export PATH="$HOME/bin:$PATH"'
fi
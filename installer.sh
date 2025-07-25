#!/bin/bash

INSTALL_DIR="$HOME/bin/MSM_Pipeline"
mkdir -p "$INSTALL_DIR"

cp MSM_Pipeline.py "$INSTALL_DIR/MSM_Pipeline"
chmod +x "$INSTALL_DIR/MSM_Pipeline"

cp -r Templates "$INSTALL_DIR/"

# Optional symlink or wrapper for PATH
mkdir -p "$HOME/bin"
ln -sf "$INSTALL_DIR/MSM_Pipeline" "$HOME/bin/MSM_Pipeline"

echo "Installed to $INSTALL_DIR"

if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "WARNING: $HOME/bin is not in your PATH. Add the following to your ~/.bashrc or ~/.zshrc:"
    echo 'export PATH="$HOME/bin:$PATH"'
fi
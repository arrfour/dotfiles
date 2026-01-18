#!/bin/bash

# Update the local repository from the remote
echo "Checking for updates..."
BRANCH=$(git branch --show-current)
git pull origin "$BRANCH"

# Re-run the installation script to ensure everything is in sync
echo "Re-applying configurations..."
./install.sh

echo "Update complete!"

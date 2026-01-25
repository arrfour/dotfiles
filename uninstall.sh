#!/bin/bash

# Loop through all the dotfiles, if the file is a symlink then remove it
# Then if the backup file exists, restore it to it's original location
for file in $(find . -maxdepth 1 -name ".*" -type f  -printf "%f\n" ); do
    if [ -h ~/$file ]; then
        rm -f ~/$file
    fi
    if [ -e ~/${file}.dtbak ]; then
        mv -f ~/$file{.dtbak,}
    fi
done

# Uninstall .config subdirectories
config_root="$HOME/.config"
if [ -d ".config" ]; then
    for dir in $(ls -d .config/*/); do
        target_dir=$(basename "$dir")
        if [ -h "$config_root/$target_dir" ]; then
            echo "Removing symlink for $target_dir"
            rm -f "$config_root/$target_dir"
        fi
    done
fi

echo "Uninstalled"
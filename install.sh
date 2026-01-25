#!/bin/bash

# Find all dot files then if the original file exists, create a backup
# Once backed up to {file}.dtbak symlink the new dotfile in place
for file in $(find . -maxdepth 1 -name ".*" -type f  -printf "%f\n" ); do
    # If it's a symlink, remove it (will be recreated)
    if [ -h ~/$file ]; then
        rm -f ~/$file
    # If it's a regular file/directory, back it up
    elif [ -e ~/$file ]; then
        mv -f ~/$file{,.dtbak}
    fi
    ln -s $PWD/$file ~/$file
done

# Sync .config subdirectories
config_root="$HOME/.config"
mkdir -p "$config_root"
if [ -d ".config" ]; then
    for dir in $(ls -d .config/*/); do
        target_dir=$(basename "$dir")
        echo "Syncing config for $target_dir"
        ln -snf "$PWD/.config/$target_dir" "$config_root/$target_dir"
    done
fi

echo "Installed"

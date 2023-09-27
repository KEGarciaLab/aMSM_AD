#!/bin/bash

# Set the root directory to search for files
root_directory="D:\Desktop\Work\Data\Test"

# Create a logs directory if it doesn't exist
logs_directory="logs"
mkdir -p "$logs_directory"

# Generate the current date and time in the desired format
current_datetime=$(date +"%m-%d-%y_%H:%M")

# Log file to store renamed files with the current date and time
log_file="$logs_directory/renamed_files_$current_datetime.txt"

# Use find to search for files containing ".LR." and rename them to ".ANATgrid."
find "$root_directory" -type f -name "*.LR.*" -exec bash -c 'source_file="$1"; new_name="${source_file//.LR./.ANATgrid.}"; mv "$source_file" "$new_name"; echo "Renamed: $source_file -> $new_name" && echo "Renamed: $source_file -> $new_name" >> "$2"' _ {} "$log_file" \;

# Use find to search for files containing ".LLR." and rename them to ".CPgrid."
find "$root_directory" -type f -name "*.LLR.*" -exec bash -c 'source_file="$1"; new_name="${source_file//.LLR./.CPgrid.}"; mv "$source_file" "$new_name"; echo "Renamed: $source_file -> $new_name" && echo "Renamed: $source_file -> $new_name" >> "$2"' _ {} "$log_file" \;

echo "Renaming completed. Check $log_file for details."

#!/bin/bash

########## DEFINE VARIABLES
DATASET=/N/project/aMSM/ADNI/Data/3T_Analysis/ciftify # Folder containing subject data
PREFIX="Subject" # Prefix to prepend to each subject ID
CURRENT_DATETIME=$(date +'%Y-%m-%d_%H-%M-%S') # Date and time will be appended to the text file so multiple runs keep data separate
OUTPUT_DIR=${HOME}/Scripts/MyScripts/Output/$(basename "$0") # Output location
OUTPUT_FILE=${OUTPUT_DIR}/subject_numbers.txt # Output file name

########## CREATE OUTPUT DIRECTORY
mkdir -p "$OUTPUT_DIR"

########## FIND ALL SUBJECTS
# Use find to search only within the specified dataset directory, extract subject numbers, and remove duplicates
find "$DATASET" -maxdepth 1 -type d -name "${PREFIX}_[0-9]*" | awk -F'/' '{print $NF}' | awk -F'_' '{print $2}' | sort -u > "$OUTPUT_FILE"

########## WRITE TO .txt FILE
# Combine the subject numbers into a single line separated by spaces
subjects=$(cat "$OUTPUT_FILE" | tr '\n' ' ' | sed 's/ $/\n/')

# Write the subjects to the output file
echo "$subjects" > "$OUTPUT_FILE"

echo "Subject numbers written to $OUTPUT_FILE"

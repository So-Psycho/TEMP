#!/bin/bash

# Configuration
DATA_DIR="EPSTEIN-DATA"
INPUT_FILE="sources_manifest.txt"
LOG_FILE="download_log.txt"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Epstein Estate Data Downloader...${NC}"

# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo -e "${RED}Error: Input file '$INPUT_FILE' not found.${NC}"
    echo "Please create '$INPUT_FILE' with the format: Subfolder|Filename|PrimaryURL|SecondaryURL"
    exit 1
fi

# Create main directory
if [[ ! -d "$DATA_DIR" ]]; then
    echo "Creating main directory: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

# Initialize counters
total_files=0
success_count=0
fail_count=0

# Read the input file line by line
# Expected format: Subfolder | Filename | Primary_URL | Secondary_URL
while IFS='|' read -r subfolder filename url1 url2 || [ -n "$subfolder" ]; do
    # Trim whitespace
    subfolder=$(echo "$subfolder" | xargs)
    filename=$(echo "$filename" | xargs)
    url1=$(echo "$url1" | xargs)
    url2=$(echo "$url2" | xargs)

    # Skip empty lines or comments
    if [[ -z "$subfolder" || "$subfolder" == \#* ]]; then
        continue
    fi

    ((total_files++))

    target_dir="$DATA_DIR/$subfolder"
    target_file="$target_dir/$filename"

    # Create sub-directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi

    # Check if file already exists
    if [[ -f "$target_file" ]]; then
        echo -e "${YELLOW}[SKIP] $filename already exists.${NC}"
        continue
    fi

    echo "Downloading $filename to $subfolder..."

    # Attempt Primary URL
    if wget -q --show-progress -O "$target_file" "$url1"; then
        echo -e "${GREEN}[OK] Downloaded from Primary URL.${NC}"
        ((success_count++))
    else
        echo -e "${YELLOW}[WARN] Primary URL failed. Trying Secondary URL...${NC}"

        # Attempt Secondary URL
        if wget -q --show-progress -O "$target_file" "$url2"; then
             echo -e "${GREEN}[OK] Downloaded from Secondary URL.${NC}"
             ((success_count++))
        else
            echo -e "${RED}[FAIL] Both URLs failed for $filename.${NC}"
            echo "$(date): Failed to download $filename ($url1, $url2)" >> "$LOG_FILE"
            # Clean up empty file if created
            rm -f "$target_file"
            ((fail_count++))
        fi
    fi

done < "$INPUT_FILE"

echo "------------------------------------------------"
echo -e "${GREEN}Download Complete.${NC}"
echo "Total processed: $total_files"
echo "Successful: $success_count"
echo "Failed: $fail_count"
echo "Check $LOG_FILE for details on failures."

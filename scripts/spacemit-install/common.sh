#!/bin/bash
# Script to install dependencies using wget from SDK_URL and extract to EXTRACT_DIR if not present yet
# Usage: ./common.sh -u <SDK_URL> -h <EXPECTED_HASH> -z <ZIP_DIR> -e <EXTRACT_DIR>

# Parse command line options
SDK_URL=$2
EXPECTED_HASH=$4
ZIP_DIR=$6
EXTRACT_DIR=$8

SDK_FILENAME=$(basename "$SDK_URL")
HASH_FILE="$ZIP_DIR/.${SDK_FILENAME}.sha256"

echo "Processing SDK from $SDK_URL"
mkdir -p "$ZIP_DIR"
mkdir -p "$EXTRACT_DIR"

DOWNLOAD_NEEDED=false
EXTRACT_NEEDED=false

# Determine if we need to download
if [ ! -f "$ZIP_DIR/$SDK_FILENAME" ]; then
    echo "Archive doesn't exist, download needed."
    DOWNLOAD_NEEDED=true
elif [ -n "$EXPECTED_HASH" ]; then
    ACTUAL_HASH=$(sha256sum "$ZIP_DIR/$SDK_FILENAME" | awk '{ print $1 }')
    if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
        echo "Hash mismatch, download needed."
        echo "Expected: $EXPECTED_HASH"
        echo "Actual:   $ACTUAL_HASH"
        DOWNLOAD_NEEDED=true
    else
        echo "Archive exists with matching hash, skipping download."
    fi
fi

# Download if needed
if [ "$DOWNLOAD_NEEDED" = true ]; then
    echo "Downloading archive..."
    wget "$SDK_URL" -O "$ZIP_DIR/$SDK_FILENAME" --no-check-certificate
    
    if [ $? -ne 0 ]; then
        echo "Error: Download failed."
        exit 1
    fi
    
    if [ -n "$EXPECTED_HASH" ]; then
        ACTUAL_HASH=$(sha256sum "$ZIP_DIR/$SDK_FILENAME" | awk '{ print $1 }')
        if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
            echo "Error: Downloaded file hash doesn't match expected hash."
            echo "Expected: $EXPECTED_HASH"
            echo "Actual:   $ACTUAL_HASH"
            exit 1
        fi
    fi
fi

# Determine if extraction is needed
FILENAME_NOEXT="${SDK_FILENAME%.tar.gz}"
FILENAME_NOEXT="${FILENAME_NOEXT%.tgz}"
FILENAME_NOEXT="${FILENAME_NOEXT%.tar.xz}"  # Add support for .tar.xz files
if [ ! -d "$EXTRACT_DIR/$FILENAME_NOEXT" ]; then
    EXTRACT_NEEDED=true
fi

# Extract if needed
if [ "$EXTRACT_NEEDED" = true ]; then
    echo "Extracting to $EXTRACT_DIR..."
    
    # Select extraction method based on file extension
    if [[ "$SDK_FILENAME" == *.tar.xz ]]; then
        tar -xJf "$ZIP_DIR/$SDK_FILENAME" -C "$EXTRACT_DIR/"
    else
        tar -xzf "$ZIP_DIR/$SDK_FILENAME" -C "$EXTRACT_DIR/"
    fi
    
    if [ $? -ne 0 ]; then
        echo "Error: Extraction failed."
        exit 1
    fi
    echo "Extraction completed."
else
    echo "Target directory already exists, skipping extraction."
fi

echo "Installation completed successfully!"
exit 0
#!/bin/bash
# Script to install SpacemiT AI SDK v1.1.0 via common script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/common.sh"

# SpacemiT AI SDK specific parameters
SDK_URL="https://archive.spacemit.com/spacemit-ai/spacemit-ai-sdk/spacemit-ai-sdk.v1.1.0.x86_64.tar.gz"
SDK_HASH="4805803455bddf95dfcba5ae69f717eb3960daa79bce67304581c9cf98f5ed8c"
ZIP_DIR="./spacemit/zips"
EXTRACT_DIR="./spacemit"

echo "Installing SpacemiT AI SDK v1.1.0..."

# Make common script executable
chmod +x "$COMMON_SCRIPT"

# Call the common script with parameters
bash "$COMMON_SCRIPT" -u "$SDK_URL" -h "$SDK_HASH" -z "$ZIP_DIR" -e "$EXTRACT_DIR"

if [ $? -eq 0 ]; then
    echo "SpacemiT AI SDK installation successful!"
    SDK_PATH="../../spacemit/spacemit-ai-sdk.v1.1.0"
    echo "SDK available at: $SDK_PATH"
else
    echo "Installation failed."
    exit 1
fi
#!/bin/bash
# Script to install SpacemiT toolchain v1.0.1 via common script


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/common.sh"

# SpacemiT AI SDK specific parameters
SDK_URL="https://archive.spacemit.com/toolchain/spacemit-toolchain-linux-glibc-x86_64-v1.0.1.tar.xz"
SDK_HASH="e6375782572a8288d75a8699c45972241820a65061fdb03f5e4a714511cb0b05"
ZIP_DIR="./spacemit/zips"
EXTRACT_DIR="./spacemit"

echo "Installing SpacemiT toolchain 1.0.1 ..."

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
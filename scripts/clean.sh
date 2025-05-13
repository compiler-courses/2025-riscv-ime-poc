#!/bin/bash
# Script to clean build directory

# Default build directory
BUILD_DIR="build"

# Check if an argument was provided
if [ $# -eq 1 ]; then
  BUILD_DIR="$1"
fi

echo "Cleaning build directory: $BUILD_DIR"

# Check if directory exists before removing
if [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
  echo "Build directory removed successfully."
else
  echo "No build directory found at $BUILD_DIR, nothing to clean."
fi

echo "Clean completed!"
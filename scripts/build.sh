#!/bin/bash
# build CMake project for RISC-V
set -e  # Exit on any error

# Default build directory
BUILD_DIR="build"

# Check if an argument was provided for build directory
if [ $# -eq 1 ]; then
  BUILD_DIR="$1"
fi

echo "Using build directory: $BUILD_DIR"

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure CMake
cmake .. \
  -DCMAKE_C_COMPILER="$RISCV_GCC" \
  -DCMAKE_CXX_COMPILER="$RISCV_GXX" \
  -DCMAKE_C_FLAGS="$RISCV_CFLAGS" \
  -DCMAKE_CXX_FLAGS="$RISCV_CXXFLAGS" \
  -DCMAKE_ASM_FLAGS="$CMAKE_ASM_FLAGS"

# Build
make -j$(nproc)

echo "Build completed successfully!"
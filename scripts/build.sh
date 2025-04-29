# build CMake project for RISC-V
set -e  # Exit on any error

# Create build directory if it doesn't exist
mkdir -p build
cd build

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
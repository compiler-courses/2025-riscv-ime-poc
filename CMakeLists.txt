cmake_minimum_required(VERSION 3.15)

# Cross-compilation setup
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR riscv64)

# Only look for toolchain if not explicitly set
if(NOT CMAKE_C_COMPILER OR NOT CMAKE_CXX_COMPILER)
    # Try to find RISC-V toolchain (look for SpaceMIT SDK variants first)
    find_program(CMAKE_C_COMPILER NAMES riscv64-unknown-linux-gnu-gcc riscv64-none-elf-gcc riscv64-unknown-elf-gcc)
    find_program(CMAKE_CXX_COMPILER NAMES riscv64-unknown-linux-gnu-g++ riscv64-none-elf-g++ riscv64-unknown-elf-g++)
    find_program(CMAKE_ASM_COMPILER NAMES riscv64-unknown-linux-gnu-gcc riscv64-none-elf-gcc riscv64-unknown-elf-gcc)

    if(NOT CMAKE_C_COMPILER OR NOT CMAKE_CXX_COMPILER OR NOT CMAKE_ASM_COMPILER)
        message(FATAL_ERROR "RISC-V toolchain not found. Make sure you're in the nix-shell environment.")
    endif()
endif()

# Define project after setting up compilers
project(RISCV_IME VERSION 0.1.0 LANGUAGES C CXX ASM)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use environment flags if needed
set(CMAKE_C_FLAGS $ENV{CMAKE_C_FLAGS})
set(CMAKE_CXX_FLAGS $ENV{CMAKE_CXX_FLAGS})
set(CMAKE_ASM_FLAGS $ENV{CMAKE_ASM_FLAGS})

# Static linking
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")

# Create main library
add_library(matrix_mul
    src/asm/naive/matmul_naive_float.S
    src/asm/vector/matmul_vector_float.S
    
    # Naive integer implementations
    src/asm/naive/int/matmul_naive_int8.S
    src/asm/naive/int/matmul_naive_int16.S
    src/asm/naive/int/matmul_naive_int32.S

    # Vector integer implementations
    src/asm/vector/int/matmul_vector_int8.S
    src/asm/vector/int/matmul_vector_int16.S
    src/asm/vector/int/matmul_vector_int32.S
)

# Set include directories
target_include_directories(matrix_mul PUBLIC src)
target_include_directories(matrix_mul PUBLIC src/hpp)

# Create executable
add_executable(matmul_demo src/main.cpp)
target_link_libraries(matmul_demo PRIVATE matrix_mul)

# QEMU target
add_custom_target(run
    COMMAND ${CMAKE_COMMAND} -E env PATH=${CMAKE_CURRENT_SOURCE_DIR}/../.bin:$ENV{PATH} 
            run-qemu-fhs $<TARGET_FILE:matmul_demo>
    DEPENDS matmul_demo
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Running with QEMU"
)
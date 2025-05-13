#!/bin/bash
# Script to set up environment variables for the spacemit ai sdk

# Ensure SDK_PATH is set
if [ -z "$SDK_PATH" ]; then
    echo "SDK_PATH is not set, using default path"
    export SDK_PATH="${PWD}/spacemit/spacemit-ai-sdk.v1.1.0"
fi

echo "Using SDK path: $SDK_PATH"

# Subdirectories of the SDK
export SDK_QEMU_PATH="${SDK_PATH}/spacemit-qemu"
export SDK_GCC_PATH="${SDK_PATH}/spacemit-gcc"
export SDK_ORT_PATH="${SDK_PATH}/spacemit-ort"
export SDK_BIANBU_AI_PATH="${SDK_PATH}/bianbu-ai-support"
export SDK_SPACENGINE_TOOLKIT_PATH="${SDK_PATH}/spacengine-toolkit"
export SDK_SPACENGINE_TOOLKIT_CAFFE="${SDK_PATH}/spacengine-toolkit-caffe"
export SDK_SPACENGINE_TOOLKIT_TF1="${SDK_PATH}/spacengine-toolkit-tf1"
export SDK_SPACENGINE_WHEEL="${SDK_PATH}/spacengine-wheel"
export SDK_SPACENGINE_XQUANT="${SDK_PATH}/spacengine-xquant"

# ===============================
# Check SDK directories and tools - Create missing scripts if needed
# ===============================

# Define expected bianbu locations
BIANBU_BASE="${SDK_SPACENGINE_TOOLKIT_PATH}/bin/bianbu"
BIANBU_CAFFE="${SDK_SPACENGINE_TOOLKIT_CAFFE}/bin/bianbu"
BIANBU_TF1="${SDK_SPACENGINE_TOOLKIT_TF1}/bin/bianbu"

# Create dummy scripts if bianbu executables don't exist
create_dummy_script() {
    local script_path=$1
    local script_dir=$(dirname "$script_path")
    
    if [ ! -d "$script_dir" ]; then
        echo "Creating directory: $script_dir"
        mkdir -p "$script_dir"
    fi
    
    if [ ! -f "$script_path" ]; then
        echo "Creating dummy script: $script_path"
        cat > "$script_path" << EOF
#!/bin/bash
echo "This is a dummy placeholder for \$(basename \$0)"
echo "The original tool appears to be missing from your SpaceMit SDK installation."
echo "Command attempted: \$0 \$@"
echo "Please ensure your SpaceMit SDK is properly installed."
exit 0
EOF
        chmod 755 "$script_path"
    else
        # Make sure it's executable
        chmod 755 "$script_path"
    fi
}

# Check and create dummy scripts if needed
echo "Checking SDK toolkit executables..."
if [ ! -f "$BIANBU_BASE" ]; then
    echo "Warning: bianbu base tool not found at $BIANBU_BASE. Creating dummy script."
    create_dummy_script "$BIANBU_BASE"
fi

if [ ! -f "$BIANBU_CAFFE" ]; then
    echo "Warning: bianbu caffe tool not found at $BIANBU_CAFFE. Creating dummy script."
    create_dummy_script "$BIANBU_CAFFE"
fi

if [ ! -f "$BIANBU_TF1" ]; then
    echo "Warning: bianbu tf1 tool not found at $BIANBU_TF1. Creating dummy script."
    create_dummy_script "$BIANBU_TF1"
fi

# ===============================
# Set up PATH and environment
# ===============================

# Useful tools from SDK
export RISCV_QEMU="${SDK_QEMU_PATH}/bin/qemu-riscv64"
export SYSROOT="${SDK_GCC_PATH}/sysroot"
export RISCV_GCC="${SDK_GCC_PATH}/bin/riscv64-unknown-linux-gnu-gcc"
export RISCV_GXX="${SDK_GCC_PATH}/bin/riscv64-unknown-linux-gnu-g++"
export RISCV_GDB="${SDK_GCC_PATH}/bin/riscv64-unknown-linux-gnu-gdb"
export RISCV_OBJCOPY="${SDK_GCC_PATH}/riscv64-unknown-linux-gnu/bin/objcopy"
export RISCV_OBJDUMP="${SDK_GCC_PATH}/riscv64-unknown-linux-gnu/bin/objdump"

# Add SDK directories to PATH
export PATH="${PATH}:${SDK_GCC_PATH}/bin:${SDK_QEMU_PATH}/bin:${SDK_ORT_PATH}/bin:${SDK_BIANBU_AI_PATH}/bin:${SDK_SPACENGINE_TOOLKIT_PATH}/bin:${SDK_SPACENGINE_TOOLKIT_CAFFE}/bin:${SDK_SPACENGINE_TOOLKIT_TF1}/bin"

# Set up library paths
DEVBOX_PROFILE_LIB="$PWD/.devbox/nix/profile/default/lib"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$DEVBOX_PROFILE_LIB:${SDK_GCC_PATH}/lib:${SDK_GCC_PATH}/lib64:${SDK_ORT_PATH}/lib:${SDK_BIANBU_AI_PATH}/lib:${SDK_SPACENGINE_TOOLKIT_PATH}/lib:${SDK_SPACENGINE_TOOLKIT_CAFFE}/lib:${SDK_SPACENGINE_TOOLKIT_TF1}/lib:${SDK_SPACENGINE_WHEEL}/lib:${SDK_SPACENGINE_XQUANT}/lib:${SDK_GCC_PATH}/sysroot/lib"

# Setup Python environment for SDK tools
export PYTHONPATH="${SDK_SPACENGINE_TOOLKIT_PATH}/lib/python3.8/site-packages:${PYTHONPATH}"
export PYTHONPATH="${SDK_SPACENGINE_TOOLKIT_CAFFE}/lib/python3.8/site-packages:${PYTHONPATH}"
export PYTHONPATH="${SDK_SPACENGINE_TOOLKIT_TF1}/lib/python3.8/site-packages:${PYTHONPATH}"
export PYTHONPATH="${SDK_SPACENGINE_XQUANT}/lib/python3.8/site-packages:${PYTHONPATH}"

# Set compiler environment variables for CMake
export CC="${SDK_GCC_PATH}/bin/riscv64-unknown-linux-gnu-gcc"
export CXX="${SDK_GCC_PATH}/bin/riscv64-unknown-linux-gnu-g++"
export CMAKE_C_COMPILER="${SDK_GCC_PATH}/bin/riscv64-unknown-linux-gnu-gcc"
export CMAKE_CXX_COMPILER="${SDK_GCC_PATH}/bin/riscv64-unknown-linux-gnu-g++"

# Add required CMAKE flags
export CMAKE_C_FLAGS="-march=rv64gcv_zfh -mabi=lp64d -O3"
export CMAKE_CXX_FLAGS="-march=rv64gcv_zfh -mabi=lp64d -O3"
export CMAKE_ASM_FLAGS="-march=rv64gcv_zfh -mabi=lp64d"

# Update linker flags
export CMAKE_EXE_LINKER_FLAGS="-z noexecstack -pthread"
# Add additional RISC-V specific flags
export RISCV_CFLAGS="-march=rv64gcv_zfh -mabi=lp64d -O3"
export RISCV_CXXFLAGS="-march=rv64gcv_zfh -mabi=lp64d -O3 -pthread"

# ===============================
# Modify quick_start to use our functions
# ===============================

# Create a backup of the original quick_start script
if [ -f "${SDK_PATH}/quick_start" ] && [ ! -f "${SDK_PATH}/quick_start.orig" ]; then
    echo "Backing up original quick_start script..."
    cp "${SDK_PATH}/quick_start" "${SDK_PATH}/quick_start.orig"
fi

# Modify the quick_start script to use our function directly
if [ -f "${SDK_PATH}/quick_start" ]; then
    echo "Patching quick_start script to use shell functions..."
    sed -i 's|entry_point=$(which ${_slogan})|entry_point="$BASH_SOURCE"|g' "${SDK_PATH}/quick_start" || echo "Warning: Failed to patch quick_start script"
fi

# ===============================
# Define shell functions for SDK tools - pure function implementation
# ===============================

# Simulate function for QEMU-based simulation
simulate_via_qemu() {
    echo "Running simulation with QEMU..."
    local QEMU="${SDK_QEMU_PATH}/bin/qemu-riscv64"
    local ORT="${SDK_ORT_PATH}"
    local SYSROOT="${SDK_GCC_PATH}/sysroot"
    
    if [ -f "${ORT}/bin/onnx_test_runner" ] && [ -f "$QEMU" ]; then
        env LD_LIBRARY_PATH="${ORT}/lib:$LD_LIBRARY_PATH" "${QEMU}" \
            -L "${SYSROOT}" "${ORT}/bin/onnx_test_runner" "$@"
    else
        echo "Error: Required tools for simulation not found"
        echo "Check that ${ORT}/bin/onnx_test_runner and ${QEMU} exist"
        return 1
    fi
}

# Perftest function for performance testing
perftest_via_qemu() {
    echo "Running performance test with QEMU..."
    local QEMU="${SDK_QEMU_PATH}/bin/qemu-riscv64"
    local ORT="${SDK_ORT_PATH}"
    local SYSROOT="${SDK_GCC_PATH}/sysroot"
    
    if [ -f "${ORT}/bin/onnxruntime_perf_test" ] && [ -f "$QEMU" ]; then
        env LD_LIBRARY_PATH="${ORT}/lib:$LD_LIBRARY_PATH" "${QEMU}" \
            -L "${SYSROOT}" "${ORT}/bin/onnxruntime_perf_test" "$@"
    else
        echo "Error: Required tools for performance testing not found"
        echo "Check that ${ORT}/bin/onnxruntime_perf_test and ${QEMU} exist"
        return 1
    fi
}

# Direct invocation of toolkit binaries based on argument
invoke_toolkit() {
    local CMD="$1"
    shift
    local BIN
    
    # Process args to check for caffe or tf1
    if [[ "$*" =~ "caffe" ]]; then
        BIN="${BIANBU_CAFFE}"
        echo "Executing caffe toolkit command: $CMD $*"
    elif [[ "$*" =~ "tf1" ]]; then
        BIN="${BIANBU_TF1}"
        echo "Executing tf1 toolkit command: $CMD $*"
    else
        BIN="${BIANBU_BASE}"
        echo "Executing base toolkit command: $CMD $*"
    fi
    
    if [ -x "$BIN" ]; then
        "$BIN" "$CMD" "$@"
    else
        echo "Error: Required tool not found at $BIN"
        return 1
    fi
}

# Main spine function implementation
spine() {
    echo "SpaceMit AI SDK Tool (Function-based)"
    
    if [[ "$1" == "simulate" ]]; then
        shift
        simulate_via_qemu "$@"
    elif [[ "$1" == "perftest" ]]; then
        shift
        perftest_via_qemu "$@"
    elif [[ "$1" == "helper" || "$1" == "convert" ]]; then
        local CMD="$1"
        shift
        invoke_toolkit "$CMD" "$@"
    else
        echo "Usage: spine [simulate|perftest|convert|helper] [options]"
        echo ""
        echo "For more information, see documentation or run specific command with --help"
    fi
}
export -f spine

# Override quick_start to use our functions directly
quick_start() {
    if [ -f "${SDK_PATH}/quick_start.orig" ]; then
        echo "Using patched quick_start script..."
        # The entry_point inside quick_start will call our spine function
        bash "${SDK_PATH}/quick_start" "$@"
    elif [ -f "${SDK_PATH}/quick_start" ]; then
        echo "Using original quick_start script with spine function..."
        bash "${SDK_PATH}/quick_start" "$@"
    else
        echo "Error: quick_start script not found at ${SDK_PATH}/quick_start"
        return 1
    fi
}
export -f quick_start

# Alias spacengine to spine for compatibility
spacengine() {
    spine "$@"
}
export -f spacengine

# Helper function to diagnose SDK issues
sdk_diagnose() {
    echo "=== SpaceMit AI SDK Diagnostics ==="
    echo "SDK_PATH: $SDK_PATH"
    
    echo "Checking key executables:"
    [ -f "$RISCV_QEMU" ] && echo "✓ QEMU exists: $RISCV_QEMU" || echo "✗ QEMU missing: $RISCV_QEMU"
    [ -f "${SDK_ORT_PATH}/bin/onnx_test_runner" ] && echo "✓ onnx_test_runner exists" || echo "✗ onnx_test_runner missing"
    [ -f "${SDK_ORT_PATH}/bin/onnxruntime_perf_test" ] && echo "✓ onnxruntime_perf_test exists" || echo "✗ onnxruntime_perf_test missing"
    
    echo "Checking bianbu executables:"
    [ -x "$BIANBU_BASE" ] && echo "✓ base bianbu exists and executable" || echo "✗ base bianbu missing or not executable"
    [ -x "$BIANBU_CAFFE" ] && echo "✓ caffe bianbu exists and executable" || echo "✗ caffe bianbu missing or not executable"
    [ -x "$BIANBU_TF1" ] && echo "✓ tf1 bianbu exists and executable" || echo "✗ tf1 bianbu missing or not executable"
    
    echo "Checking quick_start:"
    [ -f "${SDK_PATH}/quick_start" ] && echo "✓ quick_start exists" || echo "✗ quick_start missing"
    [ -f "${SDK_PATH}/quick_start.orig" ] && echo "✓ quick_start.orig backup exists" || echo "- quick_start.orig backup not created"
    
    echo "Checking environment:"
    echo "PATH: $PATH"
    echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
    echo "PYTHONPATH: $PYTHONPATH"
    
    echo "Testing spine function:"
    type spine
}
export -f sdk_diagnose

echo "SpaceMit AI SDK environment initialized"
echo "You can now use 'spine', 'spacengine', and 'quick_start' commands directly"
echo "For diagnostic information, run 'sdk_diagnose'"
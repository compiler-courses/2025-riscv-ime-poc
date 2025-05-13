# Run RISC-V binary via QEMU
# Usage: run-qemu.sh <binary> [arguments...]

set -e  # Exit on error

# Check if binary is provided
if [ $# -lt 1 ]; then
  echo "Usage: $(basename $0) <binary> [arguments...]"
  echo "Example: $(basename $0) build/matmul_demo"
  exit 1
fi

BINARY="$1"
shift  # Remove binary from arguments list

# Check if binary exists
if [ ! -f "$BINARY" ]; then
  echo "Error: Binary '$BINARY' not found"
  exit 1
fi

# Print execution info
echo "Running with QEMU: $BINARY"

# Check if RISCV_QEMU is set
if [ -z "$RISCV_QEMU" ]; then
  echo "Error: RISCV_QEMU is not set. Are you running from nix-shell?"
  exit 1
fi

# Check if SYSROOT is set
if [ -z "$SYSROOT" ]; then
  echo "Error: SYSROOT is not set. Are you running from nix-shell?"
  exit 1
fi
# $RISCV_QEMU -cpu rv64,v=true,g=true -L $SYSROOT 
# Run the binary with QEMU
# $RISCV_QEMU -s 1G -R 2G -cpu rv64,v=true,g=true -L "$SYSROOT" "$BINARY" "$@"
# $RISCV_QEMU -cpu rv64,v=true,g=true -L "$SYSROOT" "$BINARY" "$@"
$RISCV_QEMU -s 4G -R 2G -cpu rv64,v=true,vlen=128,vext_spec=v1.0 -L "$SYSROOT" "$BINARY" "$@"
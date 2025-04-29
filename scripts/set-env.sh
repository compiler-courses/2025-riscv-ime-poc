# initialize SpaceMIT SDK 

if [ -z "$SDK_PATH" ]; then
  echo "Error: SDK_PATH is not set. Are you running this from the nix-shell?"
  exit 1
fi

# Make sure we can find the SDK tools
if [ ! -d "$SDK_PATH/spacemit-gcc" ]; then
  echo "Error: SpaceMIT SDK not found at $SDK_PATH"
  exit 1
fi

# Export common variables for convenience scripts
export SYSROOT="$SDK_PATH/spacemit-gcc/sysroot"
export QEMU_CMD="qemu-riscv64 -L $SYSROOT"
export CROSS_TOOL="$SDK_PATH/spacemit-gcc/bin/riscv64-unknown-linux-gnu-"

# Print environment info
echo "SpaceMIT SDK environment is ready!"
echo "SDK location: $SDK_PATH"
echo "SYSROOT: $SYSROOT"
echo "QEMU command: $QEMU_CMD"
echo "Cross compiler prefix: $CROSS_TOOL"
echo
echo "Example usage:"
echo "  ${CROSS_TOOL}gcc -march=rv64gcv -mabi=lp64d source.c -o output"
echo "  $QEMU_CMD ./output"
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/release-24.11";
  pkgs = import nixpkgs {};

  # Use RISC-V 64-bit ELF toolchain
  # riscv64ElfGcc = pkgs.pkgsCross.riscv64-embedded.buildPackages.gcc;
  riscv64ElfGcc = pkgs.pkgsCross.riscv64.buildPackages.gcc;
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    gnumake
    gdb
    gcc
    pkg-config
    file
    
    # RISC-V specific tools
    riscv64ElfGcc  # ELF toolchain with better extension support
    qemu_full
    
    # Benchmarking and testing
    coreutils-prefixed
    gtest
    
    # Utilities
    python3
    python3Packages.matplotlib  # For visualizing benchmark results
  ];
  
  buildInputs = with pkgs; [
    zlib
  ];
  
  shellHook = ''
    # Set up RISC-V toolchain path
    export RISCV_TOOLCHAIN_PATH=${riscv64ElfGcc}
    
    # Set up QEMU environment for CLion
    export QEMU_RISCV64=${pkgs.qemu_full}/bin/qemu-riscv64
    export QEMU_SYSROOT=${riscv64ElfGcc}/sysroot
    
    # Create a QEMU runner script with vector and FP support
    mkdir -p $PWD/.bin
    cat > $PWD/.bin/run-qemu-riscv64 <<EOF
    #!/bin/bash
    exec $QEMU_RISCV64 -cpu rv64,x-v=true,x-f=true,vlen=128 -L $QEMU_SYSROOT "\$@"
    EOF
    chmod +x $PWD/.bin/run-qemu-riscv64
    export PATH="$PWD/.bin:$PATH"
    
    # Print available RISC-V extensions
    echo "RISC-V toolchain information:"
    $RISCV_TOOLCHAIN_PATH/bin/riscv64-unknown-elf-gcc -v 2>&1 | grep "Target:"
    
    # Also update CMake architecture flags for commands
    echo "export CMAKE_C_FLAGS=\"-march=rv64imafv -mabi=lp64d\"" > $PWD/.env
    echo "export CMAKE_CXX_FLAGS=\"-march=rv64imafv -mabi=lp64d\"" >> $PWD/.env
    echo "export CMAKE_ASM_FLAGS=\"-march=rv64imafv -mabi=lp64d\"" >> $PWD/.env
    
    echo "RISC-V 64-bit Matrix Multiplication Development Environment"
    echo "QEMU runner available at: run-qemu-riscv64"
    echo "Architecture flags set to: rv64imav with lp64 ABI"
  '';
}
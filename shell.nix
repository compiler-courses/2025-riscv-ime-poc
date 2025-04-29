let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/release-24.11";
  pkgs = import nixpkgs {};
  # SpaceMIT IME SDK
  spacemitImeSdk = ../spacemit/spacemit-ai-sdk.v1.1.0;

  # Locations of various SDK components
  spacemitGcc = "${spacemitImeSdk}/spacemit-gcc";
  spacemitOrt = "${spacemitImeSdk}/spacemit-ort";
  spacemitQemu = "${spacemitImeSdk}/spacemit-qemu";
  bianbuAi = "${spacemitImeSdk}/bianbu-ai-support";
  spacengineToolkit = "${spacemitImeSdk}/spacengine-toolkit";
  spacengineToolkitCaffe = "${spacemitImeSdk}/spacengine-toolkit-caffe";
  spacengineToolkitTf1 = "${spacemitImeSdk}/spacengine-toolkit-tf1";
  spacengineWheel = "${spacemitImeSdk}/spacengine-wheel";
  spacengineXquant = "${spacemitImeSdk}/spacengine-xquant";
  
  
  nixLibs = pkgs.lib.makeLibraryPath [ 
    pkgs.zlib 
    pkgs.stdenv.cc.cc.lib 
    pkgs.openssl
    pkgs.glibc
    pkgs.glib    
  ];
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    cmake
    ninja
    gnumake
    gdb
    pkg-config
    file

    hwloc #Portable abstraction of hierarchical architectures for high-performance computing; lstopo
    
    # For running external binaries
    patchelf
    glibc
    stdenv.cc.cc.lib
    zlib
    openssl
    glib    
    
    # Benchmarking and testing
    coreutils-prefixed
    gtest
    
    # Utilities
    python3
    python3Packages.matplotlib
  ];
  
  buildInputs = with pkgs; [
    zlib
  ];
  
  shellHook = ''
    # Add SpaceMIT SDK path as environment variable
    export SDK_PATH="${toString spacemitImeSdk}"
    
    # Add scripts directory to PATH
    export PATH="$PWD/scripts:$PATH"
    
    # Add SDK binaries to PATH
    export PATH="${spacemitGcc}/bin:${spacemitOrt}/bin:${spacemitQemu}/bin:${bianbuAi}/bin:${spacengineToolkit}/bin:${spacengineToolkitCaffe}/bin:${spacengineToolkitTf1}/bin:${spacengineWheel}/bin:${spacengineXquant}/bin:$PATH"
    
    # set up library paths for dynamic linking - system libs first!
    export LD_LIBRARY_PATH="${nixLibs}:${spacemitGcc}/lib:${spacemitGcc}/lib64:${spacemitOrt}/lib:${bianbuAi}/lib:${spacengineToolkit}/lib:${spacengineToolkitCaffe}/lib:${spacengineToolkitTf1}/lib:${spacengineWheel}/lib:${spacengineXquant}/lib:${spacemitGcc}/sysroot/lib:$LD_LIBRARY_PATH"
    export NIX_LD_LIBRARY_PATH="${nixLibs}:${spacemitGcc}/lib:${spacemitGcc}/lib64:${spacemitOrt}/lib:${bianbuAi}/lib:${spacengineToolkit}/lib:${spacengineToolkitCaffe}/lib:${spacengineToolkitTf1}/lib:${spacengineWheel}/lib:${spacengineXquant}/lib:${spacemitGcc}/sysroot/lib:$NIX_LD_LIBRARY_PATH"
    
    # Set up nix-ld - required for dynamic libraries on NixOS
    export NIX_LD="$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)"
    export SYSROOT="${spacemitGcc}/sysroot"
    
    # Ensure scripts are executable
    if [ -d "$PWD/scripts" ]; then
      chmod +x $PWD/scripts/*
    fi
    
    # Set up CMake environment
    export CMAKE_PREFIX_PATH="${spacemitGcc}:${spacemitOrt}:${bianbuAi}:${spacengineToolkit}:${spacengineToolkitCaffe}:${spacengineToolkitTf1}:${spacengineWheel}:${spacengineXquant}:$CMAKE_PREFIX_PATH"
    
    # Set compiler environment variables for CMake
    export CC="${spacemitGcc}/bin/riscv64-unknown-linux-gnu-gcc"
    export CXX="${spacemitGcc}/bin/riscv64-unknown-linux-gnu-g++"
    export CMAKE_C_COMPILER="${spacemitGcc}/bin/riscv64-unknown-linux-gnu-gcc"
    export CMAKE_CXX_COMPILER="${spacemitGcc}/bin/riscv64-unknown-linux-gnu-g++"
    export CMAKE_C_FLAGS="-march=rv64gcv -mabi=lp64d -O2"
    export CMAKE_CXX_FLAGS="-march=rv64gcv -mabi=lp64d -O2"
    export CMAKE_ASM_FLAGS="-march=rv64gcv -mabi=lp64d"
    
    # Add variables expected by scripts
    export RISCV_GCC="${spacemitGcc}/bin/riscv64-unknown-linux-gnu-gcc"
    export RISCV_GXX="${spacemitGcc}/bin/riscv64-unknown-linux-gnu-g++"
    export RISCV_GDB="${spacemitGcc}/bin/riscv64-unknown-linux-gnu-gdb"
    
    export RISCV_QEMU="${spacemitQemu}/bin/qemu-riscv64"

    export RISCV_CFLAGS="-march=rv64gcv -mabi=lp64d -O2"
    export RISCV_CXXFLAGS="-march=rv64gcv -mabi=lp64d -O2"
    export RISCV_OBJCOPY="${spacemitGcc}/riscv64-unknown-linux-gnu/bin/objcopy"
    export RISCV_OBJDUMP="${spacemitGcc}/riscv64-unknown-linux-gnu/bin/objdump"
    
    
    # Add alias for building Cmake project
    alias build='scripts/build-cmake.sh'
    
    # Run setup script to verify environment
    scripts/set-env.sh
  '';
}
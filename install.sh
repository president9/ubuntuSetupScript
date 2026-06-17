#!/bin/bash
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

set -eE
trap 'echo ""; echo "Script failed at line $LINENO"; exit 1' ERR

confirm() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  read -r -p "Proceed? [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]]
}

if confirm "STEP 1: Update & upgrade system packages + autoinstall GPU drivers ?"; then
  apt update
  apt upgrade -y
  ubuntu-drivers autoinstall
else
  echo "Skipped."
fi

# basic tools
if confirm "STEP 2: Install dev tools (git, build-essential, ninja, cmake, pip) ?"; then
  apt install -y git-all
  apt install -y build-essential
  apt install -y ninja-build
  apt install -y cmake
  apt install -y python3-pip
else
  echo "Skipped."
fi

# cuda
if confirm "STEP 3: Download & install CUDA 13.3.0 (requires manual EULA acceptance) ?"; then
  wget https://developer.download.nvidia.com/compute/cuda/13.3.0/local_installers/cuda_13.3.0_610.43.02_linux.run
  sh cuda_13.3.0_610.43.02_linux.run
  # Script pauses here for your EULA interaction, then continues automatically.
  export PATH=/usr/local/cuda/bin:$PATH
  export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
else
  echo "Skipped."
fi

#llama.cpp CUDA + RPC
if confirm "STEP 4: Clone & build llama.cpp (with CUDA + RPC support) ?"; then
  cd "$REAL_HOME" || exit 1
  git clone https://github.com/ggml-org/llama.cpp
  cd "$REAL_HOME/llama.cpp" || exit 1
  cmake -B build -DGGML_CUDA=ON -DGGML_RPC=ON -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc -DLLAMA_PERF=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo
  cmake --build build --config RelWithDebInfo -j"$(nproc)"
else
  echo "Skipped."
fi

echo ""
echo "Done."

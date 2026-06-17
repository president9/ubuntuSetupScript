#!/bin/bash
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)
REAL_BASHRC="$REAL_HOME/.bashrc"

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

append_bashrc() {
  local line="$1"
  # Only append if not already present
  grep -qxF "$line" "$REAL_BASHRC" 2>/dev/null || echo "$line" >> "$REAL_BASHRC"
}

if confirm "STEP 1: Update & upgrade system packages + autoinstall GPU drivers?"; then
  apt update
  apt upgrade -y
  ubuntu-drivers autoinstall
  echo ""
  echo "Please REBOOT before continuing, then re-run this script."
else
  echo "Skipped."
fi

# Basic tools
if confirm "STEP 2: Install dev tools (git, build-essential, ninja, cmake, pip, openssh)?"; then
  apt install -y git-all
  apt install -y build-essential
  apt install -y ninja-build
  apt install -y cmake
  apt install -y python3-pip
  apt install -y openssh-server
  apt install -y python3.12-venv
  snap install nvim --classic
else
  echo "Skipped."
fi

# Cuda
if confirm "STEP 3: Download & install CUDA 13.3.0 (requires manual EULA acceptance)?"; then
  cd "$REAL_HOME" || exit 1
  wget https://developer.download.nvidia.com/compute/cuda/13.3.0/local_installers/cuda_13.3.0_610.43.02_linux.run
  bash cuda_13.3.0_610.43.02_linux.run

  # Persist CUDA to the real user's bashrc (not root's)
  append_bashrc 'export PATH=/usr/local/cuda/bin:$PATH'
  append_bashrc 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}'

  # Apply to current session so cmake can find nvcc in the next step
  export PATH=/usr/local/cuda/bin:$PATH
  export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
else
  echo "Skipped."
fi

# llama.cpp CUDA + RPC
if confirm "STEP 4: Clone & build llama.cpp (with CUDA + RPC support)?"; then
  cd "$REAL_HOME" || exit 1

  if [ -d "$REAL_HOME/llama.cpp" ]; then
    echo "llama.cpp already exists, pulling latest..."
    cd "$REAL_HOME/llama.cpp" && git pull
  else
    git clone https://github.com/ggml-org/llama.cpp
    cd "$REAL_HOME/llama.cpp" || exit 1
  fi

  cmake -B build \
    -DGGML_CUDA=ON \
    -DGGML_RPC=ON \
    -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build --config Release -j"$(nproc)"
  
  # Used sudo to create so remove its sudoness
  chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/llama.cpp"
  
  # Persist to real user's bashrc
  append_bashrc "export PATH=\"$REAL_HOME/llama.cpp/build/bin:\$PATH\""
  
  # Apply to current session
  export PATH="$REAL_HOME/llama.cpp/build/bin:$PATH"
else
  echo "Skipped."
fi

# ComfyUI CUDA
if confirm "STEP 5: Clone & build ComfyUI (CUDA support) ?"; then
  cd "$REAL_HOME" || exit 1

  if [ -d "$REAL_HOME/ComfyUI" ]; then
    echo "ComfyUI already exists, pulling latest..."
    cd "$REAL_HOME/ComfyUI" && git pull
    echo "You must update nodes manually"
  else
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd "$REAL_HOME/ComfyUI" || exit 1
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    pip3 install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu132
    git clone https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/comfyui-manager
    pip install sageattention
    deactivate
  fi

  chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/ComfyUI"
else
  echo "Skipped."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run this to apply PATH changes to your current session:"
echo "  source $REAL_BASHRC"
echo ""

# Local AI workspace installer
Automates building llama.cpp and ComfyUI on Ubuntu 22/24.04.

## Requirements
- Ubuntu 22/24.04 
- CUDA-compatible NVIDIA GPU

## Usage
```bash
sudo bash install.sh
```

## Steps
1. Update packages + autoinstall GPU drivers *(reboot recommended after)*
2. Install dev tools (git, cmake, ninja, pip, openssh)
3. Download + install CUDA 13.3.0
4. Clone + build llama.cpp (CUDA + RPC) 

## After install
```bash
source ~/.bashrc
```

##  Other remarks
The team and I have saved a lot of time using this script...

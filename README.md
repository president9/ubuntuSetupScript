# llama.cpp installer

Automates building llama.cpp with CUDA + RPC support on Ubuntu 22/24.04.

## Usage
```bash
sudo bash install.sh
```

## Steps
1. Update packages + autoinstall GPU drivers *(reboot recommended after)*
2. Install dev tools (git, cmake, ninja, pip, openssh)
3. Download + install CUDA 13.3.0
4. Clone + build llama.cpp (CUDA + RPC) 

Remember to source after step 3 and 4.

## After install
```bash
source ~/.bashrc
```

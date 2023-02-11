#!/bin/bash

# Debug
#set -x
set -Eeo pipefail

##################################################
### Comment this line to disable static binary ###
STATIC_BUILD=1
##################################################

# Check os
OS_TYPE=$(hostnamectl | grep -F "Operating System:")

# Check for minisign
if command -v minisign &> /dev/null; then
  echo "Minisign $(minisign -v | cut -d " " -f 2) already installed to $(which minisign)"
  exit
elif (echo "$OS_TYPE" | grep -qF "Fedora"); then
  echo "Installing minisign via package manager..."
  sudo dnf install -y minisign >/dev/null
  echo "Installed minisign $(minisign -v | cut -d " " -f 2) via package manager"
  exit
else
  echo "Minisign not found, starting to build and install from source:"
fi

# Install build tools
if ! command -v cmake &> /dev/null || \
  ! command -v pkg-config &> /dev/null || \
  ! command -v gcc &> /dev/null || \
  ! command -v unzip &> /dev/null; then
  if (echo "$OS_TYPE" | grep -qF "Fedora"); then
    echo "Installing build dependencies via dnf..."
    sudo dnf install -y build-essential cmake pkg-config unzip >/dev/null
  elif (echo "$OS_TYPE" | grep -qF "Debian"); then
    echo "Installing build dependencies via apt..."
    sudo apt-get update >/dev/null
    sudo apt-get install -y build-essential cmake pkg-config unzip >/dev/null
  else
    echo "Error, please make sure the following packages are installed:
    - cmake
    - unzip
    - pkg-config
    - build-essential"
    exit 1
  fi
fi

# Install libsodium
SODIUM_DIR="/tmp/libsodium-stable"
SODIUM_TAR="$SODIUM_DIR.tar.gz"
SODIUM_SIG="$SODIUM_TAR.minisig"
SODIUM_LINK="https://download.libsodium.org/libsodium/releases/LATEST.tar.gz"
SODIUM_SIG_LINK="$SODIUM_LINK.minisig"
echo "Downloading libsodium sources..."
wget -q "$SODIUM_LINK" -O "$SODIUM_TAR"
wget -q "$SODIUM_SIG_LINK" -O "$SODIUM_SIG"
rm -rf "$SODIUM_DIR"
echo "Unpacking libsodium sources..."
tar -xf "$SODIUM_TAR" -C "$(dirname "$SODIUM_DIR")"
cd "$SODIUM_DIR" || exit 1
# Build libsodium
echo "Building libsodium sources..."
./configure >/dev/null
make >/dev/null
echo "Installing libsodium from source..."
sudo make install >/dev/null

# Install minisign
MINI_DIR="/tmp/minisign-master"
MINI_ZIP="/tmp/minisign.zip"
MINI_LINK="https://github.com/jedisct1/minisign/archive/refs/heads/master.zip"
echo "Downloading minisign sources..."
wget -q "$MINI_LINK" -O "$MINI_ZIP"
rm -rf "$MINI_DIR"
echo "Unpacking minisign sources..."
unzip -q "$MINI_ZIP" -d "$(dirname "$MINI_DIR")"
rm -f "$MINI_ZIP"
mkdir -p "$MINI_DIR/build"
cd "$MINI_DIR/build" || exit 1
echo "Building minisign sources..."
if [[ "$STATIC_BUILD" -eq 1 ]]; then
  cmake -D BUILD_STATIC_EXECUTABLES=1 .. >/dev/null
else
  cmake .. >/dev/null
fi
make
echo "Installing minisign from source..."
sudo make install >/dev/null

# Notify of completion
echo "
--------------------------------------------------------------------------------
Finished, minisign $(minisign -v | cut -d " " -f 2) has been installed to: $(which minisign)
Testing minisign by verifying the downloaded libsodium library:
"
minisign -VP RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3 -m "$SODIUM_TAR"
rm -f "$SODIUM_TAR"
rm -f "$SODIUM_SIG"
rm -rf "$SODIUM_DIR"
rm -rf "$MINI_DIR"
echo "--------------------------------------------------------------------------------"

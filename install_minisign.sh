#!/bin/bash

# Debug
#set -x
set -Eeo pipefail

# Get script dir
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
OS_TYPE=$(hostnamectl | grep -F "Operating System:")

# Check for minisign
if command -v minisign &> /dev/null; then
  echo "Minisign already installed, exiting:
  $(minisign -v)"
  exit
elif (echo "$OS_TYPE" | grep -qF "Fedora"); then
  sudo dnf install -y minisign
  echo "Done, installed minisign via package manager"
  exit
fi
echo "Building minisign from source..."

# Install build tools
if ! command -v cmake &> /dev/null || \
  ! command -v pkg-config &> /dev/null || \
  ! command -v gcc &> /dev/null || \
  ! command -v unzip &> /dev/null; then
  if (echo "$OS_TYPE" | grep -qF "Fedora"); then
    sudo dnf install -y build-essential cmake pkg-config unzip
  elif (echo "$OS_TYPE" | grep -qF "Debian"); then
    sudo apt update
    sudo apt install -y build-essential cmake pkg-config unzip
  else
    echo "Error, please make sure the following packages are installed:
    - cmake
    - unzip
    - pkg-config
    - build-essential"
  fi
fi

# TODO: Add post-install verification of libsodium minisig?
# Install libsodium
SODIUM_TAR="/tmp/libsodium.tar.gz"
SODIUM_DIR="/tmp/libsodium-stable"
SODIUM_LINK="https://download.libsodium.org/libsodium/releases/LATEST.tar.gz"
wget "$SODIUM_LINK" -O "$SODIUM_TAR"
rm -rf "$SODIUM_DIR"
tar -xf "$SODIUM_TAR" -C $(dirname "$SODIUM_DIR")
cd "$SODIUM_DIR" || exit 1
# Build libsodium
./configure
make
sudo make install

# Install minisign
MINI_ZIP="/tmp/minisign.zip"
MINI_DIR="/tmp/minisign-master"
MINI_LINK="https://github.com/jedisct1/minisign/archive/refs/heads/master.zip"
wget "$MINI_LINK" -O "$MINI_ZIP"
rm -rf "$MINI_DIR"
unzip "$MINI_ZIP" -d $(dirname "$MINI_DIR")
mkdir -p "$MINI_DIR/build"
cd "$MINI_DIR/build" || exit 1
# Static?
cmake ..
make
sudo make install

# Notify of completion
echo "
Done, minisign has been installed in: $(which minisign)
Version:"
minisign -v

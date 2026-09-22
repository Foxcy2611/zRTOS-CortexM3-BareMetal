#!/usr/bin/env bash
set -e

TOOLS=(
    cmake
    ninja
    arm-none-eabi-gcc
    arm-none-eabi-objcopy
    arm-none-eabi-size
    openocd
)

for tool in "${TOOLS[@]}"
do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "[OK] $tool"
    else
        echo "[MISSING] $tool"
    fi
done
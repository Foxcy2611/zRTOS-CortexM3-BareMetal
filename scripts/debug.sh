#!/usr/bin/env bash
set -e

ELF="$1"

if [ -z "$ELF" ]; then
    echo "Usage: $0 <firmware.elf>"
    exit 1
fi

if [ ! -f "$ELF" ]; then
    echo "[ERROR] File not found: $ELF"
    exit 1
fi

arm-none-eabi-gdb "$ELF" \
    -ex "target extended-remote localhost:3333"
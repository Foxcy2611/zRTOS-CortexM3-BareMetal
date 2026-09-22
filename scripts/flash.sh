#!/usr/bin/env bash
set -e

FIRMWARE="$1"

if [ -z "$FIRMWARE" ]; then
    echo "Usage: $0 <firmware.elf|firmware.hex|firmware.bin>"
    exit 1
fi

if [ ! -f "$FIRMWARE" ]; then
    echo "[ERROR] File not found: $FIRMWARE"
    exit 1
fi

openocd \
    -f interface/stlink.cfg \
    -f target/stm32f1x.cfg \
    -c "program \"$FIRMWARE\" verify reset exit"
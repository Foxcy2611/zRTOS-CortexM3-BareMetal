#!/usr/bin/env bash
set -e

PRESET="${1:-debug}"

cmake --preset "$PRESET"
cmake --build --preset "$PRESET"

# Run bằng 1 trong 2 cách:
# 
# 
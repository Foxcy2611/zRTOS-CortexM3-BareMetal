#!/usr/bin/env bash
set -e

openocd \
    -f interface/stlink.cfg \
    -f target/stm32f1x.cfg \
    -c "init; targets; shutdown"
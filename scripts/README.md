# SCRIPT CHẠY

## Tổng hợp các SCRIPT

| Tên script | Tác dụng | Chạy bằng cách |
|---|---|---|
| check_env.sh | Kiểm tra cmake, ninja, arm-none-eabi-gcc, openocd... | `./scripts/check_env.sh` |
| build.sh | Configure + build bằng preset | • Debug:<br>`./scripts/build.sh debug`<br>• Release:<br>`./scripts/build.sh release` |
| clean.sh | Xóa build output | `./scripts/clean.sh` |
| check_stlink.sh | Kiểm tra ST-Link / kết nối target | `./scripts/check_stlink.sh` |
| flash.sh | Nạp ELF xuống STM32 | `./scripts/flash.sh _Link_tới_Prj_`|
| openocd.sh | Mở OpenOCD server | `./scripts/openocd.sh` |
| debug.sh | GDB, để làm sau cũng được | `./scripts/debug.sh build/debug/examples/zrtos_bsp_smoke.elf` |

## Workflow cơ bản

Run các script lần lượt như sau

```script
./scripts/build.sh debug

./scripts/check_stlink.sh

./scripts/flash.sh zrtos_bsp_smoke
```
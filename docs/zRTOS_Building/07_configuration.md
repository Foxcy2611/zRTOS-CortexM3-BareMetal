# 07 — Configuration

zRTOS v1 giữ compile-time configuration nhỏ và rõ ràng.

Một file gợi ý:

```text
include/zrtos/zrtos_config.h
```

---

## Core limits

```c
#define ZRTOS_MAX_TASKS          12
#define ZRTOS_MAX_PRIORITIES      8
#define ZRTOS_TICK_HZ          1000
```

Quy ước:

- priority 0 dành cho idle;
- user priority từ 1 tới `MAX_PRIORITIES-1`.

---

## Diagnostics

```c
#define ZRTOS_ENABLE_ASSERT             1
#define ZRTOS_ENABLE_STACK_CANARY       1
#define ZRTOS_ENABLE_STACK_WATERMARK    1
#define ZRTOS_ENABLE_RUNTIME_STATS      1
```

Các option này có thể bị disable ở build tối giản, nhưng nên bật trong development.

---

## Scheduler options

V1 không cần tạo quá nhiều policy switch.

Các behavior chính được cố định:

- fixed priority;
- preemptive;
- round-robin cùng priority;
- static allocation.

Không biến mọi design choice thành macro.

---

## Tick assumptions

- tick counter 32-bit;
- finite timeout tối đa `INT32_MAX` tick;
- `WAIT_FOREVER` xử lý riêng;
- tick rate phải đủ thấp để interrupt overhead hợp lý nhưng đủ cao cho demo/test.

---

## Build configuration

Project build bằng CMake + Ninja.

Các compile definition liên quan MCU/board nằm ở target CMake, không hard-code rải rác trong source.

Khuyến nghị:

- warnings bật cao;
- debug build có symbols;
- `-ffunction-sections -fdata-sections` nếu phù hợp;
- link map luôn được sinh;
- có size report sau link.

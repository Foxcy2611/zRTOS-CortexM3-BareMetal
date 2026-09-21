# 00 — Kiến trúc zRTOS v1

## 1. Các tầng

```text
Application -> include/zrtos -> kernel -> port/cortex_m3 -> CMSIS
     |
     +-----------------------> bsp/stm32f103c8t6 -> SPL
```

### `include/zrtos/`

Public API và public type.

- Task API.
- Timing API.
- Semaphore/Queue/Mutex API.
- Status code.
- Compile-time public config cần thiết.

### `kernel/`

Phần logic RTOS không phụ thuộc peripheral STM32.

- task state;
- scheduler;
- ready/delayed/wait lists;
- timing;
- IPC;
- synchronization;
- diagnostics.

Kernel không được include SPL header.

### `port/cortex_m3/`

Phần phụ thuộc ARM Cortex-M3.

- MSP / PSP.
- SVC.
- PendSV.
- SysTick glue.
- PRIMASK / interrupt masking.
- context save/restore.
- optional DWT runtime counter.

### `bsp/stm32f103c8t6/`

Phần phụ thuộc MCU/board.

- clock;
- GPIO;
- UART;
- ADC;
- DMA;
- board init.

BSP có thể dùng STM32 SPL.

### `examples/`

Firmware mẫu kết hợp public zRTOS API và BSP.

---

## 2. Luồng khởi động

```text
Reset
  ↓
Startup
  ↓
SystemInit
  ↓
main
  ↓
bsp_init
  ↓
zrtos_init
  ↓
create static tasks
  ↓
zrtos_start
  ↓
SVC
  ↓
First Task
```

`zrtos_start()` không trực tiếp nhảy bằng function call vào task. Port bootstrap task đầu tiên qua exception-return để task bắt đầu đúng execution model của Cortex-M.

---

## 3. Scheduler và port

Quy tắc:

```text
Scheduler = chọn task tiếp theo
Port      = chuyển CPU context
```

Scheduler policy nằm trong C.

Assembly/naked handler chỉ làm phần tối thiểu cần thiết cho save/restore context và chuyển execution.

---

## 4. Ownership

- Kernel không cấp phát heap trong v1.
- TCB và stack do caller hoặc application cấp phát tĩnh.
- Queue storage do caller cấp phát.
- Object phải sống ít nhất bằng khoảng thời gian kernel còn tham chiếu tới object đó.
- Task RUNNING không nằm trong ready list.
- READY task nằm đúng một ready list.
- BLOCKED task có thể đồng thời có một item trong event wait list và một item trong delayed list.
- Completion của timed wait phải atomically kết thúc cả hai nguồn wake.

---

## 5. Build graph

CMake targets nên chia theo module thay vì gom mọi source vào một executable:

```text
zrtos_vendor   -> CMSIS + SPL subset
zrtos_bsp      -> STM32F103 BSP
zrtos_kernel   -> kernel + Cortex-M3 port
firmware_*     -> startup + linker + app + các target trên
```

Build backend duy nhất trong v1 là Ninja.

Ví dụ configure:

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi-toolchain.cmake
```

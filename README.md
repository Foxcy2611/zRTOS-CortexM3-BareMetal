# zRTOS — RTOS Kernel From Scratch on STM32F103

**zRTOS** là một RTOS kernel nhỏ được xây dựng từ đầu cho **STM32F103C8T6 / ARM Cortex-M3**.

Project tập trung vào việc hiểu và hiện thực các cơ chế cốt lõi bên trong một RTOS thay vì chỉ sử dụng API của một RTOS có sẵn. Mục tiêu là tạo ra một kernel đủ nhỏ để có thể hiểu toàn bộ kiến trúc, nhưng đủ hoàn chỉnh để chạy một firmware thực tế trên STM32F103.

> zRTOS là project học tập và portfolio. Không đặt mục tiêu production-grade, safety-certified hoặc thay thế FreeRTOS.

---

## 1. Nền tảng và toolchain

zRTOS được phát triển và kiểm thử trên STM32F103C8T6 sử dụng ARM Cortex-M3.

### 1.1. Target hardware

| Thành phần | Thông tin |
|---|---|
| MCU | STM32F103C8T6 |
| CPU | ARM Cortex-M3 |
| Core clock | tối đa 72 MHz |
| Flash | 128 KB |
| SRAM | 20 KB |
| Architecture | ARMv7-M |
| Board | STM32F103C8T6 development board / Blue Pill |
| External clock | HSE 8 MHz |
| Debug interface | SWD |

> zRTOS hiện tập trung vào STM32F103C8T6. Các port cho MCU hoặc architecture khác không nằm trong scope của.

### 1.2. Development toolchain

| Tool | Vai trò |
|---|---|
| `arm-none-eabi-gcc` | Cross compiler cho ARM Cortex-M |
| CMake | Cấu hình build project |
| Ninja | Build backend |
| GNU Arm Binutils | `objcopy`, `objdump`, `size`, ... |
| GDB | Debug firmware |
| OpenOCD | Flash/debug bridge |
| ST-Link | SWD debug probe |
| WSL | Environment |
| VS Code | Editor / development environment |

### 1.3. Libraries

| Library | Vai trò |
|---|---|
| CMSIS | ARM Cortex-M3 core và STM32 device definitions |
| STM32F10x SPL | Peripheral drivers cho STM32F103 |

zRTOS kernel không phụ thuộc STM32 SPL. SPL chỉ được sử dụng trong BSP và
firmware/application layer.

---

## 2. Mục tiêu

zRTOS hướng tới việc chứng minh ba nhóm năng lực chính:

### 2.1. ARM Cortex-M3 low-level

- Exception model.
- MSP / PSP.
- SVC.
- PendSV.
- SysTick.
- Context save / restore.
- Interrupt masking và critical section.

### 2.2. RTOS kernel

- Task và TCB.
- Static task allocation.
- Fixed-priority preemptive scheduler.
- Round-robin giữa task cùng priority.
- Blocking và delay không busy-wait.
- Semaphore.
- Queue.
- Mutex.
- Priority inheritance.
- Finite timeout.
- ISR-safe API.
- Kernel diagnostics.

### 2.3. Embedded software engineering

- Tách Application / Kernel / Port / BSP.
- C + ARM Assembly.
- CMake + Ninja.
- Cross-compilation bằng `arm-none-eabi-gcc`.
- Debug bằng ST-Link + OpenOCD + GDB.
- Regression test và stress test.
- Hardware validation có checklist.
- Documentation và release discipline.

---

## 3. Kiến trúc tổng thể

```text
+------------------------------------------------------+
|                    APPLICATION                       |
|             User Tasks / Firmware Logic              |
+--------------------------+---------------------------+
                           |
              +------------+------------+
              |                         |
              v                         v
+--------------------------+   +-----------------------+
|        zRTOS API         |   |          BSP          |
| Task / IPC / Sync / Time |   | GPIO / UART / ADC /   |
|                          |   | DMA / SPI / I2C       |
+------------+-------------+   +-----------+-----------+
             |                             |
             v                             v
+--------------------------+          STM32 Drivers
|          KERNEL          |
| Task / Scheduler / IPC   |
| Timing / Synchronization |
+------------+-------------+
             |
             v
+--------------------------+
|      Cortex-M3 Port      |
| SVC / PendSV / SysTick   |
| PSP / MSP / IRQ Masking  |
+------------+-------------+
             |
             v
            CMSIS
             |
             v
+--------------------------+
| STM32F103 / Cortex-M3    |
+--------------------------+
```

Nguyên tắc chính:

- `kernel/` không phụ thuộc SPL hoặc peripheral STM32.
- `port/cortex_m3/` chỉ xử lý phần phụ thuộc kiến trúc ARM Cortex-M3.
- `bsp/stm32f103c8t6/` xử lý board/peripheral và có thể dùng SPL.
- Application chỉ dùng public API của zRTOS và BSP.
- Scheduler quyết định **task nào chạy**; port thực hiện **CPU context switch**.

---

## 4. Scheduler và task model

zRTOS sử dụng:

```text
Fixed Priority
      +
Preemptive Scheduling
      +
Round-Robin giữa task cùng priority
```

Task có các trạng thái chính:

```text
UNUSED -> READY -> RUNNING
            ^        |
            |        v
            +---- BLOCKED
```

Task bị block bởi delay hoặc synchronization object không được scheduler chọn cho đến khi event hoặc timeout hoàn tất wait.

Task và kernel object được cấp phát tĩnh trong.

---

## 5. IPC và synchronization

zRTOS hướng tới:

- Counting semaphore.
- Static queue.
- ISR-safe semaphore/queue API.
- Mutex có ownership.
- Priority inheritance.
- Finite timeout cho blocking API.

Một trong các mục tiêu nâng cao của project là tái hiện và xử lý priority inversion bằng priority inheritance thay vì chỉ dừng ở scheduler cơ bản.

---

## 6. Cấu trúc repository

```text
zRTOS-CortexM3-BareMetal/
│
├── bsp/
│   ├── linker/                  # Linker script cho STM32F103C8T6
│   ├── startup/                 # Vector table, Reset_Handler, startup code
│   └── stm32f103c8t6/           # Board support riêng cho STM32F103C8T6
│       └── include/             # Cấu hình board/SPL như stm32f10x_conf.h
│
├── cmake/                       # Toolchain file, compiler options, CMake helper
│
├── docs/                        # Đặc tả kiến trúc, scheduler, IPC, test, limitations
│
├── examples/                    # Firmware/demo theo từng milestone của zRTOS
│
├── include/
│   └── zrtos/                   # Public API và public types của zRTOS
│
├── kernel/                      # Core RTOS: task, scheduler, timing, IPC, sync
│
├── libraries/
│   ├── CMSIS/                   # ARM Cortex-M3 core + STM32 device definitions
│   └── STM32F10x_StdPeriph_Driver/
│                               # STM32 Standard Peripheral Library
│
├── port/                        # Phần phụ thuộc kiến trúc CPU
│   └── cortex_m3/               # SVC, PendSV, PSP/MSP, context switch, IRQ control
│
├── scripts/                     # Script hỗ trợ build/flash/debug/automation
│
├── tests/                       # Host tests và target/hardware tests
│
├── .clang-format               # Quy tắc format source code
├── .gitignore                  # Loại build artifacts và file tạm khỏi Git
│
├── CMakeLists.txt              # Entry point của build system
├── CMakePresets.json           # Preset build với CMake + Ninja
│
├── CONTRIBUTING.md             # Quy tắc đóng góp và development workflow
├── LICENSE                     # MIT License
├── THIRD_PARTY_NOTICES.md      # License/notice cho CMSIS, SPL và third-party code
│
├── README.md                   # Tổng quan project
└── ROADMAP.md                  # Lộ trình học và xây dựng zRTOS
```

Chi tiết kiến trúc, invariant, API contract, testing và hardware validation nằm trong [`docs/`](docs/README.md).

---

## 7. Nguyên tắc phát triển

1. Hiểu cơ chế trước khi viết abstraction.
2. Tách scheduler khỏi context switch.
3. Kernel không phụ thuộc peripheral STM32.
4. Static allocation trước.
5. Task chờ event phải block, không busy-wait.
6. ISR không được gọi blocking API.
7. Kernel shared state phải có critical section rõ ràng.
8. Mỗi subsystem phải có invariant.
9. Mỗi feature quan trọng phải có test.
10. Không copy implementation của FreeRTOS để hoàn thành feature.
11. Không đánh dấu feature là PASS chỉ vì build thành công.
12. Nếu implementation khác specification, cập nhật spec có chủ ý trước khi chấp nhận behavior mới.

---

## 8. Roadmap

```text
Cortex-M3 Internals
        ↓
Task Model
        ↓
First Task
        ↓
Context Switch
        ↓
Scheduler
        ↓
Blocking & Timing
        ↓
IPC & Synchronization
        ↓
Mutex & Priority Inheritance
        ↓
Diagnostics & Testing
        ↓
Real Firmware
        ↓
Release
```

Xem chi tiết tại [`ROADMAP.md`](ROADMAP.md).

---

## 9. Scope

Trong scope:

- Single-core Cortex-M3.
- Static allocation.
- Preemptive fixed-priority scheduler.
- Round-robin cùng priority.
- Semaphore, queue, mutex.
- Priority inheritance.
- Finite timeout.
- ISR-safe IPC.
- Diagnostics và hardware validation.

Ngoài scope:

- SMP / multicore.
- MPU-based task isolation.
- Dynamic task creation/deletion phức tạp.
- Tickless idle.
- Safety certification.
- Formal verification.
- Multi-architecture production ports.

---

## 10. Documentation

- [`docs/README.md`](docs/README.md) — bản đồ tài liệu.
- [`architecture.md`](docs/00_architecture.md) — kiến trúc tổng thể.
- [`kernel_invariants.md`](docs/01_kernel_invariants.md) — các invariant bắt buộc.
- [`task_model.md`](docs/02_task_model.md) — mô hình task và TCB.
- [`context_switch.md`](docs/03_context_switch.md) — Cortex-M3 port và context switch.
- [`scheduler.md`](docs/04_scheduler.md) — scheduling, tick và blocking.
- [`ipc.md`](docs/05_ipc.md) — semaphore, queue, mutex và timeout race.
- [`api_contract.md`](docs/06_api_contract.md) — public API behavior.
- [`configuration.md`](docs/07_configuration.md) — cấu hình kernel.
- [`testing.md`](docs/08_testing.md) — chiến lược test.
- [`hardware_validation.md`](docs/09_hardware_validation.md) — release gate trên board.
- [`known_limitations.md`](docs/10_known_limitations.md) — giới hạn có chủ ý.
- [`implementation_status.md`](docs/implementation_status.md) — trạng thái hiện tại.

---

## 11. Author

- **Name:** Nguyễn Ngọc Chiến
- **ID:** B23DCVT061
- **University:** Posts and Telecommunications Institute of Technology

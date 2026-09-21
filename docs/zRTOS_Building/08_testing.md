# 08 — Build và Kiểm thử

## 1. Nguyên tắc

- Compile PASS không chứng minh runtime PASS.
- Host test không chứng minh context switch/ISR đúng trên Cortex-M3.
- Mỗi subsystem có test phù hợp abstraction level của nó.
- Hardware-dependent behavior phải được xác minh trên target.

---

## 2. Build workflow

Configure:

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi-toolchain.cmake \
  -DCMAKE_BUILD_TYPE=Debug
```

Build:

```bash
cmake --build build
```

Clean rebuild:

```bash
rm -rf build
cmake -S . -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi-toolchain.cmake
cmake --build build
```

---

## 3. Host tests

Phù hợp cho:

- intrusive list;
- ring buffer logic;
- tick-wrap math;
- pure scheduler selection logic nếu tách được khỏi port;
- timeout arithmetic;
- helper function không phụ thuộc register/exception.

Không dùng host test để kết luận:

- SVC đúng;
- PendSV đúng;
- PSP/MSP đúng;
- ISR preemption đúng.

---

## 4. Target checkpoints

Khuyến nghị firmware targets:

```text
zrtos_phase0
zrtos_first_task
zrtos_scheduler_demo
zrtos_ipc_stress
zrtos_full_demo
```

### `zrtos_phase0`

- startup;
- clock;
- GPIO;
- UART;
- linker/memory sanity.

### `zrtos_first_task`

- SVC;
- PSP/MSP;
- initial frame;
- first task entry.

### `zrtos_scheduler_demo`

- PendSV;
- preemption;
- delay;
- priority;
- round-robin.

### `zrtos_ipc_stress`

- semaphore;
- queue;
- mutex;
- timeout;
- event race;
- high switch count.

### `zrtos_full_demo`

- UART IRQ;
- ADC/DMA;
- ISR-to-task signaling;
- shared logging;
- multiple concurrent tasks.

---

## 5. Fault injection

Bắt buộc có test chủ động cho:

- stack canary corruption;
- task return;
- invalid mutex unlock;
- tick near `UINT32_MAX`;
- timeout sát event;
- queue full/empty pressure;
- priority inversion scenario.

---

## 6. Test evidence

Mỗi hardware validation run nên ghi:

- ngày giờ;
- board;
- ST-Link/OpenOCD version;
- compiler version;
- commit hash;
- firmware target;
- UART log;
- test duration;
- PASS/FAIL;
- fault record nếu có.

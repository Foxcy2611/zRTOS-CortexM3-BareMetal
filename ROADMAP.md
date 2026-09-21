# zRTOS Roadmap — STM32F103 / ARM Cortex-M3

Roadmap này mô tả thứ tự học, hiện thực và xác minh zRTOS từ đầu trên STM32F103C8T6.

Các phần bare-metal cơ bản như startup, linker, clock cơ bản, CMake toolchain, ST-Link/OpenOCD và workflow cross-compile được xem là prerequisite.

Build system thống nhất của project là **CMake + Ninja**.

---

## Quy ước hoàn thành phase

Mỗi phase đi theo flow:

```text
SPEC -> IMPLEMENT -> TEST -> BOARD VERIFY -> PASS
```

Không đổi trạng thái thành PASS chỉ vì compile/link thành công.

---

# Phase 0 — Build & Bare-metal Bring-up

Mục tiêu: có project skeleton reproducible trước khi viết kernel.

- CMake + Ninja build.
- `arm-none-eabi-gcc` toolchain file.
- Startup code.
- Linker script đúng STM32F103C8T6.
- CMSIS.
- SPL tối thiểu.
- BSP smoke test: clock, GPIO, UART.
- OpenOCD + GDB.

PASS khi:

- clean configure/build thành công;
- sinh ELF/HEX/BIN/MAP;
- flash được board;
- LED/UART smoke test pass.

---

# Phase 1 — Cortex-M3 Foundations

Học và lab:

- Thread mode / Handler mode.
- Exception entry / return.
- Hardware stack frame.
- MSP / PSP.
- SVC.
- PendSV.
- AAPCS, caller/callee-saved registers.
- PRIMASK và BASEPRI ở mức khái niệm.

PASS khi:

- đọc được MSP/PSP trong debugger;
- trigger SVC/PendSV có chủ đích;
- giải thích được hardware/software context frame;
- hiểu vì sao PendSV thường dùng cho context switch.

---

# Phase 2 — Task Model & Initial Context

Hiện thực:

- `zrtos_tcb_t`.
- Static task stack.
- Task states.
- Initial hardware frame.
- Initial software frame.
- Stack alignment.
- Task return trap.

PASS khi:

- initial stack frame dump đúng layout;
- `tcb->sp` đúng contract;
- stack alignment và boundary assert pass.

---

# Phase 3 — Start First Task bằng SVC

Hiện thực:

- `zrtos_init()`.
- `zrtos_start()`.
- chọn task READY đầu tiên.
- SVC restore `R4-R11`.
- set PSP.
- exception return vào task.

PASS khi:

- reset -> main -> zRTOS -> task entry;
- task chạy Thread mode bằng PSP;
- handler vẫn dùng MSP;
- argument truyền đúng qua `R0`.

---

# Phase 4 — PendSV Context Switch & Cooperative Scheduling

Hiện thực:

- save/restore `R4-R11`.
- save PSP vào TCB.
- restore next task PSP.
- `zrtos_yield()`.
- cooperative round-robin ban đầu.
- tách scheduler policy khỏi assembly port.

PASS khi:

- A/B/C switch lặp ổn định;
- local/register state không corrupt;
- PSP luôn nằm đúng task stack;
- stress context switch dài hạn không HardFault.

---

# Phase 5 — Preemptive Fixed-Priority Scheduler

Hiện thực:

- SysTick kernel tick.
- preemption.
- fixed priority.
- same-priority round-robin.
- idle task.

PASS khi:

- high priority preempt low;
- same-priority tasks chia time slice;
- task không cần tự yield vẫn bị preempt;
- idle chỉ chạy khi không còn user task READY.

---

# Phase 6 — Lists, Blocking & Delay

Hiện thực:

- intrusive list.
- ready lists theo priority.
- delayed list.
- `BLOCKED` state.
- wrap-safe tick compare.
- `zrtos_delay()`.

PASS khi:

- BLOCKED task không bao giờ được scheduler chọn;
- nhiều deadline thức đúng thứ tự;
- test qua `UINT32_MAX` không lỗi;
- delay không busy-wait.

---

# Phase 7 — Critical Section & Semaphore

Hiện thực:

- critical section bằng save/restore PRIMASK cho v1.
- counting semaphore.
- task wait list.
- priority-aware wake.
- `FromISR` give.

PASS khi:

- race trên kernel list được loại bỏ;
- semaphore block/wake đúng;
- ISR có thể wake higher-priority task;
- ISR không bao giờ block.

---

# Phase 8 — Queue & ISR Communication

Hiện thực:

- caller-owned static ring buffer.
- send/receive.
- blocked receiver.
- blocked sender.
- `FromISR` send.
- producer/consumer demo.

PASS khi:

- FIFO đúng;
- không mất/reorder item;
- full/empty behavior đúng contract;
- sender/receiver wake đúng priority/FIFO rule;
- ISR-to-task path hoạt động trên board.

---

# Phase 9 — Mutex, Priority Inheritance & Timeout

Hiện thực theo thứ tự:

1. mutex ownership;
2. reproduce priority inversion;
3. base/effective priority;
4. basic priority inheritance;
5. chain propagation;
6. finite timeout;
7. event-vs-timeout race completion path.

PASS khi:

- non-owner unlock bị từ chối;
- priority inversion được tái hiện;
- PI giải quyết scenario Low/Medium/High;
- effective priority restore đúng;
- event và timeout không double-wake;
- timeout qua tick wrap đúng.

---

# Phase 10 — Diagnostics & Hardening

Hiện thực:

- `ZRTOS_ASSERT()`.
- stack fill.
- stack canary.
- stack high-watermark.
- context-switch counter.
- runtime cycle counter.
- fault record cơ bản.
- regression/stress tests.

PASS khi:

- cố ý phá canary -> assert/fault hook;
- task return trap hoạt động;
- stack watermark có ý nghĩa;
- stress dài hạn không assert/HardFault;
- log đủ để điều tra lỗi.

---

# Phase 11 — Real Firmware Demo

Gợi ý task:

- Command Task.
- Sensor Task.
- Processing Task.
- Logger Task.
- Idle Task.

Luồng chính:

- UART RX IRQ -> Queue -> Command Task.
- ADC + DMA -> ISR -> signal -> Sensor Task.
- shared UART qua Logger Task hoặc mutex.

PASS khi:

- full demo chạy liên tục trên board;
- UART không interleave ngoài thiết kế;
- ADC/DMA path hoạt động;
- scheduler/IPC/mutex/timeout cùng tồn tại ổn định.

---

# Phase 12 — Portfolio Release

- clean repository.
- docs khớp source.
- implementation status cập nhật.
- hardware validation đầy đủ.
- known limitations rõ ràng.
- clean clone -> configure -> build bằng CMake + Ninja.
- release note chỉ viết sau khi có bằng chứng.
- tag `v1.0.0` chỉ sau khi hardware gates PASS.

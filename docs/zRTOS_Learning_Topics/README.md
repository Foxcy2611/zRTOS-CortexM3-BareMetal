# zRTOS Learning Topics

> Bộ giáo trình lý thuyết dùng để học và tự xây **zRTOS trên STM32F103 / ARM Cortex-M3**.
>
> Mỗi phase có một `README.md` làm mục lục và **3 chapter dài**. Mỗi chapter theo cùng cấu trúc: Phạm vi → Giới hạn → Mục lục → lý thuyết → mental model → invariant → hiểu nhầm → liên hệ zRTOS → tổng kết → câu hỏi tự kiểm tra.

## Cách học

```text
Đọc chapter
   ↓
Tự vẽ lại mental model
   ↓
Trả lời câu hỏi tự kiểm tra
   ↓
Mới bắt đầu code/lab phase đó
   ↓
Test + document + commit
```

## Danh sách phase

- [Phase 1 — Cortex-M3 Foundations for RTOS](phase-01-cortex-m3-foundations/README.md) — Hiểu exception model, MSP/PSP, SVC, PendSV và register context — nền móng CPU cho zRTOS.
- [Phase 2 — Task Model & Initial Task Context](phase-02-task-model/README.md) — Biến task thành execution context cụ thể: TCB, state, stack và initial frame.
- [Phase 3 — Start First Task with SVC](phase-03-first-task-svc/README.md) — Dùng SVC để bootstrap task đầu tiên chạy bằng PSP.
- [Phase 4 — PendSV Context Switch & Cooperative Scheduler](phase-04-context-switch-cooperative/README.md) — Hiện thực save/restore context đúng và tách scheduler khỏi context switch.
- [Phase 5 — Preemptive Fixed-Priority Scheduler](phase-05-preemptive-scheduler/README.md) — Thêm SysTick, preemption, priority, round-robin và idle task.
- [Phase 6 — Kernel Lists, Blocking & Delay](phase-06-lists-blocking-delay/README.md) — Xây intrusive list, ready lists, BLOCKED state, delay và tick wraparound.
- [Phase 7 — Critical Section & Semaphore](phase-07-critical-semaphore/README.md) — Hiểu race condition, critical section, semaphore và ISR-safe synchronization.
- [Phase 8 — Queue & ISR Communication](phase-08-queue-isr/README.md) — Xây static queue, blocked sender/receiver và ISR-to-task communication.
- [Phase 9 — Mutex, Priority Inheritance & Finite Timeout](phase-09-mutex-timeout/README.md) — Hiểu mutex, priority inversion/inheritance và finite timeout.
- [Phase 10 — Diagnostics, Testing & Kernel Hardening](phase-10-diagnostics-testing/README.md) — Thêm assert, stack diagnostics, runtime stats, regression/stress test.
- [Phase 11 — Real STM32F103 Firmware Using zRTOS](phase-11-real-firmware/README.md) — Dùng chính zRTOS để xây firmware STM32F103 có UART IRQ, ADC/DMA và shared peripherals.
- [Phase 12 — Portfolio Release & Architecture Consolidation](phase-12-portfolio-release/README.md) — Đóng zRTOS v1 thành repo sạch, reproducible, document tốt và đủ mạnh cho CV/phỏng vấn.

## Scope

Bộ tài liệu dừng ở **portfolio-grade solo RTOS project** cho zRTOS v1. Production-grade/certification không phải mục tiêu của curriculum này.

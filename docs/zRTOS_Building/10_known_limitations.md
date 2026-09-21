# 10 — Known Limitations

Các giới hạn dưới đây là intentional scope của zRTOS v1, không phải bug cần che giấu.

- Educational / portfolio RTOS, không production-grade hoặc safety-certified.
- Chỉ target ARM Cortex-M3 single-core trong v1.
- Board chính: STM32F103C8T6.
- Static allocation; không có heap task/object trong v1.
- Không hỗ trợ task deletion runtime.
- Task chạy privileged; chưa có MPU/user mode isolation.
- Fixed number of priorities và tasks theo compile-time config.
- Không có SMP.
- Không có tickless idle trong v1.
- Finite timeout tối đa `INT32_MAX` tick theo wrap-safe compare model.
- Mutex non-recursive.
- Deadlock prevention không thuộc v1.
- Priority inheritance có giới hạn scope, không formal verification.
- PRIMASK-based critical section có thể mask toàn bộ maskable interrupt trong khoảng ngắn.
- BASEPRI ceiling model chưa bắt buộc trong v1.
- Runtime cycle counter không phải WCET proof.
- Diagnostics không thay thế memory protection.
- Full correctness claim chỉ áp dụng cho behavior đã được hardware validation.

# Bài 10.3 — Regression, Stress Test và Known Limitations

> **Phạm vi:** Test strategy cho kernel, long-run stress, integration test và known limitations.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không safety certification, MISRA compliance program hoặc formal coverage target.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-stack-runtime-diagnostics.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Regression test theo subsystem](#1-regression-test-theo-subsystem)
- [2. Stress và integration](#2-stress-và-integration)
- [3. Known limitations](#3-known-limitations)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Regression test theo subsystem

Mỗi feature có behavior deterministic cần test riêng để refactor không làm hỏng chức năng cũ.

### Task/context

Initial stack layout, first-task bootstrap, register preservation.

### Scheduler/timing

Priority, round-robin, blocked exclusion, delay deadline, wraparound.

### IPC

Semaphore count/wake, queue FIFO/full/empty, mutex owner/PI, finite timeout.

### Tại sao phần này quan trọng với RTOS?

Regression suite biến từng phase thành nền tin cậy cho phase sau.

### Góc nhìn debug

Test target nên báo PASS/FAIL rõ, không chỉ dựa quan sát LED.

---

## 2. Stress và integration

Stress test tìm interleaving hiếm bằng số lượng switch/IPC operation lớn. Integration test kiểm nhiều subsystem tương tác.

### Sequence/checksum

Producer-consumer dùng sequence ID/checksum để detect silent loss/reorder.

### Long-run

Chạy đủ lâu hoặc ép điều kiện để hit repeated switching, contention và timing edges.

### Fault injection

Cố tình overflow queue/canary hoặc invalid path để verify error/assert behavior.

### Tại sao phần này quan trọng với RTOS?

Race hiếm thường chỉ xuất hiện khi timing thay đổi nhiều lần.

### Góc nhìn debug

Giữ first-failure evidence và counters, tránh spam log phá timing.

---

## 3. Known limitations

Educational/portfolio kernel tốt phải nói rõ giới hạn: static allocation, Cortex-M3-only, fixed priority, task lifecycle, O(N) delay scan, PI nesting scope... tùy source thật.

### Honesty

Limitation cho thấy scope có chủ đích.

### Sync với source

Nếu feature thay đổi, limitation list phải update.

### Tại sao phần này quan trọng với RTOS?

Reviewer đánh giá engineering judgement qua guarantee và trade-off.

### Góc nhìn debug

Cross-check docs với tests/source trước release.

---

## 4. Mental Model tổng hợp

```text
feature implementation
      |
      +--> focused regression
      +--> integration
      +--> stress/fault injection
      |
      v
observed behavior
      |
      +--> supported guarantees
      +--> known limitations
      |
      v
portfolio confidence
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Refactor không bỏ qua regression cũ.
- Test evidence đủ xác định pass/fail.
- Known limitations khớp implementation.
- Full demo không thay edge-case tests.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “LED blink đúng là test context switch”

Không cover register/stack corruption.

### “Stress phải random hoàn toàn”

Deterministic stress dễ reproduce hơn.

### “Ghi limitation làm repo yếu”

Scope đúng đáng tin hơn claim quá mức.

---

## 7. Liên hệ trực tiếp với zRTOS

Kết thúc Phase 10, core zRTOS phải đủ test/observability để Phase 11 dùng như RTOS library thay vì tiếp tục debug bằng niềm tin.

---

## 8. Tổng kết

- Mỗi subsystem cần regression độc lập.
- Stress tìm bug xác suất; integration tìm mismatch giữa module contracts.
- Known limitations là một phần design documentation.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Regression, integration và stress khác nhau thế nào?
2. Sequence ID giúp queue stress ra sao?
3. Tại sao known limitations là artifact quan trọng?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-stack-runtime-diagnostics.md) · [Phase Index →](README.md)

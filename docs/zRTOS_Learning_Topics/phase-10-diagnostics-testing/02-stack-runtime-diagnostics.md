# Bài 10.2 — Stack Diagnostics và Runtime Statistics

> **Phạm vi:** Stack fill pattern, high-watermark, canary, context-switch counter và runtime/idle statistics.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không MPU stack protection hoặc full trace recorder.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-kernel-assert-invariants.md) · [Bài tiếp →](03-regression-stress-limitations.md)

---

## Mục lục

- [1. Stack fill pattern và high-watermark](#1-stack-fill-pattern-và-high-watermark)
- [2. Stack canary](#2-stack-canary)
- [3. Context-switch và runtime counters](#3-context-switch-và-runtime-counters)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Stack fill pattern và high-watermark

Khi tạo task, vùng stack chưa dùng có thể fill một pattern cố định như `0xA5`. Sau runtime, scan vùng pattern còn nguyên để ước lượng mức stack tối đa đã chạm.

### High-watermark

Cho biết phần stack chưa từng bị ghi đè, giúp tune stack size bằng evidence.

### Giới hạn

Đây là practical estimate dựa pattern, không phải proof toán học tuyệt đối về stack usage.

### Tại sao phần này quan trọng với RTOS?

STM32F103 RAM nhỏ; stack từng task là chi phí lớn.

### Góc nhìn debug

Chạy stress/full demo rồi report watermark từng task.

---

## 2. Stack canary

Đặt guard word hoặc pattern ở boundary để detect khi stack vượt giới hạn và ghi đè vùng bảo vệ.

### Detection, không prevention

Canary không ngăn write; nó chỉ giúp phát hiện khi được check.

### Check points

Có thể check ở context switch, tick hoặc debug API; mỗi cách có overhead/detection latency.

### Tại sao phần này quan trọng với RTOS?

Stack overflow có thể corrupt TCB/list rồi trông giống scheduler bug.

### Góc nhìn debug

Cố tình tạo task dùng local array lớn để trigger guard.

---

## 3. Context-switch và runtime counters

Counter context switch và free-running timer giúp quan sát scheduler behavior thay vì chỉ suy đoán.

### Switch counter

Hữu ích cho stress progress và xác nhận preemption đang xảy ra.

### Runtime accounting

Tại mỗi switch, tính delta timer cho task vừa chạy; idle runtime cho estimate CPU idle percentage.

### Timer source

TIM2 free-running trên STM32F103 có thể được BSP expose cho kernel stats thay vì kernel gọi SPL trực tiếp.

### Tại sao phần này quan trọng với RTOS?

Observability tăng khả năng benchmark/debug và giá trị portfolio.

### Góc nhìn debug

So tổng runtime task với elapsed interval và kiểm counter wrap.

---

## 4. Mental Model tổng hợp

```text
task create
  |
fill stack pattern + canary
  |
runtime
  +--> context switch count
  +--> runtime accounting
  +--> idle accounting
  |
debug/report
  +--> watermark
  +--> canary status
  +--> CPU idle/load estimate
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Diagnostics không thay đổi scheduler semantics.
- Canary failure dẫn tới failure path rõ.
- Counter/timer wrap được cân nhắc.
- Kernel không phụ thuộc trực tiếp SPL timer driver.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Canary bảo vệ stack”

Canary phát hiện, không cô lập memory như MPU.

### “Watermark là exact usage”

Là estimate dựa pattern.

### “Stats miễn phí”

Instrumentation trong hot path có overhead.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 11 full demo nên report watermark, switch count và idle percentage để chứng minh kernel đang chạy như thiết kế.

---

## 8. Tổng kết

- Watermark giúp sizing static stack bằng dữ liệu thực.
- Canary giúp phát hiện stack overflow sớm hơn.
- Diagnostics nên optional để không bắt overhead vào core.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. High-watermark được suy ra thế nào?
2. Canary khác MPU protection ra sao?
3. Vì sao runtime stats nên đi qua BSP abstraction?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-kernel-assert-invariants.md) · [Bài tiếp →](03-regression-stress-limitations.md)

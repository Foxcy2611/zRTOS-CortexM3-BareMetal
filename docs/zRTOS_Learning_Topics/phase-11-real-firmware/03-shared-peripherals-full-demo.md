# Bài 11.3 — Shared Peripherals, Logger Task và Full Demo Architecture

> **Phạm vi:** Serialization shared UART, mutex vs dedicated logger task và kiến trúc full demo zRTOS.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không xây production logging framework.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-uart-adc-dma-integration.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Shared UART problem](#1-shared-uart-problem)
- [2. Logger priority và overload](#2-logger-priority-và-overload)
- [3. Full demo architecture](#3-full-demo-architecture)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Shared UART problem

Nếu nhiều task gọi UART transmit độc lập, message có thể xen kẽ hoặc driver state bị race tùy implementation.

### Mutex approach

Lock UART quanh transaction. Đơn giản nhưng caller có thể block trong thời gian transmit.

### Logger Task approach

Các task enqueue message; Logger Task là single owner UART. Ownership sạch nhưng cần log queue capacity/policy.

### Tại sao phần này quan trọng với RTOS?

Shared peripheral làm synchronization application trở nên cụ thể.

### Góc nhìn debug

Stress hai task log liên tục và verify message boundaries.

---

## 2. Logger priority và overload

Logger thường priority thấp hơn control/sensor path. Nếu log quá nhiều, queue có thể full; logging không nên làm realtime path collapse.

### Drop policy

Debug log có thể drop + counter thay vì block high-priority task tùy requirement.

### Lossless requirement

Nếu log là dữ liệu bắt buộc, thiết kế phải dành bandwidth/buffer hoặc backpressure rõ.

### Formatting cost

Format string dài nên cân nhắc chạy ở logger task để không kéo dài critical path.

### Tại sao phần này quan trọng với RTOS?

Observability không được phá behavior đang quan sát.

### Góc nhìn debug

Measure log queue high-water/overflow dưới stress.

---

## 3. Full demo architecture

Demo cuối nên kết hợp feature kernel vừa đủ: UART IRQ queue, ADC/DMA signal, processing task, logger, delay, priorities và diagnostics.

### Không biến thành sensor showcase

Mục tiêu là chứng minh scheduler/IPC/context behavior, không số lượng ngoại vi.

### Diagnostics

Report task watermark, switch counter, idle percentage và overflow counters.

### Final regression

Chạy full demo cùng regression/stress để application không che lỗi kernel.

### Tại sao phần này quan trọng với RTOS?

Application thực là integration test lớn và artifact CV dễ trình bày.

### Góc nhìn debug

Run long stress, reset/reflash nhiều lần, inspect watermark/counters.

---

## 4. Mental Model tổng hợp

```text
UART RX IRQ
   |
RX Queue -> Command Task

ADC + DMA
   |
DMA IRQ -> Semaphore -> Processing Task

Tasks
   |
Log Queue -> Logger Task -> UART

Idle
   |
runtime / stack / overflow diagnostics
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Shared UART có một serialization policy rõ.
- Logging không chặn realtime-critical path ngoài policy đã định.
- Full demo expose overflow/error counters.
- Stack watermark từng task còn safety margin sau stress.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Mutex luôn tốt hơn Logger Task”

Trade-off phụ thuộc ownership, latency và complexity.

### “Demo càng nhiều ngoại vi càng mạnh”

Kernel interaction và reasoning quan trọng hơn số module.

### “Application chạy nghĩa regression không cần”

Full demo không thay unit/edge tests.

---

## 7. Liên hệ trực tiếp với zRTOS

Kết thúc Phase 11, bạn chuyển vai từ người viết kernel sang người dùng chính zRTOS. Đây là bằng chứng API/design đủ coherent để xây firmware thật.

---

## 8. Tổng kết

- Peripheral sharing cần một serialization policy duy nhất.
- Logging policy là một phần system design.
- Full demo chứng minh vừa viết kernel vừa biết dùng RTOS để kiến trúc firmware.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. So sánh mutex UART và Logger Task.
2. Full demo nên chứng minh những kernel feature nào?
3. Tại sao logging cần overload policy?
4. Diagnostics nào nên hiển thị trong demo?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-uart-adc-dma-integration.md) · [Phase Index →](README.md)

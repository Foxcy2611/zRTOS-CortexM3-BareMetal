# Bài 11.2 — UART IRQ, ADC/DMA và Deferred Processing

> **Phạm vi:** ISR-to-task architecture với UART RX queue và ADC/DMA completion signaling.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không đi sâu parser protocol hoặc thuật toán xử lý sensor.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-task-decomposition-priorities.md) · [Bài tiếp →](03-shared-peripherals-full-demo.md)

---

## Mục lục

- [1. UART RX IRQ → Queue](#1-uart-rx-irq-→-queue)
- [2. ADC + DMA deferred processing](#2-adc-+-dma-deferred-processing)
- [3. Deferred processing principle](#3-deferred-processing-principle)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. UART RX IRQ → Queue

RXNE ISR đọc byte để service hardware rồi gọi `zrtos_queue_send_from_isr()`. Command Task block trên queue và parse ở task context.

### ISR tối giản

Không parse command, format string hay chạy loop dài trong IRQ.

### Burst capacity

Queue capacity phải chịu được burst trong worst-case consumer latency; overflow counter giúp kiểm chứng.

### Wake path

Nếu receiver đang BLOCKED và priority cao hơn current, ISR pend PendSV để task chạy ngay sau IRQ.

### Tại sao phần này quan trọng với RTOS?

Pattern này chứng minh FromISR + queue + wake + scheduler end-to-end.

### Góc nhìn debug

Trace IRQ timestamp, queue count, receiver state và thời điểm PendSV.

---

## 2. ADC + DMA deferred processing

DMA chuyển samples vào buffer mà CPU không copy từng sample. DMA complete IRQ chỉ báo task xử lý.

### Semaphore/notification

ISR give signal; Sensor/Processing Task wake và xử lý batch.

### Buffer ownership

Task không đọc buffer đang bị DMA overwrite nếu chưa có double-buffer/ping-pong protocol.

### Restart sequencing

DMA restart/swap buffer phải khớp thời điểm task được phép truy cập data.

### Tại sao phần này quan trọng với RTOS?

DMA đưa ownership và concurrency thực tế vào RTOS application.

### Góc nhìn debug

Track buffer A/B owner state và DMA current target.

---

## 3. Deferred processing principle

Interrupt context tối ưu hardware response; task context tối ưu scheduling, blocking và application logic. Chuyển phần nặng ra task gọi là deferred processing.

### Response latency

High-priority processing task có thể chạy gần ngay sau ISR return qua PendSV.

### Backpressure

Nếu processing chậm hơn producer, cần buffer/overflow policy chứ không giả hệ thống luôn kịp.

### Observability

Đếm dropped bytes, DMA overruns hoặc processing backlog để biết thiết kế có đủ margin.

### Tại sao phần này quan trọng với RTOS?

Đây là pattern nền cho firmware RTOS thực tế.

### Góc nhìn debug

Stress producer rate và đo overflow/latency.

---

## 4. Mental Model tổng hợp

```text
UART:
RX IRQ -> queue_from_isr -> Command Task

ADC:
DMA writes buffer
     |
DMA complete IRQ
     |
give signal
     |
Processing Task
     |
release/swap ownership
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- ISR không block hoặc làm heavy processing.
- DMA/task không đồng thời sở hữu cùng writable buffer ngoài protocol.
- Overflow/backpressure có policy rõ.
- Wake high-priority task từ ISR đi qua deferred PendSV.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “DMA xong là buffer luôn safe”

Còn phụ thuộc restart và ownership.

### “Parse ngay ISR giảm latency”

Có thể tăng interrupt latency toàn hệ thống.

### “Queue đủ lớn thì không cần overflow policy”

Mọi buffer hữu hạn đều có overload limit.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 11.2 là integration proof cho queue/semaphore FromISR. Khi flow này stress ổn, IPC không còn chỉ là demo synthetic.

---

## 8. Tổng kết

- ISR capture byte; task xử lý protocol.
- DMA completion là event; heavy processing thuộc task.
- Deferred processing tách hard IRQ latency khỏi workload application.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. UART RX ISR nên làm tối thiểu những gì?
2. DMA buffer ownership giải quyết race nào?
3. Deferred processing đem lại lợi ích gì?
4. Backpressure/overflow cần được quan sát thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-task-decomposition-priorities.md) · [Bài tiếp →](03-shared-peripherals-full-demo.md)

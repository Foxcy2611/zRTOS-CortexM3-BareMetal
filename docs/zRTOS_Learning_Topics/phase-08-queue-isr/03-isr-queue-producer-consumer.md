# Bài 8.3 — Queue FromISR và Producer/Consumer

> **Phạm vi:** ISR non-blocking queue send, overflow policy và producer/consumer application pattern.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không đi sâu DMA zero-copy queue.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-blocked-senders-receivers.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. ISR producer pattern](#1-isr-producer-pattern)
- [2. Queue full trong ISR](#2-queue-full-trong-isr)
- [3. Producer/consumer decoupling](#3-producerconsumer-decoupling)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. ISR producer pattern

UART RXNE ISR là ví dụ tự nhiên: đọc byte để service hardware rồi gửi byte vào queue bằng API FromISR.

### Minimal ISR

ISR không parse command, format string hay block. Nó chỉ capture event/data tối thiểu.

### Wake receiver

Nếu command task đang BLOCKED, enqueue byte làm task READY; nếu priority cao hơn current, pend PendSV.

### Tại sao phần này quan trọng với RTOS?

Đây là bridge thực giữa hardware interrupt và RTOS application task.

### Góc nhìn debug

Trace byte arrival→queue count→receiver state→PendSV.

---

## 2. Queue full trong ISR

FromISR không được chờ slot. Khi full phải có policy deterministic.

### Drop + counter

Đơn giản và observable: drop byte/item, increment overflow counter.

### Overwrite

Chỉ dùng nếu semantics explicit và phù hợp data; không âm thầm overwrite.

### Backpressure impossible trực tiếp

ISR thường không thể block producer hardware theo same task semantics; có thể dùng peripheral flow control riêng nếu hardware hỗ trợ.

### Tại sao phần này quan trọng với RTOS?

Overload behavior là phần design, không phải edge case bỏ qua.

### Góc nhìn debug

Cố tình làm consumer chậm để verify overflow policy.

---

## 3. Producer/consumer decoupling

Queue cho producer và consumer chạy ở nhịp khác nhau trong capacity. Consumer có thể block khi empty; producer không cần polling consumer state.

### Sequence testing

Gắn sequence ID/checksum để stress loss/reorder.

### Capacity reasoning

Capacity phải dựa burst rate, consumer worst-case latency và item size/RAM budget.

### Tại sao phần này quan trọng với RTOS?

Đây là application architecture pattern lặp lại ở UART, sensor, logger.

### Góc nhìn debug

Theo dõi high-water mark queue nếu thêm diagnostic.

---

## 4. Mental Model tổng hợp

```text
UART IRQ (producer)
   |
read byte
   |
queue_send_from_isr
   |
RX Queue
   |
wake
   v
Command Task (consumer)
   |
parse/process
   |
block again on empty
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- FromISR send không block.
- Overflow policy rõ và observable.
- Consumer có thể block khi empty.
- FIFO/order semantics đúng trong scope multi-producer design đã chọn.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Queue sẽ không bao giờ overflow nếu task priority cao”

Burst/critical sections/other workload vẫn có thể vượt capacity.

### “Parse trong ISR nhanh hơn”

Có thể kéo dài interrupt latency toàn hệ thống.

### “Queue capacity chọn tùy ý”

Nên có reasoning theo burst/latency/RAM.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 11 sẽ reuse đúng architecture này cho UART RX command path, biến Queue FromISR thành feature được chứng minh trong firmware thật.

---

## 8. Tổng kết

- ISR capture; task process.
- FromISR queue full phải return/record policy, không block.
- Queue decouple timing nhưng không biến capacity thành vô hạn.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. FromISR queue full có những policy nào?
2. Producer/consumer được decouple ở khía cạnh nào?
3. Tại sao ISR chỉ nên capture tối thiểu?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-blocked-senders-receivers.md) · [Phase Index →](README.md)

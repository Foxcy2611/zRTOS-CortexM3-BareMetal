# Bài 11.1 — Task Decomposition và Priority Assignment

> **Phạm vi:** Thiết kế application task trên zRTOS: responsibility, blocking relation, latency và priority.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không thiết kế một sản phẩm cụ thể ngoài firmware demo tổng hợp.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-uart-adc-dma-integration.md)

---

## Mục lục

- [1. Không biến mọi function thành task](#1-không-biến-mọi-function-thành-task)
- [2. Priority theo latency và deadline](#2-priority-theo-latency-và-deadline)
- [3. Blocking architecture và data ownership](#3-blocking-architecture-và-data-ownership)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Không biến mọi function thành task

Task nên tồn tại vì có concurrency, timing hoặc blocking responsibility riêng. Một helper function không tự nhiên cần stack và scheduling identity riêng.

### Task cost

Mỗi task tốn stack, TCB, ready/wait membership và làm scheduling graph phức tạp hơn.

### Cohesion

Các event có cùng ownership/timing có thể xử lý trong một task thay vì chia vụn.

### Tại sao phần này quan trọng với RTOS?

Task decomposition tốt quyết định application có dễ reasoning hay trở thành maze synchronization.

### Góc nhìn debug

Vẽ data/event flow trước khi code. Nếu hai task luôn tuần tự chờ nhau, xem có nên gộp không.

---

## 2. Priority theo latency và deadline

Priority không nên dựa tên chức năng “quan trọng”. Nó phản ánh mức urgency và response time cần thiết.

### High priority task

Thường block phần lớn thời gian, wake khi có event cần response nhanh.

### Low priority task

Logger/display/background có thể thấp nếu delay không phá requirement.

### CPU hog

High task không block có thể starve phần còn lại dù scheduler hoàn toàn đúng.

### Tại sao phần này quan trọng với RTOS?

Priority assignment là realtime design, không phải cosmetic field.

### Góc nhìn debug

Tạo overload scenario và đo task response latency/starvation.

---

## 3. Blocking architecture và data ownership

Task không có việc nên block trên queue/semaphore/event/delay thay vì poll shared flag liên tục.

### Event-driven

Wake chỉ khi có data/event làm CPU usage thấp và priority meaningful hơn.

### Queue ownership

Copy queue làm ownership đơn giản: sender copy vào, receiver nhận bản copy.

### Shared DMA buffer

Nếu không copy, ownership phải explicit để task không đọc buffer DMA đang ghi.

### Tại sao phần này quan trọng với RTOS?

Đây là lúc các primitive kernel trở thành architecture application thực.

### Góc nhìn debug

Audit từng `while(1)` xem có busy polling không; audit từng shared buffer xem ai sở hữu.

---

## 4. Mental Model tổng hợp

```text
hardware/events
   |
   +--> Command Task
   +--> Sensor Task
   +--> Processing Task
   +--> Logger Task
   |
each task:
 - responsibility rõ
 - priority theo latency
 - block khi idle
 - data ownership explicit
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Mỗi task có responsibility và reason tồn tại rõ.
- Priority có rationale timing, không tùy ý.
- Task không busy-poll nếu có blocking primitive phù hợp.
- Shared data ownership được xác định.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Nhiều task làm project trông RTOS hơn”

Chỉ làm tốn RAM và complexity nếu không có concurrency need.

### “Task quan trọng thì luôn priority cao”

Priority dựa response/deadline, không business label.

### “Polling 1 ms cũng coi như block”

Vẫn tiêu CPU và tạo scheduling noise.

---

## 7. Liên hệ trực tiếp với zRTOS

Full demo dự kiến dùng Command Task, Sensor/Processing Task, Logger Task và Idle — vừa đủ ép queue/semaphore/mutex/ISR tương tác mà vẫn dễ giải thích.

---

## 8. Tổng kết

- Tạo task vì concurrency requirement, không vì muốn có nhiều task.
- Priority phải có rationale timing.
- Good RTOS app thường có task mostly blocked, runnable khi có việc.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Khi nào một responsibility đáng tách thành task?
2. Priority nên dựa trên yếu tố nào?
3. Tại sao task mostly-blocked là pattern tốt?
4. Shared DMA buffer cần ownership rule gì?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-uart-adc-dma-integration.md)

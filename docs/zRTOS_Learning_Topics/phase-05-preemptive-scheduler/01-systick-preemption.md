# Bài 5.1 — SysTick và Preemption

> **Phạm vi:** Kernel tick, SysTick handler và chuyển cooperative scheduler thành preemptive.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không tickless idle hoặc high-resolution timer.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-fixed-priority-round-robin.md)

---

## Mục lục

- [1. Kernel tick](#1-kernel-tick)
- [2. Preemption](#2-preemption)
- [3. SysTick/PendSV ordering](#3-systickpendsv-ordering)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Kernel tick

SysTick tạo periodic time base. `zrtos_tick_count` là thời gian logic dùng cho scheduling/delay, không nhất thiết là wall clock chính xác tuyệt đối.

### Tick frequency

Tick cao tăng resolution nhưng tăng interrupt overhead; tick thấp giảm overhead nhưng timeout/delay thô hơn.

### Port vs kernel

Raw `SysTick_Handler` nên gọi kernel tick handler thay vì nhét toàn bộ policy vào port.

### Tại sao phần này quan trọng với RTOS?

Tick là event source đầu tiên khiến kernel có notion time và involuntary scheduling.

### Góc nhìn debug

Đo tick count qua debugger và verify reload/config.

---

## 2. Preemption

Preemption nghĩa current task có thể mất CPU mà không gọi yield. SysTick request PendSV; scheduler reevaluate runnable set.

### Không bắt buộc đổi task mỗi tick

Nếu current vẫn là task phù hợp nhất, scheduler có thể chọn lại chính nó.

### Deferred switch

SysTick không restore task khác trực tiếp; nó pend PendSV.

### Tại sao phần này quan trọng với RTOS?

Đây là transition từ cooperative demo sang RTOS preemptive thật.

### Góc nhìn debug

Cho hai task loop không yield, observe context switch vẫn xảy ra.

---

## 3. SysTick/PendSV ordering

SysTick có thể update tick, wake task về sau, rồi request PendSV. PendSV priority thấp hơn cho phép handler hoàn tất kernel time state trước selection.

### Atomicity

Shared tick/task state mutation cần tuân critical policy khi IPC/ISR bắt đầu phức tạp.

### Latency

Tick handler quá nặng sẽ tăng interrupt latency; Phase 6 O(N) wake scan chấp nhận được với task nhỏ nhưng phải biết trade-off.

### Tại sao phần này quan trọng với RTOS?

Exception priority/order giúp scheduler nhìn state hoàn chỉnh.

### Góc nhìn debug

Break/trace SysTick then PendSV order.

---

## 4. Mental Model tổng hợp

```text
Task running
  |
  | SysTick
  v
tick_count++
update kernel time state
pend PendSV
  |
  v
PendSV
  |
  v
scheduler_select_next()
  |
  v
same task or another task
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- SysTick không trực tiếp restore next task.
- Tick count update nhất quán trước scheduler reevaluation.
- Preemption có thể chọn lại current task.
- Tick rate là config rõ ràng.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Mỗi SysTick phải switch task”

Không; policy có thể chọn lại current.

### “SysTick chính là scheduler”

Nó là timer event source.

### “Preemption nghĩa task không bao giờ cần block/yield”

Block vẫn thiết yếu để không waste CPU.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 5.1 chỉ thêm time-triggered scheduling event. Phase 5.2 mới thêm priority policy.

---

## 8. Tổng kết

- SysTick cung cấp periodic kernel event, không phải scheduler bản thân.
- Preemption là scheduler reevaluation bất đồng ý task, không phải forced alternation mỗi tick.
- SysTick cập nhật event/time; PendSV thực hiện switch sau đó.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Preemption khác yield thế nào?
2. Vì sao SysTick chỉ pend PendSV?
3. Tick rate có trade-off gì?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-fixed-priority-round-robin.md)

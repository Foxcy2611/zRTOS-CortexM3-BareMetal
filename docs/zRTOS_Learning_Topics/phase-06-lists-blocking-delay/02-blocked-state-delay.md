# Bài 6.2 — BLOCKED State và zrtos_delay()

> **Phạm vi:** Blocking semantics, delay API, wake_tick và transition RUNNING↔BLOCKED.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Chưa IPC blocking; chỉ delay.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-intrusive-list-ready-lists.md) · [Bài tiếp →](03-tick-wraparound-delayed-structures.md)

---

## Mục lục

- [1. Blocking không phải busy wait](#1-blocking-không-phải-busy-wait)
- [2. zrtos_delay flow](#2-zrtosdelay-flow)
- [3. Wake delayed task](#3-wake-delayed-task)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Blocking không phải busy wait

Task BLOCKED bị remove khỏi runnable set, vì vậy CPU chạy task khác hoặc Idle. Đây là sự khác biệt nền tảng với loop chờ flag/tick.

### CPU utilization

Blocked task không chiếm instruction cycles để kiểm condition.

### Scheduler visibility

Scheduler đơn giản vì BLOCKED task không xuất hiện trong ready lists.

### Tại sao phần này quan trọng với RTOS?

Blocking là feature biến scheduler thành useful multitasking system.

### Góc nhìn debug

Inspect task state/list membership trong thời gian delay.

---

## 2. zrtos_delay flow

Current RUNNING task tính deadline, set block reason DELAY, remove ready_item và request PendSV.

### wake_tick

Deadline = current tick + delay ticks theo modulo arithmetic.

### Current-only block

Task API delay chỉ block task đang RUNNING, không tùy tiện block task khác trong v1.

### delay(0)

Semantics phải define rõ: no-op hoặc yield-like. Không để implementation ngẫu nhiên.

```text
RUNNING
  |
  | zrtos_delay(N)
  v
BLOCKED / DELAY
  |
  | tick reaches wake_tick
  v
READY
  |
  | scheduler
  v
RUNNING
```

### Tại sao phần này quan trọng với RTOS?

Delay là first blocking mechanism để test common block/make_ready helpers.

### Góc nhìn debug

Trace ready_item.container trước/sau delay và wake.

---

## 3. Wake delayed task

Tick handler tìm delay-blocked tasks đạt deadline và đưa về READY.

### make_ready

Helper remove waiting metadata phù hợp, set READY và insert ready list.

### Preempt after wake

Nếu wake task priority cao hơn current, request PendSV.

### Tại sao phần này quan trọng với RTOS?

Wake path chuẩn sẽ được reuse cho IPC.

### Góc nhìn debug

Nhiều task deadline khác nhau; verify không wake sớm/late ngoài tick granularity.

---

## 4. Mental Model tổng hợp

```text
current task
  |
zrtos_delay
  |
  +--> state BLOCKED
  +--> reason DELAY
  +--> ready_item remove
  +--> wake_tick set
  +--> PendSV
  |
another task runs
  |
SysTick finds deadline
  |
make task READY
  |
possible preemption
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- BLOCKED delay task không nằm ready list.
- Delay wake chỉ áp dụng block_reason DELAY.
- Task tự delay phải đang RUNNING.
- Wake path insert task vào đúng priority ready list.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Delay nghĩa task vẫn chạy nhưng không làm gì”

Đó là busy wait; RTOS delay phải block.

### “Scheduler có thể giữ blocked task rồi skip”

zRTOS chọn representation remove khỏi runnable set.

### “Wake task chỉ set state READY là đủ”

Còn phải cập nhật ready-list membership.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 6.2 nên tạo `zrtos_task_block_current()` và `zrtos_task_make_ready()` với invariant rõ để Phase 7-9 IPC tái sử dụng.

---

## 8. Tổng kết

- BLOCKED task không runnable và không busy-loop.
- Delay là state transition + scheduling operation, không chỉ timer count.
- Tick là owner wake condition cho DELAY-blocked task.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Blocking khác busy wait thế nào?
2. zrtos_delay cần thay đổi state/list gì?
3. Tại sao wake High task có thể cần PendSV?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-intrusive-list-ready-lists.md) · [Bài tiếp →](03-tick-wraparound-delayed-structures.md)

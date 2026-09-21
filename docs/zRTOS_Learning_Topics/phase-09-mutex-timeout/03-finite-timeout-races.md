# Bài 9.3 — Finite Timeout và Event-vs-Timeout Races

> **Phạm vi:** NO_WAIT/WAIT_FOREVER/finite timeout, timed blocking, wake reason và exactly-once completion.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không high-resolution timer hoặc timer wheel.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-priority-inheritance.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Unified timeout model](#1-unified-timeout-model)
- [2. Task chờ event hoặc deadline](#2-task-chờ-event-hoặc-deadline)
- [3. Exactly-once wake](#3-exactly-once-wake)
- [4. Wraparound reuse](#4-wraparound-reuse)
- [5. Mental Model tổng hợp](#5-mental-model-tổng-hợp)
- [6. Các invariant cần giữ](#6-các-invariant-cần-giữ)
- [7. Các hiểu nhầm thường gặp](#7-các-hiểu-nhầm-thường-gặp)
- [8. Liên hệ trực tiếp với zRTOS](#8-liên-hệ-trực-tiếp-với-zrtos)
- [9. Tổng kết](#9-tổng-kết)
- [10. Câu hỏi tự kiểm tra](#10-câu-hỏi-tự-kiểm-tra)
- [11. Tài liệu tham khảo](#11-tài-liệu-tham-khảo)

---

## 1. Unified timeout model

Semaphore, queue và mutex nên dùng semantics timeout thống nhất để caller không phải học ba contract khác nhau.

### NO_WAIT

Operation kiểm condition một lần rồi return nếu không available.

### WAIT_FOREVER

Task block cho tới object event, không có finite deadline.

### Finite ticks

Task block nhưng có deadline và có thể return TIMEOUT.

### Tại sao phần này quan trọng với RTOS?

Unified model giảm code duplication và user confusion.

### Góc nhìn debug

Test boundary timeout=0, 1, finite, forever.

---

## 2. Task chờ event hoặc deadline

Finite IPC waiter cùng lúc liên quan hai source wake: object event và tick deadline.

### Wait metadata

TCB cần block reason/object relation/deadline/result đủ để cleanup.

### Wake reason

Operation khi resume cần biết `OK` hay `TIMEOUT`.

### Tại sao phần này quan trọng với RTOS?

Timed blocking biến task từ one-condition waiter thành two-condition state machine.

### Góc nhìn debug

Inspect wait_item + deadline + result trong test.

---

## 3. Exactly-once wake

Event và timeout có thể xảy ra sát nhau. Kernel phải đảm bảo chỉ một path remove waiter/make READY/set result.

### Event wins

Give/send/receive trước deadline remove task khỏi wait list và mark success; tick sau không được wake lại.

### Timeout wins

Tick expiry remove wait_item khỏi object list, make READY với TIMEOUT; later event không còn thấy waiter đó.

### Critical ordering

Object operation và tick wake mutation phải được serialized theo kernel critical policy.

```text
Task waiting on object + deadline
      /                          object event                tick expiry
      \                         /
       +---- critical ordering-+
                |
         exactly one winner
                |
         READY once
         result OK/TIMEOUT
```

### Tại sao phần này quan trọng với RTOS?

Double wake có thể double-remove list, duplicate ready insertion và corrupt scheduler.

### Góc nhìn debug

Force event around deadline via ISR; run repeatedly.

---

## 4. Wraparound reuse

Finite deadlines phải dùng wrap-safe timing helper Phase 6; không viết comparison mới riêng cho IPC.

### Maximum interval

Same bounded interval constraint applies.

### Common helper

One source of truth for `deadline_reached(now, deadline)`.

### Tại sao phần này quan trọng với RTOS?

Timing inconsistency giữa delay và IPC rất khó debug.

### Góc nhìn debug

Force near UINT32_MAX for semaphore/queue timeout tests.

---

## 5. Mental Model tổng hợp

```text
BLOCKED on object
 + wait_item in object list
 + deadline
 + pending result

event path OR timeout path
       |
       v
one winner:
 remove wait metadata
 set result
 make READY
       |
       v
operation resumes with OK/TIMEOUT
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 6. Các invariant cần giữ

- Một timed wait complete đúng một lần.
- TIMEOUT path remove waiter khỏi object list.
- Event path hủy logically timeout eligibility.
- Result status phản ánh path thắng.
- Wrap-safe deadline helper dùng chung.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 7. Các hiểu nhầm thường gặp

### “Timeout chỉ cần thêm if tick>=deadline”

Còn phải cleanup wait list và race event.

### “Double wake không sao nếu state đã READY”

List corruption/duplicate insertion vẫn có thể xảy ra.

### “Mỗi IPC tự viết timeout logic”

Dễ tạo semantics không nhất quán.

---

## 8. Liên hệ trực tiếp với zRTOS

Finite timeout là một trong các feature làm zRTOS vượt mức mini scheduler/semaphore demo và trở thành portfolio kernel có concurrency reasoning thật.

---

## 9. Tổng kết

- Timeout mode là phần API contract, không chỉ parameter số.
- Finite wait có hai competing completion paths.
- Timed wait correctness = exactly-once completion + cleanup loser path.
- Delay và IPC timeout phải share timing semantics.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 10. Câu hỏi tự kiểm tra

1. NO_WAIT, WAIT_FOREVER và finite timeout khác nhau thế nào?
2. Exactly-once wake bảo vệ invariant nào?
3. Timeout path phải cleanup những gì?
4. Event-vs-timeout race được serialize thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 11. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-priority-inheritance.md) · [Phase Index →](README.md)

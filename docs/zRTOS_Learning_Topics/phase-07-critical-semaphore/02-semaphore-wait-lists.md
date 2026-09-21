# Bài 7.2 — Semaphore, Wait Lists và Direct Handoff

> **Phạm vi:** Binary/counting semaphore, object-specific wait list, block/wake và direct handoff.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không có mutex ownership; mutex thuộc Phase 9.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-race-critical-sections.md) · [Bài tiếp →](03-fromisr-basepri.md)

---

## Mục lục

- [1. Semaphore token model](#1-semaphore-token-model)
- [2. Take fast path và block path](#2-take-fast-path-và-block-path)
- [3. Give và direct handoff](#3-give-và-direct-handoff)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Semaphore token model

Semaphore biểu diễn số token khả dụng từ 0 tới `max_count`. Binary semaphore chỉ là trường hợp max_count=1; counting semaphore tổng quát hơn.

### Signaling

ISR/task có thể `give` để báo event; receiver `take` để consume token.

### Resource counting

Counting semaphore cũng có thể biểu diễn N resource giống nhau, miễn semantics ownership không cần như mutex.

### Tại sao phần này quan trọng với RTOS?

Semaphore là blocking primitive đầu tiên kết hợp kernel state, wait list và scheduler.

### Góc nhìn debug

Theo dõi `count` cùng số waiter, tránh chỉ nhìn return code.

---

## 2. Take fast path và block path

Nếu count>0, take decrement trong critical section và return. Nếu count=0 và caller được phép wait, task phải BLOCKED.

### Object-specific wait list

Semaphore giữ `waiting_tasks`. Chỉ `state=BLOCKED` không nói task đang chờ semaphore nào.

### wait_item

TCB có node riêng cho wait membership, tách khỏi ready_item.

```text
count > 0
 take -> count-- -> OK

count == 0
 take(wait)
    |
    +--> remove ready_item
    +--> wait_item -> sem.waiters
    +--> state BLOCKED
    +--> PendSV
```

### Tại sao phần này quan trọng với RTOS?

Wait list chính là mapping object→waiters mà block_reason một mình không biểu diễn đủ.

### Góc nhìn debug

Inspect ready_item.container và wait_item.container khi task block.

---

## 3. Give và direct handoff

Nếu không waiter, give tăng count tới max. Nếu có waiter, zRTOS có thể trao token trực tiếp bằng cách wake waiter mà không tăng count.

### Tại sao không count++ rồi wake

Nếu token vừa nằm trong count vừa được coi là đã trao waiter, một task khác có thể consume count và một give sinh hai hiệu ứng.

### Wake policy

Fixed-priority kernel thường chọn highest-priority waiter để giảm latency và phù hợp scheduling policy.

### Tại sao phần này quan trọng với RTOS?

Direct handoff là ví dụ rõ về invariant resource accounting.

### Góc nhìn debug

Test nhiều waiter + count zero, một give chỉ làm đúng một waiter READY và count vẫn hợp lý.

---

## 4. Mental Model tổng hợp

```text
Semaphore S
 count
 max_count
 waiters

take:
 token exists -> consume
 no token -> BLOCKED in S.waiters

give:
 waiter exists -> direct wake
 no waiter -> count++
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- 0 <= count <= max_count.
- Một waiter chỉ thuộc đúng object wait list đang chờ.
- Direct handoff không đồng thời increment count.
- Wake remove wait_item trước khi task quay lại ready list.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Semaphore = binary flag”

Counting semaphore có nhiều token và blocking semantics.

### “BLOCKED state đủ để wake”

Cần biết chính object đang được chờ.

### “Give luôn tăng count”

Không trong direct-handoff path.

---

## 7. Liên hệ trực tiếp với zRTOS

`zrtos_sem_take()` và `zrtos_sem_give()` sẽ là test đầu tiên cho common block/make_ready helper + wait_item design.

---

## 8. Tổng kết

- Semaphore quản lý token; mutex về sau quản lý ownership.
- Task blocked trên semaphore rời ready list và tham gia chính semaphore wait list.
- Một give tạo đúng một token effect: lưu vào count hoặc trao waiter.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao semaphore cần wait list riêng?
2. Direct handoff tránh lỗi accounting nào?
3. wait_item khác ready_item ở vai trò gì?
4. Semaphore khác mutex về concept gì?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-race-critical-sections.md) · [Bài tiếp →](03-fromisr-basepri.md)

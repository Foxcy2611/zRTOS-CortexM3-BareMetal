# Bài 9.1 — Mutex và Priority Inversion

> **Phạm vi:** Mutex ownership, lock/unlock semantics và classic priority inversion.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không recursive mutex hoặc deadlock detection.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-priority-inheritance.md)

---

## Mục lục

- [1. Mutex khác semaphore](#1-mutex-khác-semaphore)
- [2. Priority inversion](#2-priority-inversion)
- [3. Basic mutex invariants](#3-basic-mutex-invariants)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Mutex khác semaphore

Mutex không chỉ là binary state. Nó có owner identity và rule chỉ owner unlock; semantics này mở đường cho priority inheritance.

### Acquire

Free mutex -> caller trở thành owner.

### Wait

Owned mutex -> caller có thể block trong wait list.

### Unlock

Owner release; waiter phù hợp có thể trở thành READY/acquire theo policy.

### Tại sao phần này quan trọng với RTOS?

Ownership là dữ liệu cần thiết để biết task nào phải boost khi High chờ.

### Góc nhìn debug

Assert non-owner unlock và inspect owner pointer.

---

## 2. Priority inversion

Low priority task giữ mutex. High priority task cần mutex nên BLOCKED. Medium priority task không cần mutex nhưng READY và preempt Low.

### Indirect blocking

High về logic chỉ phụ thuộc Low, nhưng scheduler cho Medium chạy trước Low; vì vậy High bị Medium kéo dài latency.

### Không phải deadlock

Low cuối cùng có thể chạy/release nếu Medium không chiếm CPU vô hạn. Inversion là latency anomaly, không cycle ownership.

```text
Low owns M
High wants M -> BLOCKED
Medium READY
     |
     v
Medium runs instead of Low
     |
     v
Low cannot release M
     |
     v
High waits longer
```

### Tại sao phần này quan trọng với RTOS?

Đây là problem kinh điển fixed-priority RTOS; hiểu trace trước khi implement fix.

### Góc nhìn debug

Tạo three-task demo và timestamp task execution.

---

## 3. Basic mutex invariants

Trước inheritance, mutex vẫn phải đúng ownership/wait semantics.

### Owner uniqueness

Một mutex chỉ có một owner hoặc NULL.

### Waiter membership

Task chờ mutex không nằm ready set.

### Unlock legality

Non-owner unlock trả error/assert theo API contract.

### Tại sao phần này quan trọng với RTOS?

Nếu ownership core sai, inheritance không thể cứu.

### Góc nhìn debug

Test lock free, lock owned, non-owner unlock, waiter wake.

---

## 4. Mental Model tổng hợp

```text
M free
 |
Low lock
 |
owner=Low
 |
High lock
 |
High BLOCKED
 |
Medium READY
 |
priority inversion visible
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Mutex có tối đa một owner.
- Chỉ owner được unlock.
- Waiter BLOCKED không nằm ready list.
- Ownership state và wait list cập nhật atomically.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Mutex là binary semaphore có tên khác”

Ownership và inheritance làm semantics khác.

### “Priority inversion là priority số bị đổi”

Là inversion trong blocking order/latency.

### “Inversion = deadlock”

Không; deadlock cần cyclic/no-progress condition khác.

---

## 7. Liên hệ trực tiếp với zRTOS

zRTOS nên có demo `priority_inversion` trước khi Phase 9.2 bật inheritance, để chứng minh fix dựa trên problem thật.

---

## 8. Tổng kết

- Mutex = mutual exclusion + ownership.
- Priority inversion là high task bị gián tiếp trì hoãn bởi medium vì low giữ resource.
- Mutex correctness bắt đầu từ ownership invariant.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Mutex khác binary semaphore ở điểm nào?
2. Mô tả Low/Medium/High priority inversion.
3. Priority inversion khác deadlock thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-priority-inheritance.md)

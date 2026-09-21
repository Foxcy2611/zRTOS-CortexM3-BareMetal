# Bài 9.2 — Base/Effective Priority và Priority Inheritance

> **Phạm vi:** Priority inheritance, base/effective priority, ready-list reposition và restore policy.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Transitive inheritance/multiple mutex nesting có thể được giới hạn trong v1 nhưng phải document.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-mutex-priority-inversion.md) · [Bài tiếp →](03-finite-timeout-races.md)

---

## Mục lục

- [1. Base và effective priority](#1-base-và-effective-priority)
- [2. Inheritance trigger](#2-inheritance-trigger)
- [3. Priority restore và multiple mutex](#3-priority-restore-và-multiple-mutex)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Base và effective priority

Base priority là cấu hình gốc. Effective priority là giá trị scheduler dùng khi task đang được boost.

### Không overwrite base

Nếu chỉ sửa một field priority duy nhất, kernel có thể quên priority gốc khi cần restore.

### Scheduler input

Ready-list membership phải phản ánh effective priority nếu lists index theo priority.

### Tại sao phần này quan trọng với RTOS?

Tách hai khái niệm giúp inheritance có lifecycle rõ.

### Góc nhìn debug

Inspect cả base/effective trong inversion demo.

---

## 2. Inheritance trigger

Khi High block trên mutex do Low sở hữu, Low effective priority được nâng ít nhất tới priority waiter cao nhất.

### Ready owner

Nếu Low đang READY trong list priority cũ, phải remove/reinsert sang list effective mới.

### Running owner

Nếu Low đang RUNNING, state current vẫn hợp lệ nhưng subsequent scheduler selection phải thấy effective priority mới.

```text
Low base=1 eff=1 owns M
High prio=5 waits
       |
       v
Low eff=5
       |
       v
Low outranks Medium
       |
       v
Low releases M
       |
       v
High can proceed
```

### Tại sao phần này quan trọng với RTOS?

Chỉ đổi field mà không update ready structure là bug scheduler representation.

### Góc nhìn debug

Trace list container/priority before and after boost.

---

## 3. Priority restore và multiple mutex

Unlock không luôn đồng nghĩa restore thẳng base. Nếu owner còn giữ mutex khác có waiter priority cao, effective priority vẫn có thể cần boost.

### Simplified v1

Có thể giới hạn mỗi task giữ một mutex có inheritance hoặc recompute max waiter trên owned mutexes.

### Known limitation

Nếu chưa hỗ trợ chain/nested cases, docs phải nói chính xác thay vì claim full PI.

### Tại sao phần này quan trọng với RTOS?

Đây là nơi hobby implementation dễ sai nhưng vẫn pass simple 3-task demo.

### Góc nhìn debug

Test task giữ hai mutex nếu implementation claim support.

---

## 4. Mental Model tổng hợp

```text
base priority = static configuration
effective priority = scheduler-visible value

waiter High -> owner boost
resource release -> recompute effective
ready-list membership follows effective
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Base priority không bị mất khi boost.
- Scheduler selection dùng effective priority.
- Ready task đổi effective priority phải đổi ready-list membership.
- Restore priority phản ánh mọi inheritance reason còn tồn tại trong scope support.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Chỉ set tcb->priority = High là xong”

Ready list theo priority có thể trở nên inconsistent.

### “Unlock luôn về base”

Không nếu còn mutex/waiter khác gây boost.

### “Simple demo pass nghĩa PI production-complete”

Nested/transitive cases có thể chưa support.

---

## 7. Liên hệ trực tiếp với zRTOS

Portfolio v1 không cần full industrial mutex graph, nhưng scope inheritance phải được test và ghi `known_limitations.md`.

---

## 8. Tổng kết

- Scheduler chạy theo effective; base giữ cấu hình gốc.
- Inheritance là priority change + scheduler membership consequence.
- Restore policy phải xét toàn bộ inheritance reasons còn active.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Base/effective priority khác nhau thế nào?
2. Tại sao boost READY task cần reposition list?
3. Unlock multiple-mutex case phức tạp ở đâu?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-mutex-priority-inversion.md) · [Bài tiếp →](03-finite-timeout-races.md)

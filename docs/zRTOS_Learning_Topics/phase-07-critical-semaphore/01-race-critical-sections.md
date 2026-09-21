# Bài 7.1 — Race Condition và Critical Section

> **Phạm vi:** Race condition trong single-core Cortex-M, atomicity và critical section dùng PRIMASK.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không đi sâu lock-free algorithm hoặc formal memory model đa lõi.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-semaphore-wait-lists.md)

---

## Mục lục

- [1. Single-core vẫn có race condition](#1-single-core-vẫn-có-race-condition)
- [2. Atomicity ở level kernel](#2-atomicity-ở-level-kernel)
- [3. PRIMASK save/restore](#3-primask-saverestore)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Single-core vẫn có race condition

Không cần SMP mới có race. Trên Cortex-M3, task có thể bị interrupt/preempt giữa một chuỗi read-modify-write; ISR hoặc kernel path khác có thể chạm cùng shared state.

### Read-modify-write

Một câu C như `count++` thường thành load/add/store. Nếu ISR thay `count` giữa load và store, update bị mất.

### List transition

Remove ready_item rồi set state là multi-step invariant. Nếu bị interleave sai thời điểm, scheduler có thể thấy half-updated state.

### Tại sao phần này quan trọng với RTOS?

Critical section xuất hiện vì kernel data structure có transaction nhiều instruction.

### Góc nhìn debug

Tạo toy shared counter/list và đặt breakpoint giữa các instruction để tự quan sát interleaving.

---

## 2. Atomicity ở level kernel

Atomic không chỉ nghĩa một instruction CPU. Một **kernel operation** có thể cần nhiều instruction nhưng phải xuất hiện như một transition không thể quan sát ở trạng thái giữa.

### Precondition / postcondition

Trước mutation, invariant A đúng; sau mutation, invariant B đúng. Critical section bảo đảm không actor khác quan sát state giữa A và B.

### Critical boundary

Chỉ bao phần metadata cần atomic. Không bao UART transmit, memcpy lớn hoặc loop dài nếu không cần.

### Tại sao phần này quan trọng với RTOS?

Nghĩ theo invariant giúp chọn critical boundary đúng thay vì disable IRQ quanh cả function.

### Góc nhìn debug

Audit code theo shared variables/list memberships thay vì theo tên API.

---

## 3. PRIMASK save/restore

zRTOS v1 có thể dùng PRIMASK để mask configurable interrupt trong critical section. Quan trọng: exit phải restore trạng thái cũ.

### Nested context

Nếu caller vào khi IRQ đã disabled, exit không được vô tình enable.

### Return previous mask

`enter_critical()` có thể trả previous PRIMASK; `exit_critical(state)` restore chính value đó.

```text
before:
 PRIMASK = old

enter_critical()
 save old
 disable IRQ
 mutate shared kernel state

exit_critical(old)
 restore old
```

### Tại sao phần này quan trọng với RTOS?

Save/restore policy làm critical API composable hơn trong nested kernel paths.

### Góc nhìn debug

Test case 1: IRQ initially enabled. Case 2: initially disabled. Sau exit phải về đúng old state.

---

## 4. Mental Model tổng hợp

```text
Task / ISR có thể cùng chạm kernel state
         |
         v
enter critical
         |
shared state mutation
(list/state/count)
         |
postcondition invariant
         |
exit critical restores old mask
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Critical exit khôi phục đúng interrupt state trước enter.
- Không gọi blocking operation khi đang giữ critical section.
- Critical section chỉ bao shared kernel mutation cần atomicity.
- Ready/wait list membership và task state không để lộ half-transition.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Single-core nên không cần lock”

Interrupt/preemption vẫn tạo interleaving.

### “volatile giải quyết race”

Volatile không tạo atomic multi-step transaction.

### “Disable IRQ càng rộng càng an toàn”

Làm tăng interrupt latency và che thiết kế critical boundary kém.

---

## 7. Liên hệ trực tiếp với zRTOS

Từ Phase 7, mọi operation thay đổi ready list, wait list, semaphore count hoặc task state cần được audit critical boundary. Đây là nền correctness cho toàn IPC.

---

## 8. Tổng kết

- Single-core không loại bỏ concurrency; interrupt/preemption vẫn tạo race.
- Critical section bảo vệ transition/invariant, không bảo vệ một dòng code tùy ý.
- Critical exit phải restore previous interrupt mask, không đơn giản luôn enable IRQ.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Race condition xảy ra trên single-core thế nào?
2. Tại sao volatile không thay critical section?
3. Vì sao phải restore PRIMASK cũ?
4. Critical boundary nên dựa trên gì?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-semaphore-wait-lists.md)

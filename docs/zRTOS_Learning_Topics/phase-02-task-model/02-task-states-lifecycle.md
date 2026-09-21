# Bài 2.2 — Task States và Lifecycle

> **Phạm vi:** State machine UNUSED/READY/RUNNING/BLOCKED và quan hệ state với runnable membership.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Chưa đi sâu từng IPC wait list; chỉ xây nền state machine.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-task-abstraction-tcb.md) · [Bài tiếp →](03-initial-task-stack.md)

---

## Mục lục

- [1. Bốn state cơ bản](#1-bốn-state-cơ-bản)
- [2. State transition hợp lệ](#2-state-transition-hợp-lệ)
- [3. State và list membership không hoàn toàn giống nhau](#3-state-và-list-membership-không-hoàn-toàn-giống-nhau)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Bốn state cơ bản

zRTOS v1 có thể bắt đầu với bốn state: UNUSED, READY, RUNNING và BLOCKED. Ít state giúp transition dễ reasoning hơn.

### UNUSED

Slot/object chưa được tạo. Sau create chuyển READY và zRTOS v1 không cần quay lại UNUSED vì chưa có task delete.

### READY

Task có đủ điều kiện chạy nhưng chưa sở hữu CPU.

### RUNNING

Task hiện được scheduler chọn và CPU đang thực thi context của nó.

### BLOCKED

Task không được phép chạy vì chờ delay hoặc IPC condition.

### Tại sao phần này quan trọng với RTOS?

State là logic correctness data, không chỉ field phục vụ UI/debug.

### Góc nhìn debug

Khi bug scheduler, luôn so `current_tcb`, state và list membership cùng lúc.

---

## 2. State transition hợp lệ

Transition phải gắn operation cụ thể; không module nào được set state tùy ý.

### RUNNING -> READY

Xảy ra khi scheduler demote current do yield/preemption và task vẫn runnable.

### RUNNING -> BLOCKED

Xảy ra khi current task chủ động delay/chờ IPC và phải rời ready set.

### BLOCKED -> READY

Chỉ subsystem sở hữu wake condition phù hợp mới đánh thức task.

```text
UNUSED -> READY
READY  -> RUNNING
RUNNING -> READY
RUNNING -> BLOCKED
BLOCKED -> READY
```

### Tại sao phần này quan trọng với RTOS?

Transition table là base để viết assert và test về sau.

### Góc nhìn debug

Nếu thấy READY->BLOCKED trực tiếp trong code, cần hỏi task nào đang chạy và operation nào có quyền block nó.

---

## 3. State và list membership không hoàn toàn giống nhau

Ready list biểu diễn scheduler set; state nói logic role. Một design có thể giữ RUNNING task trong ready list để round-robin dễ hơn.

### RUNNABLE set

Nếu READY và RUNNING cùng có ready_item attached, scheduler chỉ scan ready list; current state phân biệt ai đang thực thi.

### BLOCKED removal

BLOCKED phải rời ready list; nếu không scheduler có thể chọn task chưa đủ điều kiện.

### Block reason

Về sau `BLOCKED` cần reason: DELAY, SEM, QUEUE_SEND, QUEUE_RECEIVE, MUTEX... để đúng subsystem wake task.

### Tại sao phần này quan trọng với RTOS?

Phân biệt state và membership tránh suy luận sai khi implement intrusive list.

### Góc nhìn debug

Assert `BLOCKED => ready_item.container == NULL`; các invariant READY/RUNNING tùy design phải document.

---

## 4. Mental Model tổng hợp

```text
create
  |
  v
READY
  |
  | scheduler select
  v
RUNNING
  |   |  \ yield/preempt
  |   v
  |  READY
  |
  | delay / IPC wait
  v
BLOCKED
  |
  | tick / IPC event
  v
READY
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Exactly one task RUNNING sau scheduler selection.
- BLOCKED task không được scheduler chọn.
- Wake operation chỉ chuyển đúng task BLOCKED phù hợp về READY.
- UNUSED chỉ chuyển sang READY khi create trong zRTOS v1.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “READY là đang chạy”

READY chỉ nghĩa runnable.

### “BLOCKED vẫn có thể nằm ready list rồi scheduler kiểm state”

Có thể design vậy nhưng làm scheduler phức tạp; zRTOS chọn remove khỏi ready list.

### “state chỉ để print debug”

State quyết định transition legality.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 4 scheduler sẽ quản lý READY/RUNNING. Phase 6 delay thêm RUNNING→BLOCKED→READY. Phase 7-9 IPC reuse cùng state machine với wait lists và block reasons.

---

## 8. Tổng kết

- READY/RUNNING là runnable; BLOCKED không runnable.
- State transition phải có owner/event rõ.
- State là logic; list membership là data structure biểu diễn runnable/wait set.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Nêu các transition state hợp lệ.
2. Tại sao BLOCKED phải rời runnable set?
3. State và ready-list membership khác nhau thế nào?
4. Block reason cần thiết khi nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-task-abstraction-tcb.md) · [Bài tiếp →](03-initial-task-stack.md)

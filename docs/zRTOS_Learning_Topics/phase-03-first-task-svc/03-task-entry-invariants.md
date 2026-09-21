# Bài 3.3 — Task Entry, Argument, Exit Trap và Bootstrap Invariants

> **Phạm vi:** Task function contract, task return behavior, bootstrap postconditions và debug mental model.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không hỗ trợ task delete/normal task exit trong v1.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-svc-first-task-flow.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Task entry contract](#1-task-entry-contract)
- [2. Task return trap](#2-task-return-trap)
- [3. Bootstrap postconditions](#3-bootstrap-postconditions)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Task entry contract

zRTOS v1 xem task entry là function có lifetime dài, thường loop vô hạn hoặc không return. Đây là deliberate simplification cho static task model.

### Signature

`void task(void *arg)` phù hợp việc truyền context/application object qua R0.

### Task-owned stack

Mọi local/call frame của task sau bootstrap nằm trên PSP stack riêng.

### Tại sao phần này quan trọng với RTOS?

Task function contract rõ làm failure mode và API simple.

### Góc nhìn debug

Inside task, read PSP và compare stack bounds của TCB.

---

## 2. Task return trap

Nếu task vô tình return, LR trong initial frame quyết định CPU đi đâu. Đặt explicit `zrtos_task_exit_error()` tốt hơn LR rác.

### Fail-fast

Trap có thể assert với reason `TASK_RETURNED`, giúp debug trực tiếp tại nguyên nhân.

### Không giả task delete

Đừng biến return thành delete nếu lifecycle delete chưa được thiết kế đầy đủ.

### Tại sao phần này quan trọng với RTOS?

Failure deterministic tốt hơn HardFault ngẫu nhiên.

### Góc nhìn debug

Tạo một test task cố return và confirm trap/hook fire.

---

## 3. Bootstrap postconditions

Khi first task chạy, một tập invariant phải đồng thời đúng; LED blink một mình không chứng minh điều đó.

### Logical state

current_tcb trỏ đúng task và task state RUNNING.

### CPU state

Thread Mode + PSP; PSP nằm trong stack task; MSP dành handler.

### Kernel state

scheduler_running đã đúng thời điểm; pending scheduling exceptions không dùng stale bootstrap state.

### Tại sao phần này quan trọng với RTOS?

Postcondition list là checklist debug first-task HardFault/corruption.

### Góc nhìn debug

Nếu fail, kiểm theo layer: TCB→saved_sp→software frame→PSP→hardware frame→PC/xPSR→EXC_RETURN.

---

## 4. Mental Model tổng hợp

```text
First task has started
   |
   +--> current_tcb == selected task
   +--> state == RUNNING
   +--> PSP inside task stack
   +--> Thread Mode active
   +--> MSP reserved for handlers
   +--> scheduler runtime state valid
   |
   v
ready for PendSV/context switching phase
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Task return đi vào explicit trap.
- CPU executing task implies current_tcb/state nhất quán.
- PSP nằm trong stack task tại task entry.
- Handler vẫn có MSP riêng.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Task chạy LED được là đủ validate”

Cần check CPU/kernel state.

### “Task return tự nhiên quay về zrtos_start”

Không có caller stack semantics như function call bình thường.

### “HardFault sau SVC chắc do SVC instruction”

Thường do frame/PSP/PC/xPSR/alignment.

---

## 7. Liên hệ trực tiếp với zRTOS

Kết thúc Phase 3, zRTOS có một task context thật. Phase 4 sẽ thêm nửa save và scheduler để chuyển giữa nhiều context.

---

## 8. Tổng kết

- Task entry là start point của execution context, không phải callback chạy trên caller stack.
- Task return phải có semantics explicit.
- Bootstrap thành công phải được chứng minh bằng invariant, không chỉ output application.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Task return nên xử lý thế nào trong v1?
2. Nêu các bootstrap postcondition quan trọng.
3. Nếu first task HardFault, debug theo thứ tự nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-svc-first-task-flow.md) · [Phase Index →](README.md)

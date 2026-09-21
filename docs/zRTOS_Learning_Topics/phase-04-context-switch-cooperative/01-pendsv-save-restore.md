# Bài 4.1 — PendSV Save/Restore Context

> **Phạm vi:** Normal context switch save current task, select next và restore task mới.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Scheduler policy chỉ ở mức tối thiểu; data structure tối ưu thuộc phase sau.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-tcb-sp-contract.md)

---

## Mục lục

- [1. PendSV entry với task đang chạy](#1-pendsv-entry-với-task-đang-chạy)
- [2. Store current saved SP](#2-store-current-saved-sp)
- [3. Restore next context](#3-restore-next-context)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. PendSV entry với task đang chạy

Khi task chạy Thread Mode/PSP và PendSV được nhận, hardware đã stack hardware frame lên PSP trước khi handler code chạy.

### Handler dùng MSP

PendSV handler itself chạy bằng MSP; PSP vẫn giữ pointer tới frame task bị ngắt.

### Save R4-R11

Handler đọc PSP rồi `STMDB` R4-R11 xuống dưới hardware frame.

### Tại sao phần này quan trọng với RTOS?

Đây là half-save mà first-task SVC không cần.

### Góc nhìn debug

Inspect PSP trước/sau STMDB và verify 8 word mới.

---

## 2. Store current saved SP

Sau software save, pointer hiện trỏ full context frame. Kernel phải ghi nó vào current TCB trước khi đổi current task.

### Ordering

Nếu đổi current_tcb trước rồi store SP, có thể ghi stack A vào TCB B — corruption trực tiếp.

### Atomic reasoning

PendSV priority/masking phải bảo đảm scheduler data không bị concurrent mutation không được thiết kế.

### Tại sao phần này quan trọng với RTOS?

Một ordering bug vài instruction có thể phá toàn bộ context switch.

### Góc nhìn debug

Watch current_tcb và saved_sp addresses trong single-step.

---

## 3. Restore next context

Scheduler cung cấp next TCB. Port load next saved SP, restore R4-R11, set PSP và exception return.

### Task mới hoặc cũ

Nếu initial frame cùng contract, restore path không cần biết task đã từng chạy chưa.

### Resume semantics

PC/xPSR hardware frame khiến task resume đúng instruction/function context.

```text
A PSP -> [A R4..R11][A HW]
             |
             +--> save A.sp
                     |
                     v
                 select B
                     |
B.sp -> [B R4..R11][B HW]
             |
             +--> restore -> PSP -> exception return
```

### Tại sao phần này quan trọng với RTOS?

Một restore path thống nhất là dấu hiệu context design sạch.

### Góc nhìn debug

Dùng distinct register patterns/counters giữa A và B.

---

## 4. Mental Model tổng hợp

```text
Task A
  |
PendSV
  |
hardware frame A exists
  |
save R4-R11
  |
A.saved_sp = PSP
  |
scheduler_select_next()
  |
current_tcb = B
  |
load B.saved_sp
restore R4-R11
set PSP
  |
exception return
  |
Task B resumes
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- A.saved_sp được lưu trước khi current_tcb đổi sang B.
- B.saved_sp trỏ context frame hợp lệ.
- Port không tự quyết priority policy.
- R4-R11 được preserve chính xác qua switch.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Context switch chỉ đổi current_tcb”

CPU register/stack context vẫn phải save/restore.

### “Scheduler nên chạy trước save để chọn nhanh”

Có thể clobber state current trước khi preserve.

### “Task mới cần restore path khác”

Không nếu initial frame contract thống nhất.

---

## 7. Liên hệ trực tiếp với zRTOS

PendSV handler sẽ là phần assembly trọng tâm nhất của zRTOS. Giữ handler nhỏ; mọi policy chuyển sang `zrtos_scheduler_select_next()`.

---

## 8. Tổng kết

- PendSV bắt đầu với hardware frame đã có; software chỉ bổ sung R4-R11.
- Save current SP hoàn tất trước task selection.
- Normal switch = save current + policy select + restore next.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Sequence save/select/restore chính xác là gì?
2. Tại sao store saved_sp phải xảy ra trước đổi current_tcb?
3. Task mới và task cũ dùng chung restore path thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-tcb-sp-contract.md)

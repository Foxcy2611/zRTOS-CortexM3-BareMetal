# Bài 1.3 — PendSV, AAPCS và Full CPU Context

> **Phạm vi:** AAPCS caller/callee-saved register, PendSV và full CPU context cần bảo toàn khi preempt task.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không có floating-point context vì Cortex-M3 không có FPU.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-svc-exc-return.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. AAPCS và register lifetime](#1-aapcs-và-register-lifetime)
- [2. PendSV là deferred context-switch exception](#2-pendsv-là-deferred-context-switch-exception)
- [3. Full task context](#3-full-task-context)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. AAPCS và register lifetime

AAPCS mô tả contract register giữa các function call. Caller-saved thường gồm R0-R3/R12; callee-saved gồm R4-R11. Context switch lại là event bất đồng bộ, không phải function call giữa task A và B.

### Hardware gánh phần caller-like state

Exception hardware frame bao gồm R0-R3/R12 và return state. Đây là lý do PendSV chỉ cần software-save phần R4-R11 để full general-purpose context được bảo toàn.

### Compiler không biết về context switch

Compiler không tự sinh prologue để bảo vệ R4-R11 trước khi task bị preempt. Nếu kernel không save, task khác có thể ghi đè register vật lý đó.

### Tại sao phần này quan trọng với RTOS?

Hiểu ranh giới hardware/software save giúp assembly ngắn, đúng và giải thích được.

### Góc nhìn debug

Compile task có optimization rồi inspect disassembly để thấy local sống trong R4-R11; đây là test context integrity tốt hơn LED.

---

## 2. PendSV là deferred context-switch exception

PendSV có thể được pend và ưu tiên thấp, vì vậy ISR có thể hoàn tất rồi CPU mới chạy context switch. Đây là mô hình phổ biến trên Cortex-M RTOS.

### Request không đồng nghĩa switch ngay

`PENDSVSET` chỉ yêu cầu exception. Nếu CPU đang xử lý IRQ priority cao, PendSV chờ tới khi đủ điều kiện.

### Tại sao tốt cho ISR

ISR chỉ cập nhật hardware/kernel event, wake task và request switch. Nó không cần tự save/restore task giữa logic ISR.

```text
ISR
 |
 +--> capture event
 +--> wake task
 +--> pend PendSV
 |
 v
return
 |
 v
PendSV
 |
 v
scheduler + context switch
```

### Tại sao phần này quan trọng với RTOS?

Deferred switching giảm coupling giữa mọi peripheral ISR và scheduler.

### Góc nhìn debug

Quan sát thứ tự exception bằng breakpoint/trace: IRQ -> return/pending -> PendSV.

---

## 3. Full task context

Một task phải resume như thể chưa từng mất CPU. Full context của zRTOS gồm hardware frame, R4-R11 và saved PSP.

### Stack layout

Software frame nằm liền với hardware frame để saved SP có thể trỏ tới một format thống nhất.

### TCB contract

TCB chỉ cần lưu pointer tới frame; CPU register data nằm trên task stack, không copy hết vào struct.

### Naked handler

Assembly/naked handler thường cần vì compiler-generated prologue/epilogue có thể đụng register/stack trước khi kernel save đúng context.

```text
TCB->saved_sp
      |
      v
+-------------+
| R4 ... R11 | software saved
+-------------+
| R0 ... xPSR| hardware saved
+-------------+
```

### Tại sao phần này quan trọng với RTOS?

Đây là contract xuyên suốt Phase 2-4; task mới và task cũ đều phải restore được bằng cùng logic.

### Góc nhìn debug

Kiểm tra saved SP nằm trong đúng stack, frame pattern đúng và PC resume đúng sau hàng nghìn switch.

---

## 4. Mental Model tổng hợp

```text
Task A
  |
PendSV entry -> hardware frame A
  |
save R4-R11
  |
A.tcb->saved_sp = PSP
  |
scheduler selects B
  |
PSP = B.tcb->saved_sp
  |
restore R4-R11
  |
exception return restores hardware frame B
  |
Task B resumes
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- R4-R11 của current task được save trước khi scheduler có thể clobber chúng.
- saved_sp luôn trỏ đúng full-frame format.
- Port thực hiện mechanism; scheduler thực hiện policy.
- PendSV không chứa BSP/peripheral logic.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “AAPCS tự bảo vệ R4-R11 khi preempt”

Không có callee/caller relationship giữa hai task.

### “PendSV là scheduler”

PendSV chỉ là exception dùng để thực hiện switch.

### “Save càng nhiều register càng chắc”

Save dư có thể phá layout/latency mà không tăng correctness.

---

## 7. Liên hệ trực tiếp với zRTOS

Đây là chapter cuối nền tảng CPU. Phase 2 sẽ tạo TCB/initial frame; Phase 3 dùng SVC restore; Phase 4 hiện thực đúng sequence PendSV ở mental model trên.

---

## 8. Tổng kết

- R4-R11 phải do zRTOS software-save; hardware đã lo phần exception frame.
- PendSV là mechanism để defer switch tới điểm exception-priority phù hợp.
- Full context = hardware frame + R4-R11 + saved PSP.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao R4-R11 cần software save?
2. PendSV deferred switch giúp ISR thế nào?
3. TCB saved SP trỏ tới gì?
4. Tại sao context-switch handler thường viết assembly/naked?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-svc-exc-return.md) · [Phase Index →](README.md)

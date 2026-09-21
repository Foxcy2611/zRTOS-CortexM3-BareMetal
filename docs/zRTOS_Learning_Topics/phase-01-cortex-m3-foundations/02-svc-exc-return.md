# Bài 1.2 — SVC và EXC_RETURN

> **Phạm vi:** SVC như synchronous exception, EXC_RETURN và cơ chế bootstrap task đầu tiên.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không xây syscall layer, privilege separation hoặc user/kernel mode như hệ điều hành lớn.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-exception-model-msp-psp.md) · [Bài tiếp →](03-pendsv-aapcs-context.md)

---

## Mục lục

- [1. SVC là synchronous exception](#1-svc-là-synchronous-exception)
- [2. EXC_RETURN](#2-excreturn)
- [3. First-task restore path](#3-first-task-restore-path)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. SVC là synchronous exception

SVC được phát sinh chủ động bằng instruction `SVC`. Khác peripheral IRQ, thời điểm xảy ra do software kiểm soát. Tính chất này rất phù hợp để kernel chuyển từ bootstrap context sang first task.

### Tại sao cần một exception để start task

Task đầu tiên phải bắt đầu bằng cùng context format mà PendSV sẽ restore về sau. Nếu gọi thẳng `task_entry()` từ `main`, task vẫn chạy như function trên bootstrap stack, không chứng minh RTOS context thật.

### SVC entry

Khi SVC xảy ra, hardware vẫn tạo exception frame theo rule đã học. Handler chạy bằng MSP; initial task frame mà kernel chuẩn bị nằm ở stack riêng và sẽ được handler restore.

### Tại sao phần này quan trọng với RTOS?

SVC tạo một điểm chuyển mode có kiểm soát để zRTOS đưa CPU từ main/bootstrap sang Thread Mode/PSP.

### Góc nhìn debug

Break tại `SVC_Handler`, kiểm tra LR handler, MSP, PSP và `current_tcb->saved_sp` trước khi restore.

---

## 2. EXC_RETURN

Trong handler, LR có thể chứa một token đặc biệt gọi EXC_RETURN. CPU không coi token này là địa chỉ code thông thường mà giải mã các bit để biết sẽ return về mode nào và dùng stack nào.

### 0xFFFFFFFD

Giá trị điển hình cho zRTOS first-task return là `0xFFFFFFFD`: return về Thread Mode và dùng PSP. Sau `BX LR`, hardware pop hardware frame từ PSP.

### Tại sao token này quan trọng

Chỉ set PSP là chưa đủ. CPU cần biết exception return phải sử dụng PSP thay vì MSP. EXC_RETURN chính là contract kiến trúc cho việc đó.

```text
SVC_Handler
   |
   +--> restore R4-R11
   +--> PSP = hardware_frame
   +--> LR = EXC_RETURN
   |
   v
BX LR
   |
   v
CPU exception-return sequence
```

### Tại sao phần này quan trọng với RTOS?

Một sai EXC_RETURN có thể khiến CPU return sai mode/stack và HardFault ngay khi bootstrap.

### Góc nhìn debug

Nếu first task không vào được, xác minh EXC_RETURN, PSP, stacked PC và xPSR trước khi nghi scheduler.

---

## 3. First-task restore path

First task khác normal context switch ở chỗ chưa có task cũ cần save. Bootstrap chỉ thực hiện nửa restore.

### Software frame

Load `current_tcb->saved_sp`, restore R4-R11. Pointer sau đó tiến tới đầu hardware frame.

### Hardware frame

Set PSP tới hardware frame. `BX LR` với EXC_RETURN khiến CPU tự restore R0-R3/R12/LR/PC/xPSR.

### Argument truyền vào task

R0 trong initial hardware frame trở thành argument đầu tiên của `task_entry(void *arg)` theo calling convention.

### Tại sao phần này quan trọng với RTOS?

Nếu first-task restore và PendSV restore dùng cùng stack contract, kernel tránh hai format context khác nhau.

### Góc nhìn debug

Dùng pattern cho R4-R11 và argument để thấy từng phần frame được restore đúng.

---

## 4. Mental Model tổng hợp

```text
main()
  |
  | zrtos_start()
  v
select current_tcb
  |
  | SVC
  v
Handler Mode / MSP
  |
  | restore R4-R11 from task stack
  | set PSP
  | EXC_RETURN -> Thread/PSP
  v
hardware pop frame
  |
  v
task_entry(arg)
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- current_tcb phải hợp lệ trước khi SVC restore.
- saved_sp phải trỏ đúng software frame.
- PSP phải trỏ hardware frame ngay trước exception return.
- Initial xPSR/PC phải hợp lệ để CPU resume task.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “SVC tự tạo task”

Không. Kernel đã chuẩn bị TCB/stack; SVC chỉ là mechanism chuyển execution.

### “EXC_RETURN là địa chỉ return”

Nó là token được CPU decode cho exception-return behavior.

### “Có thể gọi task entry trực tiếp rồi sau đó mới chuyển PSP”

Cách đó phá contract task context thống nhất.

---

## 7. Liên hệ trực tiếp với zRTOS

`zrtos_start()` về sau sẽ:

```text
select first READY task
      ↓
set zrtos_current_tcb
      ↓
trigger SVC
      ↓
SVC restore task
      ↓
scheduler runtime bắt đầu
```

SVC chỉ cần cho bootstrap; context switch runtime sẽ dùng PendSV.

---

## 8. Tổng kết

- SVC là cơ chế bootstrap có kiểm soát, không phải scheduler.
- EXC_RETURN quyết định exception return semantics; `0xFFFFFFFD` gắn trực tiếp với Thread Mode + PSP.
- First task bootstrap = restore software frame + PSP + exception return; không có save current.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Vì sao gọi task_entry trực tiếp từ main không phải bootstrap RTOS đúng?
2. EXC_RETURN làm nhiệm vụ gì?
3. First-task restore khác normal PendSV switch ở điểm nào?
4. R0 trong initial frame được dùng thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-exception-model-msp-psp.md) · [Bài tiếp →](03-pendsv-aapcs-context.md)

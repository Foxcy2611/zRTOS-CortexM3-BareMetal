# Bài 3.2 — SVC Restore và First Task Flow

> **Phạm vi:** Restore software frame, set PSP, EXC_RETURN và hardware unstack vào first task.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không có normal context switch/save current task.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-kernel-bootstrap.md) · [Bài tiếp →](03-task-entry-invariants.md)

---

## Mục lục

- [1. SVC handler contract](#1-svc-handler-contract)
- [2. Software restore → PSP](#2-software-restore-→-psp)
- [3. Exception return vào task](#3-exception-return-vào-task)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. SVC handler contract

SVC handler không tự tìm task. Nó nhận contract: `current_tcb` valid và `current_tcb->saved_sp` trỏ initial software frame.

### Naked/assembly handler

Compiler prologue có thể thay đổi register/stack, vì vậy restore path nên được kiểm soát instruction-by-instruction.

### Load saved SP

Handler load pointer từ current TCB và dùng nó làm base restore R4-R11.

### Tại sao phần này quan trọng với RTOS?

First-task flow là nơi task data model gặp CPU architecture lần đầu.

### Góc nhìn debug

Step từng instruction và ghi lại R4-R11/PSP trước-sau.

---

## 2. Software restore → PSP

Sau `LDMIA` R4-R11, pointer tiến tới hardware frame. Giá trị này trở thành PSP.

### Không copy hardware frame bằng software

CPU exception return sẽ pop hardware frame; software chỉ cần đặt PSP đúng chỗ.

### Alignment

PSP sai alignment có thể làm exception return hoặc code task fail khó hiểu.

```text
saved_sp
  |
  v
[R4..R11][R0..xPSR]
  |         ^
  | restore |
  +---------+
      pointer after LDMIA
             |
             v
            PSP
```

### Tại sao phần này quan trọng với RTOS?

Phân ranh software restore/hardware unstack giữ port ngắn và đúng kiến trúc.

### Góc nhìn debug

Ngay trước BX EXC_RETURN, PSP phải bằng address slot R0 hardware frame.

---

## 3. Exception return vào task

Handler nạp EXC_RETURN phù hợp rồi `BX LR`. CPU tự pop R0-R3/R12/LR/PC/xPSR và tiếp tục ở task entry.

### Argument

R0 được pop từ frame nên task nhận đúng `void *arg`.

### PC/xPSR

PC xác định entry; xPSR bảo đảm Thumb execution state hợp lệ.

### Tại sao phần này quan trọng với RTOS?

Đây là thời điểm zRTOS chính thức chuyển CPU sang task stack riêng.

### Góc nhìn debug

Breakpoint tại task entry; verify PSP trong range stack và R0 argument đúng.

---

## 4. Mental Model tổng hợp

```text
current_tcb->saved_sp
       |
       v
SVC Handler / MSP
       |
       +--> restore R4-R11
       +--> PSP = hardware frame
       +--> EXC_RETURN Thread+PSP
       v
hardware unstack
       |
       v
PC = task_entry
R0 = argument
       |
       v
Thread Mode / PSP
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Handler dùng MSP trong restore sequence.
- PSP trỏ đúng hardware frame trước BX EXC_RETURN.
- Task entry chạy Thread Mode bằng PSP.
- R4-R11 và hardware registers khớp initial frame đã dựng.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “SVC gọi task entry”

CPU resume task qua exception-return hardware sequence.

### “Có thể restore R0-R3 bằng LDMIA luôn cho tiện”

Không cần; hardware frame được CPU pop.

### “Task argument cần global”

R0 initial frame đã truyền argument.

---

## 7. Liên hệ trực tiếp với zRTOS

Milestone này nên có `examples/01_first_task`: một task đơn giản toggle LED/UART, nhưng debugger evidence phải chứng minh PSP/state/argument đúng.

---

## 8. Tổng kết

- SVC restore dựa hoàn toàn vào Phase 2 stack contract.
- Software restore kết thúc khi PSP trỏ đúng hardware frame.
- First task bắt đầu qua exception return, không qua C call từ main.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Pointer sau restore R4-R11 phải trỏ vào đâu?
2. CPU hardware pop register nào sau EXC_RETURN?
3. Tại sao first task phải chạy bằng PSP?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-kernel-bootstrap.md) · [Bài tiếp →](03-task-entry-invariants.md)

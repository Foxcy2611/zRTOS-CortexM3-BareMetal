# 03 — Context Switch trên Cortex-M3

## 1. Full context

Cortex-M exception entry tự lưu hardware frame:

```text
R0 R1 R2 R3 R12 LR PC xPSR
```

zRTOS port chịu trách nhiệm software-save phần callee-saved:

```text
R4-R11
```

Một layout logic điển hình:

```text
địa chỉ cao
xPSR, PC, LR, R12, R3, R2, R1, R0
R11, R10, R9, R8, R7, R6, R5, R4
địa chỉ thấp <- saved PSP
```

---

## 2. Execution model

- Thread mode của task dùng PSP.
- Handler mode dùng MSP.
- First task bootstrap qua SVC.
- Subsequent context switch qua PendSV.

---

## 3. Start first task bằng SVC

Luồng contract:

```text
zrtos_start
   ↓
select first task
   ↓
SVC
   ↓
restore R4-R11
   ↓
set PSP
   ↓
select PSP for Thread mode
   ↓
exception return
   ↓
hardware unstack
   ↓
task entry
```

Port phải dùng đúng EXC_RETURN cho Thread mode + PSP theo Cortex-M3 contract.

---

## 4. PendSV context switch

Luồng:

```text
exception entry
   ↓
hardware saves frame
   ↓
read PSP
   ↓
save R4-R11
   ↓
save PSP to current TCB
   ↓
call/select next task
   ↓
load next PSP
   ↓
restore R4-R11
   ↓
write PSP
   ↓
exception return
```

Assembly không chứa scheduling policy.

---

## 5. Exception priority policy

V1 dùng policy đơn giản:

- PendSV ở mức priority thấp nhất có thể cấu hình.
- SysTick cao hơn PendSV hoặc cùng policy đã được kiểm chứng nhưng không được phá deferred switch behavior.
- SVC không thấp hơn PendSV.
- Peripheral IRQ dùng priority phù hợp application.
- NMI/HardFault không gọi blocking API.

Nếu sau này chuyển từ PRIMASK sang BASEPRI, phải định nghĩa rõ nhóm ISR nào được phép gọi `FromISR` API.

---

## 6. Port rules

- không gọi SPL từ port;
- không chứa application policy;
- không giữ hidden scheduler state không cần thiết;
- các naked/assembly handler càng ngắn càng tốt;
- mọi assumption về struct layout phải có compile-time check.
